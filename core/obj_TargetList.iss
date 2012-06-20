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

variable collection:int TargetList_DeadDelay
variable collection:obj_Target TargetList_Targets
variable int TargetList_FreeID = 1

objectdef obj_TargetList inherits obj_State
{
	variable int TargetListID
	variable int64 DistanceTarget
	variable index:entity TargetList
	variable index:entity LockedTargetList
	variable int64 ClosestOutOfRange = -1
	variable index:entity TargetListBuffer
	variable index:entity TargetListBufferOOR
	variable index:entity LockedTargetListBuffer
	variable index:entity LockedTargetListBufferOOR
	variable index:string QueryStringList
	variable set WantedTargets
	variable int64 DistanceTarget
	variable int MaxRange = 20000
	variable bool ListOutOfRange = TRUE
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[10]
		RandomDelta:Set[0]
		This:QueueState["UpdateList"]
		DistanceTarget:Set[${MyShip.ID}]
		TargetListID:Set[${TargetList_FreeID}]
		TargetList_FreeID:Inc
	}
	
	method ClearQueryString()
	{
		QueryStringList:Clear
	}
	
	method AddQueryString(string QueryString)
	{
		QueryStringList:Insert["${QueryString.Escape}"]
	}
	
	method AddTargetingMe()
	{
		This:AddQueryString["IsTargetingMe && IsNPC"]
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
				This:QueueState["GetQueryString", 20, "${QueryStringIterator.Value.Escape}"]
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
		return TRUE
		variable iterator EntityIterator
		variable bool NeedLock = FALSE
		variable int64 LowestLock = -1
		variable int MaxTarget = ${MyShip.MaxLockedTargets}
		variable int OwnedTargets = 0
		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			MaxTarget:Set[${Me.MaxLockedTargets}]
		}
		
		WantedTargets:GetIterator[EntityIterator]
		if ${EntityIterator:First(exists)}
		{
			do
			{
				if !${TargetList_Targets.Element[${EntityIterator.Key}](exists)} || !${TargetList_Targets.Element[${EntityIterator.Key}].Locked}
				{
					WantedTargets:Remove[${EntityIterator.Key}]
				}
			}
			while ${EntityIterator:Next(exists)}
		}
		
		TargetList_Targets:GetIterator[EntityIterator]
		if ${EntityIterator:First(exists)}
		{
			do
			{
				if !${EntityIterator.Value.Owner} == ${TargetListID}
				{
					OwnedTargets:Inc
				}
			}
			while ${EntityIterator:Next(exists)}
		}
		
		This.TargetList:GetIterator[EntityIterator]
		if ${EntityIterator:First(exists)}
		{
			do
			{
				if !${EntityIterator.Value.IsLockedTarget} && (${OwnedTargets} < ${MinLockCount})
				{
					TargetList_Targets.Element[${EntityIterator.Value.ID}]:LockTarget[${TargetListID}]
					WantedTargets:Add[${EntityIterator.Value.ID}]
					This:QueueState["Idle", ${Math.Random[200]}]
					return TRUE
				}
				if ${EntityIterator.Value.IsLockedTarget} && ${WantedTargets.Used} < ${MaxLockCount} && !${WantedTargets.Contains[${EntityIterator.Value.ID}]}
				{
					TargetList_Targets.Element[${EntityIterator.Value.ID}]:WantTarget[${TargetListID}]
					WantedTargets:Add[${EntityIterator.Value.ID}]
				}
			}
			while ${EntityIterator:Next(exists)}
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

objectdef obj_Target inherits obj_State
{
	variable int64 EntityID
	variable int Owner
	variable set Wanted
	variable bool Locked = FALSE
	
	method Initialize(int64 NewID = -1)
	{
		This[parent]:Initialize
		PulseFrequency:Set[250]
		RandomDelta:Set[500]
		EntityID:Set[${NewID}]
		This:QueueState["CheckEntity", 1000]
	}
	
	method LockTarget(int Owner)
	{
		if !${Locked}
		{
			This:Clear
			This:QueueState["Lock"]
			This:QueueState["CheckOwner"]
			This:QueueState["CheckEntity", 1000]
			Owner:Set[${Owner}]
			Wanted:Add[${Owner}]
		}
	}
	
	method UnlockTarget(int Owner)
	{
		if ${Locked}
		{
			Owner:Set[0]
			Wanted:Remove[${Owner}]
			if ${Wanted.Used} <= 0
			{
				Entity[${EntityID}]:UnlockTarget
				Locked:Set[FALSE]
				Owner:Set[0]
				This:Clear
				This:QueueState["CheckEntity", 1000]
				return
			}
			Wanted:GetIterator[WantedIterator]
			WantedIterator:First
			Owner:Set[${WantedIterator.Key}]
			Wanted:Remove[${WantedIterator.Key}]
		}
	}
	
	method WantTarget(int Owner)
	{
		Wanted:Add[${Owner}]
	}
	
	method UnwantTarget(int Owner)
	{
		Wanted:Remove[${Owner}]
	}
	
	method Set(int64 NewID)
	{
		EntityID:Set[${NewID}]
	}
	
	member:bool Lock()
	{
		Entity[${EntityID}]:LockTarget
		return TRUE
	}
	
	member:bool CheckLock()
	{
		variable iterator WantedIterator
		if !${Entity[${EntityID}].IsLockedTarget} && !${Entity[${EntityID}].BeingTargeted}
		{
			Wanted:Clear
			Owner:Set[0]
			return TRUE
		}
		return FALSE
	}
	
	member:bool CheckEntity()
	{
		if !${Entity[${EntityID}](exists)}
		{
			TargetList_Targets:Erase[${EntityID}]
		}
		return FALSE
	}
	
	member:string GetFallthroughObject()
	{
		return Entity[${EntityID}]
	}
}