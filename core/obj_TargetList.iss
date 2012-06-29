/*

ComBot  Copyright ? 2012  Tehtsuo and Vendan

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

variable set OwnedTargets

objectdef obj_TargetList inherits obj_State
{
	variable int64 DistanceTarget
	variable index:entity TargetList
	variable index:entity LockedTargetList
	variable int64 ClosestOutOfRange = -1
	variable index:entity TargetListBuffer
	variable index:entity TargetListBufferOOR
	variable index:entity LockedTargetListBuffer
	variable index:entity LockedTargetListBufferOOR
	variable index:string QueryStringList
	variable set LockedAndLockingTargets
	variable int64 DistanceTarget
	variable int MaxRange = 20000
	variable int MinRange = 0
	variable bool ListOutOfRange = TRUE
	variable bool AutoLock = FALSE
	variable int MinLockCount = 2
	variable int MaxLockCount = 2
	variable bool NeedUpdate = TRUE
	variable bool Updated = FALSE
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[100]
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
		NeedUpdate:Set[TRUE]
	}
	
	method AddTargetingMe()
	{
		This:AddQueryString["IsTargetingMe && IsNPC && !IsMoribund"]
		NeedUpdate:Set[TRUE]
	}
	
	method RequestUpdate()
	{
		NeedUpdate:Set[TRUE]
		Updated:Set[FALSE]
	}
	
	method AddAllNPCs()
	{
		variable string QueryString="CategoryID = CATEGORYID_ENTITY && IsNPC && !IsMoribund && !("
		
		;Exclude Groups here
		QueryString:Concat["GroupID = GROUP_CONCORDDRONE ||"]
		QueryString:Concat["GroupID = GROUP_CONVOYDRONE ||"]
		QueryString:Concat["GroupID = GROUP_CONVOY ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLEOBJECT ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESHIP ||"]
		QueryString:Concat["GroupID = GROUP_SPAWNCONTAINER ||"]
		QueryString:Concat["GroupID = CATEGORYID_ORE ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESTRUCTURE)"]
		
		This:AddQueryString["${QueryString.Escape}"]
	}
	
	member:bool UpdateList()
	{
		Profiling:StartTrack["TargetList_UpdateList"]
		if !${NeedUpdate}
		{
			Profiling:EndTrack
			return FALSE
		}
		NeedUpdate:Set[FALSE]
		if !${Client.InSpace}
		{
			Profiling:EndTrack
			return FALSE
		}
		
		if ${Me.ToEntity.Mode} == 3
		{
			Profiling:EndTrack
			return FALSE
		}
		
		variable iterator QueryStringIterator
		QueryStringList:GetIterator[QueryStringIterator]

		if ${QueryStringIterator:First(exists)}
		{
			do
			{
				This:QueueState["GetQueryString", 250, "${QueryStringIterator.Value.Escape}"]
			}
			while ${QueryStringIterator:Next(exists)}
		}
		This:QueueState["PopulateList"]
		if ${AutoLock}
		{
			This:QueueState["ManageLocks"]
		}
		This:QueueState["SetUpdated"]
		This:QueueState["UpdateList"]
		Profiling:EndTrack
;		echo UpdateList ${This.ObjectName}
		return TRUE
	}
	
	member:bool SetUpdated()
	{
		Updated:Set[TRUE]
		return TRUE
	}
	
	member:bool GetQueryString(string QueryString)
	{
		Profiling:StartTrack["TargetList_GetQueryString"]
		variable index:entity entity_index
		variable iterator entity_iterator
		if !${Client.InSpace}
		{
			Profiling:EndTrack
			return FALSE
		}
		Profiling:StartTrack["QueryEntities"]
		EVE:QueryEntities[entity_index, "${QueryString.Escape}"]
		Profiling:EndTrack
		entity_index:GetIterator[entity_iterator]
		
		if ${entity_iterator:First(exists)}
		{
			do
			{
				if ${entity_iterator.Value.IsLockedTarget} || ${entity_iterator.Value.BeingTargeted}
				{
					TargetList_DeadDelay:Set[${entity_iterator.Value.ID}, ${Math.Calc[${LavishScript.RunningTime} + 5000]}]
				}
				if ${entity_iterator.Value.DistanceTo[${DistanceTarget}]} >= ${MinRange}
				{
					break
				}
				else
				{

				}
			}
			while ${entity_iterator:Next(exists)}
			
			if ${entity_iterator(exists)}
			{
				do
				{
					if ${entity_iterator.Value.IsLockedTarget} || ${entity_iterator.Value.BeingTargeted}
					{
						TargetList_DeadDelay:Set[${entity_iterator.Value.ID}, ${Math.Calc[${LavishScript.RunningTime} + 5000]}]
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
						break
					}
				}
				while ${entity_iterator:Next(exists)}
			}
			
			if ${entity_iterator(exists)}
			{
				do
				{
					if ${entity_iterator.Value.IsLockedTarget} || ${entity_iterator.Value.BeingTargeted}
					{
						TargetList_DeadDelay:Set[${entity_iterator.Value.ID}, ${Math.Calc[${LavishScript.RunningTime} + 5000]}]
					}
					This.TargetListBufferOOR:Insert[${entity_iterator.Value.ID}]
					if ${entity_iterator.Value.IsLockedTarget}
					{
						This.LockedTargetListBufferOOR:Insert[${entity_iterator.Value.ID}]
					}
				}
				while ${entity_iterator:Next(exists)}
			}
		}
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool PopulateList()
	{
		Profiling:StartTrack["TargetList_PopulateList"]
		This.TargetList:Clear
		This.LockedTargetList:Clear
		
		This:DeepCopyEntityIndex["This.TargetListBuffer", "This.TargetList"]
		
		This:DeepCopyEntityIndex["This.TargetListBufferOOR", "This.TargetList"]
		
		This:DeepCopyEntityIndex["This.LockedTargetListBuffer", "This.LockedTargetList"]
		
		This:DeepCopyEntityIndex["This.LockedTargetListBufferOOR", "This.LockedTargetList"]
		
		This.TargetListBuffer:Clear
		This.TargetListBufferOOR:Clear
		This.LockedTargetListBuffer:Clear
		This.LockedTargetListBufferOOR:Clear
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool ManageLocks()
	{
		if !${Client.InSpace} || ${Me.ToEntity.Mode} == 3
		{
			Profiling:EndTrack
			return TRUE
		}
		Profiling:StartTrack["TargetList_ManageLocks"]
		variable iterator EntityIterator
		variable bool NeedLock = FALSE
		variable int64 LowestLock = -1
		variable int MaxTarget = ${MyShip.MaxLockedTargets}
		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			MaxTarget:Set[${Me.MaxLockedTargets}]
		}
		This.LockedTargetList:GetIterator[EntityIterator]
		if ${EntityIterator:First(exists)}
		{
			do
			{
				if !${OwnedTargets.Contains[${EntityIterator.Value.ID}]}
				{
					LockedAndLockingTargets:Add[${EntityIterator.Value.ID}]
					OwnedTargets:Add[${EntityIterator.Value.ID}]
				}
			}
			while ${EntityIterator:Next(exists)}
		}
		
		This.LockedAndLockingTargets:GetIterator[EntityIterator]
		if ${EntityIterator:First(exists)}
		{
			do
			{
				if !${Entity[${EntityIterator.Value}](exists)} || (!${Entity[${EntityIterator.Value}].IsLockedTarget} && !${Entity[${EntityIterator.Value}].BeingTargeted})
				{
					OwnedTargets:Remove[${EntityIterator.Value}]
					LockedAndLockingTargets:Remove[${EntityIterator.Value}]
				}
			}
			while ${EntityIterator:Next(exists)}
		}

		This.TargetList:GetIterator[EntityIterator]
		if ${EntityIterator:First(exists)}
		{
			do
			{
				if !${EntityIterator.Value.IsLockedTarget} && !${EntityIterator.Value.BeingTargeted} && ${LockedAndLockingTargets.Used} < ${MinLockCount} && ${MaxTarget} > (${Me.TargetCount} + ${Me.TargetingCount}) && ${EntityIterator.Value.Distance} < ${MyShip.MaxTargetRange}
				{
					EntityIterator.Value:LockTarget
					LockedAndLockingTargets:Add[${EntityIterator.Value.ID}]
					OwnedTargets:Add[${EntityIterator.Value.ID}]
					This:QueueState["Idle", ${Math.Rand[200]}]
					Profiling:EndTrack
					return TRUE
				}
			}
			while ${EntityIterator:Next(exists)}
		}
		
		Profiling:EndTrack
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