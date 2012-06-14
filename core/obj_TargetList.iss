/*

ComBot  Copyright � 2012  Tehtsuo and Vendan

This file is part of ComBot.

ComBot is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ComBot is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ComBot.  If not, see <http://www.gnu.org/licenses/>.

*/

objectdef obj_TargetList inherits obj_State
{
	variable index:entity TargetList
	variable index:entity LockedTargetList
	variable index:entity TargetListBuffer
	variable index:entity TargetListBufferOOR
	variable index:entity LockedTargetListBuffer
	variable index:entity LockedTargetListBufferOOR
	variable index:entity MyTargets
	variable collection:int DeadDelay
	variable index:string QueryStringList
	variable int64 DistanceTarget
	variable int MaxRange = 20000
	variable bool AutoLock = FALSE
	variable bool AutoRelock = FALSE
	variable bool AutoRelockPriority = FALSE
	variable int MaxLockCount = 2
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[50]
		RandomDelta:Set[0]
		This:QueueState["UpdateList"]
		DistanceTarget:Set[${MyShip.ID}]
	}

	method ClearQueryString()
	{
		QueryStringList:Clear
	}
	
	method AddQueryString(string QueryString)
	{
		QueryStringList:Insert["${QueryString.Escape}"]
	}
	
	method AddTargetingMe(bool NPC = TRUE)
	{
		if ${NPC}
		{
			This:AddQueryString["IsTargetingMe && IsNPC"]
		}
		else
		{
			This:AddQueryString["IsTargetingMe"]
		}
	}
	
	method AddAllNPCs()
	{
		variable string QueryString="CategoryID = CATEGORYID_ENTITY && IsNPC && !("
		
		;Exclude Groups here
		QueryString:Concat["GroupID = GROUP_CONCORDDRONE ||"]
		QueryString:Concat["GroupID = GROUP_CONVOYDRONE ||"]
		QueryString:Concat["GroupID = GROUP_CONVOY ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLEOBJECT ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESHIP ||"]
		QueryString:Concat["GroupID = GROUP_SPAWNCONTAINER ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESTRUCTURE)"]
		
		This:AddQueryString["${QueryString.Escape}"]
	}
	
	member:bool UpdateList()
	{
		variable iterator QueryStringIterator
		QueryStringList:GetIterator[QueryStringIterator]

		if ${QueryStringIterator:First(exists)}
		{
			do
			{
				This:QueueState["GetQueryString", -1, "${QueryStringIterator.Value.Escape}"]
			}
			while ${QueryStringIterator:Next(exists)}
		}
		This:QueueState["PopulateList"]
		if ${AutoLock}
		{
			This:QueueState["ManageLocks"]
		}
		This:QueueState["UpdateList"]
		return TRUE
	}
	
	member:bool GetQueryString(string QueryString)
	{
		variable index:entity entity_index
		variable iterator entity_iterator
		if !${Client.InSpace}
		{
			return FALSE
		}
		EVE:QueryEntities[entity_index, "${QueryString.Escape}"]		
		entity_index:GetIterator[entity_iterator]
		if ${entity_iterator:First(exists)}
		{
			do
			{
				if ${entity_iterator.Value.IsLockedTarget} || ${entity_iterator.Value.BeingTargeted}
				{
					DeadDelay:Set[${entity_iterator.Value.ID}, ${Math.Calc[${LavishScript.RunningTime} + 5000]}]
				}
				if ${entity_iterator.Value.DistanceTo[${DistanceTarget}]} <= ${MaxRange}
				{
					This.TargetListBuffer:Insert[${entity_iterator.Value.ID}]
					if ${entity_iterator.Value.IsLockedTarget}
					{
						This.LockedTargetListBuffer:Insert[${entity_iterator.Value.ID}]
					}
				}
				else
				{
					This.TargetListBufferOOR:Insert[${entity_iterator.Value.ID}]
					if ${entity_iterator.Value.IsLockedTarget}
					{
						This.LockedTargetListBufferOOR:Insert[${entity_iterator.Value.ID}]
					}
				}
			}
			while ${entity_iterator:Next(exists)}
		}
		return TRUE
	}
	
	member:bool PopulateList()
	{
		This.TargetList:Clear
		This.LockedTargetList:Clear
		
		This:DeepCopyEntityIndex["This.TargetListBuffer", "This.TargetList"]
		This:DeepCopyEntityIndex["This.TargetListBufferOOR", "This.TargetList"]
		This:DeepCopyEntityIndex["This.LockedTargetListBuffer", "This.LockedTargetList"]
		This:DeepCopyEntityIndex["This.LockedTargetListBufferOOR", "This.LockedTargetList"]
		
		This.TargetListBuffer:Clear
		This.TargetListBufferOOR:Clear
		return TRUE
	}
	
	member:bool ManageLocks()
	{
		if !${Client.InSpace} || ${Me.ToEntity.Mode} == 3
		{
			return TRUE
		}
		variable iterator EntityIterator
		variable bool NeedLock = FALSE
		variable int64 LowestLock = -1
		variable int MaxTarget = ${MyShip.MaxLockedTargets}
		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			MaxTarget:Set[${Me.MaxLockedTargets}]
		}
		
		This.MyTargets:GetIterator[EntityIterator]
		if ${EntityIterator:First(exists)}
		{
			do
			{
				if !${EntityIterator.Value(exists)}
				{
					This.MyTargets:Remove[${EntityIterator.Key}]
				}
			}
			while ${EntityIterator:Next(exists)}
		}
		
		This.MyTargets:Collapse
		
		if ${This.MyTargets.Used} < ${MaxLockCount} && ${Targets.Locked.Used} < ${MaxTarget}
		{
			This.TargetList:GetIterator[EntityIterator]
			if ${EntityIterator:First(exists)}
			{
				do
				{
					if !${EntityIterator.Value.IsLockedTarget} && !${EntityIterator.Value.BeingTargeted} && ${DeadDelay.Element[${EntityIterator.Value.ID}]} < ${LavishScript.RunningTime}  && ${EntityIterator.Value.Distance} < ${MyShip.MaxTargetRange}
					{
						This.MyTargets:Insert[${EntityIterator.Value.ID}]
						EntityIterator.Value:LockTarget
						This:QueueState["Idle", ${Math.Rand[500]}]
						DeadDelay:Set[${EntityIterator.Value.ID}, ${Math.Calc[${LavishScript.RunningTime} + 5000]}]
						return TRUE
					}
					if ${EntityIterator.Value.IsLockedTarget} && (${AutoRelockPriority} || (${AutoRelock}  && ${EntityIterator.Distance} < ${Entity[${Target}].Distance} < ${MyShip.MaxTargetRange}))
					{
						LowestLock:Set[TRUE]
					}
				}
				while ${EntityIterator:Next(exists)}
			}
		}
		if {$AutoRelock || $AutoRelockPriority} && !${LowestLock.Equal[-1]}
		{
			Entity[${LowestLock}]:UnlockTarget
			This:QueueState["Idle", ${Math.Rand[500]}]
		}
		return TRUE
	}
	
	method DeepCopyEntityIndex(string From, string To)
	{
		variable iterator EntityIterator
		${From}:GetIterator[EntityIterator]
		if ${EntityIterator:First(exists)}
		{
			do
			{
				${To}:Insert[${EntityIterator.Value.ID}]
			}
			while ${EntityIterator:Next(exists)}
		}
	}
}