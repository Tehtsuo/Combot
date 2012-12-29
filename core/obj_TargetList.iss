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
variable collection:int TargetList_DeadDelay

objectdef obj_TargetList inherits obj_State
{
	variable int64 DistanceTarget
	variable index:entity TargetList
	variable index:entity LockedTargetList
	variable index:entity LockedAndLockingTargetList
	variable int64 ClosestOutOfRange = -1
	variable index:entity TargetListBuffer
	variable index:entity TargetListBufferOOR
	variable index:entity LockedTargetListBuffer
	variable index:entity LockedTargetListBufferOOR
	variable index:entity LockedAndLockingTargetListBuffer
	variable index:entity LockedAndLockingTargetListBufferOOR
	variable set AlreadyInList
	variable index:string QueryStringList
	variable collection:int TargetLockPrioritys
	variable collection:int TargetLockPrioritysBuffer
	variable set TargetExceptions
	variable set LockedAndLockingTargets
	variable int64 DistanceTarget
	variable int MaxRange = 20000
	variable int MinRange = 0
	variable bool ListOutOfRange = TRUE
	variable bool AutoLock = FALSE
	variable bool LockOutOfRange = TRUE
	variable int MinLockCount = 2
	variable int MaxLockCount = 2
	variable bool NeedUpdate = TRUE
	variable bool Updated = FALSE
	variable IPCCollection:int IPCTargets
	variable bool UseIPC = FALSE
	variable IPCCollection:int IPCExclusion
	variable bool UseIPCExclusion = FALSE
	variable bool ForceLockExclusion = FALSE
	variable bool LockTop = FALSE
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[20]
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
		This:AddQueryString["Distance < 150000 && IsTargetingMe && IsNPC && !IsMoribund"]
		NeedUpdate:Set[TRUE]
	}
	
	method SetIPCName(string IPCName)
	{
		IPCTargets:SetIPCName[${IPCName}]
		UseIPC:Set[TRUE]
	}
	
	method SetIPCExclusion(string IPCName)
	{
		IPCExclusion:SetIPCName[${IPCName}]
		UseIPCExclusion:Set[TRUE]
	}
	
	method RequestUpdate()
	{
		variable iterator TargetIterator
		TargetList:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			do
			{
				if !${TargetIterator.Value.ID(exists)}
				{
					TargetList:Remove[${TargetIterator.Key}]
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		TargetList:Collapse
		
		LockedTargetList:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			do
			{
				if !${TargetIterator.Value.ID(exists)}
				{
					LockedTargetList:Remove[${TargetIterator.Key}]
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		LockedTargetList:Collapse

		LockedAndLockingTargetList:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			do
			{
				if !${TargetIterator.Value.ID(exists)}
				{
					LockedAndLockingTargetList:Remove[${TargetIterator.Key}]
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		LockedAndLockingTargetList:Collapse
		
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
	
	method AddTargetException(int64 ID)
	{
		variable iterator RemoveIterator
		TargetExceptions:Add[${ID}]
		TargetList:GetIterator[RemoveIterator]
		if ${RemoveIterator:First(exists)}
		{
			do
			{
				if ${RemoveIterator.Value.ID.Equal[${ID}]}
				{
					TargetList:Remove[${RemoveIterator.Key}]
				}
			}
			while ${RemoveIterator:Next(exists)}
		}
		LockedTargetList:GetIterator[RemoveIterator]
		if ${RemoveIterator:First(exists)}
		{
			do
			{
				if ${RemoveIterator.Value.ID.Equal[${ID}]}
				{
					LockedTargetList:Remove[${RemoveIterator.Key}]
				}
			}
			while ${RemoveIterator:Next(exists)}
		}
		LockedAndLockingTargetList:GetIterator[RemoveIterator]
		if ${RemoveIterator:First(exists)}
		{
			do
			{
				if ${RemoveIterator.Value.ID.Equal[${ID}]}
				{
					LockedAndLockingTargetList:Remove[${RemoveIterator.Key}]
				}
			}
			while ${RemoveIterator:Next(exists)}
		}
		if ${Entity[${ID}].IsLockedTarget}
		{
			Entity[${ID}]:UnlockTarget
		}
	}
	
	method ClearTargetExceptions()
	{
		TargetExceptions:Clear
	}
	
	member:bool UpdateList()
	{
		Profiling:StartTrack["TargetList_UpdateList"]
		if !${NeedUpdate}
		{
			Profiling:EndTrack
			return FALSE
		}
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
				This:QueueState["GetQueryString", 20, "${QueryStringIterator.Value.Escape}, ${Math.Calc[${QueryStringList.Used}-${QueryStringIterator.Key}]}"]
			}
			while ${QueryStringIterator:Next(exists)}
		}
		
		if ${UseIPC}
		{
			This:QueueState["AddIPC"]
		}
		
		This:QueueState["PopulateList"]
		if ${AutoLock}
		{
			This:QueueState["ManageLocks"]
		}
		This:QueueState["SetUpdated"]
		This:QueueState["UpdateList"]
		NeedUpdate:Set[FALSE]
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool SetUpdated()
	{
		Updated:Set[TRUE]
		return TRUE
	}
	
	member:bool GetQueryString(string QueryString, int Priority = 0)
	{
		Profiling:StartTrack["${This.ObjectName}: TargetList_GetQueryString"]
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
			
			if ${entity_iterator.Value(exists)}
			{
				do
				{
					if ${entity_iterator.Value.IsLockedTarget} || ${entity_iterator.Value.BeingTargeted}
					{
						TargetList_DeadDelay:Set[${entity_iterator.Value.ID}, ${Math.Calc[${LavishScript.RunningTime} + 5000]}]
					}
					if ${entity_iterator.Value.DistanceTo[${DistanceTarget}]} <= ${MaxRange}
					{
						if !${TargetExceptions.Contains[${entity_iterator.Value.ID}]} && !${AlreadyInList.Contains[${entity_iterator.Value.ID}]}
						{
							This.TargetListBuffer:Insert[${entity_iterator.Value.ID}]
							AlreadyInList:Add[${entity_iterator.Value.ID}]
							TargetLockPrioritysBuffer:Set[${entity_iterator.Value.ID}, ${Priority}]
							if ${entity_iterator.Value.IsLockedTarget}
							{
								This.LockedTargetListBuffer:Insert[${entity_iterator.Value.ID}]
								This.LockedAndLockingTargetListBuffer:Insert[${entity_iterator.Value.ID}]
								TargetLockPrioritysBuffer:Set[${entity_iterator.Value.ID}, ${Math.Calc[${Priority} + ${Ship.ModuleList_TargetModules.ActiveCountOn[${entity_iterator.Value.ID}]}*100]}]
							}
							if ${entity_iterator.Value.BeingTargeted}
							{
								This.LockedAndLockingTargetListBuffer:Insert[${entity_iterator.Value.ID}]
							}
						}
					}
					else
					{
						break
					}
				}
				while ${entity_iterator:Next(exists)}
			}
			
			if ${entity_iterator.Value(exists)} && ${ListOutOfRange}
			{
				do
				{
					if ${entity_iterator.Value.IsLockedTarget} || ${entity_iterator.Value.BeingTargeted}
					{
						TargetList_DeadDelay:Set[${entity_iterator.Value.ID}, ${Math.Calc[${LavishScript.RunningTime} + 5000]}]
					}
					if !${TargetExceptions.Contains[${entity_iterator.Value.ID}]} && !${AlreadyInList.Contains[${entity_iterator.Value.ID}]}
					{
						This.TargetListBufferOOR:Insert[${entity_iterator.Value.ID}]
						AlreadyInList:Add[${entity_iterator.Value.ID}]
						TargetLockPrioritysBuffer:Set[${entity_iterator.Value.ID}, ${Math.Calc[${Priority}-1000]}]
						if ${entity_iterator.Value.IsLockedTarget}
						{
							This.LockedTargetListBufferOOR:Insert[${entity_iterator.Value.ID}]
							This.LockedAndLockingTargetListBufferOOR:Insert[${entity_iterator.Value.ID}]
							TargetLockPrioritysBuffer:Set[${entity_iterator.Value.ID}, ${Math.Calc[(${Priority}-1000) + ${Ship.ModuleList_TargetModules.ActiveCountOn[${entity_iterator.Value.ID}]}*100]}]
						}
						if ${entity_iterator.Value.BeingTargeted}
						{
							This.LockedAndLockingTargetListBufferOOR:Insert[${entity_iterator.Value.ID}]
						}
					}
				}
				while ${entity_iterator:Next(exists)}
			}
		}
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool AddIPC()
	{
		Profiling:StartTrack["TargetList_AddIPC"]
		variable iterator EntityIterator

		This.TargetListBuffer:GetIterator[EntityIterator]
		if ${EntityIterator:First(exists)}
		{
			do
			{
				if !${This.IPCTargets.Element[${EntityIterator.Value.ID}](exists)}
				{
					This.IPCTargets:Set[${EntityIterator.Value.ID}, ${Math.Calc[${LavishScript.RunningTime} + 40000]}]
				}
				else
				{
					if ${This.IPCTargets.Element[${EntityIterator.Value.ID}]} < ${Math.Calc[${LavishScript.RunningTime} - 20000]}
					{
						This.IPCTargets:Set[${EntityIterator.Value.ID}, ${Math.Calc[${LavishScript.RunningTime} + 40000]}]
					}
				}
			}
			while ${EntityIterator:Next(exists)}
		}
		This.TargetListBufferOOR:GetIterator[EntityIterator]
		if ${EntityIterator:First(exists)}
		{
			do
			{
				if !${This.IPCTargets.Element[${EntityIterator.Value.ID}](exists)}
				{
					This.IPCTargets:Set[${EntityIterator.Value.ID}, ${Math.Calc[${LavishScript.RunningTime} + 40000]}]
				}
				else
				{
					if ${This.IPCTargets.Element[${EntityIterator.Value.ID}]} < ${Math.Calc[${LavishScript.RunningTime} - 20000]}
					{
						This.IPCTargets:Set[${EntityIterator.Value.ID}, ${Math.Calc[${LavishScript.RunningTime} + 40000]}]
					}
				}
			}
			while ${EntityIterator:Next(exists)}
		}
		
		This.IPCTargets:GetIterator[EntityIterator]
		if ${EntityIterator:First(exists)}
		{
			do
			{
				if ${Entity[${EntityIterator.Key}](exists)}
				{
					if ${Entity[${EntityIterator.Key}].IsLockedTarget} || ${Entity[${EntityIterator.Key}].BeingTargeted}
					{
						TargetList_DeadDelay:Set[${EntityIterator.Key}, ${Math.Calc[${LavishScript.RunningTime} + 5000]}]
					}
					if ${Entity[${EntityIterator.Key}].DistanceTo[${DistanceTarget}]} <= ${MinRange}
					{
					}
					elseif ${Entity[${EntityIterator.Key}].DistanceTo[${DistanceTarget}]} <= ${MaxRange}
					{
						if !${AlreadyInList.Contains[${entity_iterator.Value.ID}]}
						{
							AlreadyInList:Add[${entity_iterator.Value.ID}]
							This.TargetListBuffer:Insert[${EntityIterator.Key}]
							TargetLockPrioritysBuffer:Set[${entity_iterator.Value.ID}, ${Priority}]
							if ${Entity[${EntityIterator.Key}].IsLockedTarget}
							{
								This.LockedTargetListBuffer:Insert[${EntityIterator.Key}]
								This.LockedAndLockingTargetListBuffer:Insert[${EntityIterator.Key}]
								TargetLockPrioritysBuffer:Set[${entity_iterator.Value.ID}, ${Math.Calc[${Priority} + ${Ship.ModuleList_TargetModules.ActiveCountOn[${entity_iterator.Value.ID}]}*100]}]
							}
							if ${Entity[${EntityIterator.Key}].BeingTargeted}
							{
								This.LockedAndLockingTargetListBuffer:Insert[${EntityIterator.Key}]
							}
						}
					}
					elseif ${Entity[${EntityIterator.Key}].DistanceTo[${DistanceTarget}]} > ${MaxRange} && ${ListOutOfRange}
					{
						if !${AlreadyInList.Contains[${entity_iterator.Value.ID}]}
						{
							AlreadyInList:Add[${entity_iterator.Value.ID}]
							This.TargetListBufferOOR:Insert[${EntityIterator.Key}]
							TargetLockPrioritysBuffer:Set[${entity_iterator.Value.ID}, ${Math.Calc[${Priority}-1000]}]
							if ${Entity[${EntityIterator.Key}].IsLockedTarget}
							{
								This.LockedTargetListBufferOOR:Insert[${EntityIterator.Key}]
								This.LockedAndLockingTargetListBufferOOR:Insert[${EntityIterator.Key}]
								TargetLockPrioritysBuffer:Set[${entity_iterator.Value.ID}, ${Math.Calc[(${Priority}-1000) + ${Ship.ModuleList_TargetModules.ActiveCountOn[${entity_iterator.Value.ID}]}*100]}]
							}
							if ${Entity[${EntityIterator.Key}].BeingTargeted}
							{
								This.LockedAndLockingTargetListBufferOOR:Insert[${EntityIterator.Key}]
							}
						}
					}
				}
				else
				{
					if ${EntityIterator.Value} > ${LavishScript.RunningTime}
					{
						This.IPCTargets:Erase[${EntityIterator.Key}]
					}
				}
			}
			while ${EntityIterator:Next(exists)}
		}
		
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool PopulateList()
	{
		Profiling:StartTrack["TargetList_PopulateList"]
		This.TargetList:Clear
		This.LockedTargetList:Clear
		This.LockedAndLockingTargetList:Clear
		This.TargetLockPrioritys:Clear
		
		This:DeepCopyEntityIndex["This.TargetListBuffer", "This.TargetList"]
		
		This:DeepCopyEntityIndex["This.TargetListBufferOOR", "This.TargetList"]
		
		This:DeepCopyEntityIndex["This.LockedTargetListBuffer", "This.LockedTargetList"]
		
		This:DeepCopyEntityIndex["This.LockedTargetListBufferOOR", "This.LockedTargetList"]
		
		This:DeepCopyEntityIndex["This.LockedAndLockingTargetListBuffer", "This.LockedAndLockingTargetList"]
		
		This:DeepCopyEntityIndex["This.LockedAndLockingTargetListBufferOOR", "This.LockedAndLockingTargetList"]
		
		This:DeepCopyCollection["This.TargetLockPrioritysBuffer", "This.TargetLockPrioritys"]
		
		This.TargetListBuffer:Clear
		This.TargetListBufferOOR:Clear
		This.LockedTargetListBuffer:Clear
		This.LockedTargetListBufferOOR:Clear
		This.LockedAndLockingTargetListBuffer:Clear
		This.LockedAndLockingTargetListBufferOOR:Clear
		This.TargetLockPrioritysBuffer:Clear
		AlreadyInList:Clear
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool ManageLocks()
	{
		variable bool NeedLock = FALSE
		variable int TopLocks = 0
		variable bool IsTopLocked = FALSE
		variable iterator LockIterator
		variable int LowestPriority = 999999999
		variable int64 LowestLock = -1
		if !${Client.InSpace} || ${Me.ToEntity.Mode} == 3
		{
			Profiling:EndTrack
			return TRUE
		}
		Profiling:StartTrack["TargetList_ManageLocks"]
		variable iterator EntityIterator
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
					if ${UseIPCExclusion}
					{
						IPCExclusion:Erase[${EntityIterator.Value}]
					}
					LockedAndLockingTargets:Remove[${EntityIterator.Value}]
				}
			}
			while ${EntityIterator:Next(exists)}
		}

		This.TargetList:GetIterator[EntityIterator]
		
		
		
		if ${LockTop}
		{
			if ${EntityIterator:First(exists)}
			{
				do
				{
					if ${EntityIterator.Value.ID(exists)}
					{
						IsTopLocked:Set[FALSE]
						if ${EntityIterator.Value.IsLockedTarget} || ${EntityIterator.Value.BeingTargeted}
						{
							TopLocks:Inc
							IsTopLocked:Set[TRUE]
						}
						if ${UseIPCExclusion}
						{
							if ${IPCExclusion.Element[${EntityIterator.Value.ID}](exists)}
							{
								IsTopLocked:Set[TRUE]
							}
						}
						if !${IsTopLocked}
						{
							break
						}
					}
				}
				while ${EntityIterator:Next(exists)}
			}
			if ${TopLocks} < ${MinLockCount}
			{
				NeedLock:Set[TRUE]
			}
		}
		else
		{
			if ${LockedAndLockingTargets.Used} < ${MinLockCount}
			{
				NeedLock:Set[TRUE]
			}
		}
		
		if ${NeedLock} && ${LockTop} && ${LockedAndLockingTargets.Used} >= ${MinLockCount}
		{
			LockedTargetList:GetIterator[LockIterator]
			if ${LockIterator:First(exists)}
			{
				do
				{
					if ${TargetLockPrioritys.Element[${LockIterator.Value}]} < ${LowestPriority}
					{
						LowestLock:Set[${LockIterator.Value.ID}]
						LowestPriority:Set[${TargetLockPrioritys.Element[${LockIterator.Value}]}]
					}
				}
				while ${LockIterator:Next(exists)}
			}
		}
		
		if ${NeedLock}
		{
			if ${EntityIterator:First(exists)}
			{
				do
				{
					if ${EntityIterator.Value.ID(exists)}
					{
						if ${LockTop} && !${EntityIterator.Value.IsLockedTarget} && !${EntityIterator.Value.BeingTargeted} && ${LockedAndLockingTargets.Used} >= ${MinLockCount} && ${TargetLockPrioritys.Element[${EntityIterator.Value.ID}]} > ${LowestPriority} && ${EntityIterator.Value.Distance} < ${MyShip.MaxTargetRange} && (${EntityIterator.Value.Distance} < ${MaxRange} || ${LockOutOfRange}) && ${TargetList_DeadDelay.Element[${EntityIterator.Value.ID}]} < ${LavishScript.RunningTime} && (!${UseIPCExclusion} || (!${IPCExclusion.Element[${EntityIterator.Value.ID}](exists)} || ${IPCExclusion.Element[${EntityIterator.Value.ID}].Equal[${Me.CharID}]}))
						{
							Entity[${LowestLock}]:UnlockTarget
							This:InsertState["ManageLocks"]
							This:InsertState["Idle", 1000]
							return TRUE
						}
						if !${EntityIterator.Value.IsLockedTarget} && !${EntityIterator.Value.BeingTargeted} && ${LockedAndLockingTargets.Used} < ${MinLockCount} && ${MaxTarget} > (${Me.TargetCount} + ${Me.TargetingCount}) && ${EntityIterator.Value.Distance} < ${MyShip.MaxTargetRange} && (${EntityIterator.Value.Distance} < ${MaxRange} || ${LockOutOfRange}) && ${TargetList_DeadDelay.Element[${EntityIterator.Value.ID}]} < ${LavishScript.RunningTime}
						{
							if ${UseIPCExclusion}
							{
								if !${IPCExclusion.Element[${EntityIterator.Value.ID}](exists)}
								{
									IPCExclusion:Set[${EntityIterator.Value.ID}, ${Me.CharID}]
									This:InsertState["LockIfMine", "1000", ${EntityIterator.Value.ID}]
									Profiling:EndTrack
									return TRUE
								}
								if ${IPCExclusion.Element[${EntityIterator.Value.ID}].Equal[${Me.CharID}]}
								{
									EntityIterator.Value:LockTarget
									LockedAndLockingTargets:Add[${EntityIterator.Value.ID}]
									OwnedTargets:Add[${EntityIterator.Value.ID}]
									This:QueueState["Idle", ${Math.Rand[200]}]
									Profiling:EndTrack
									return TRUE
								}
							}
							else
							{
								EntityIterator.Value:LockTarget
								LockedAndLockingTargets:Add[${EntityIterator.Value.ID}]
								OwnedTargets:Add[${EntityIterator.Value.ID}]
								This:QueueState["Idle", ${Math.Rand[200]}]
								Profiling:EndTrack
								return TRUE
							}
						}
					}
				}
				while ${EntityIterator:Next(exists)}
			}
			if ${UseIPCExclusion} && ${ForceLockExclusion}
			{
				if ${EntityIterator:First(exists)}
				{
					do
					{
						if ${EntityIterator.Value.ID(exists)}
						{
							if !${EntityIterator.Value.IsLockedTarget} && !${EntityIterator.Value.BeingTargeted} && ${LockedAndLockingTargets.Used} < ${MinLockCount} && ${MaxTarget} > (${Me.TargetCount} + ${Me.TargetingCount}) && ${EntityIterator.Value.Distance} < ${MyShip.MaxTargetRange} && (${EntityIterator.Value.Distance} < ${MaxRange} || ${LockOutOfRange}) && ${TargetList_DeadDelay.Element[${EntityIterator.Value.ID}]} < ${LavishScript.RunningTime}
							{
								EntityIterator.Value:LockTarget
								LockedAndLockingTargets:Add[${EntityIterator.Value.ID}]
								OwnedTargets:Add[${EntityIterator.Value.ID}]
								This:QueueState["Idle", ${Math.Rand[200]}]
								Profiling:EndTrack
								return TRUE
							}
						}
					}
					while ${EntityIterator:Next(exists)}
				}
			}
		}
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool LockIfMine(int64 ID)
	{
		if ${IPCExclusion.Element[${ID}].Equal[${Me.CharID}]}
		{
			Entity[${ID}]:LockTarget
			LockedAndLockingTargets:Add[${ID}]
			OwnedTargets:Add[${ID}]
			This:QueueState["Idle", ${Math.Rand[200]}]
		}
		return TRUE
	}
	
	method LockTarget(int64 Target, int Priority)
	{
		variable iterator LockIterator
		variable int LowestPriority = 9999999
		variable int64 LowestLock
		if ${LockedAndLockingTargets.Used} >= ${MinLockCount}
		{
			TargetLockPrioritys:GetIterator[LockIterator]
			if ${LockIterator:First(exists)}
			{
				do
				{
					if ${LockIterator.Value} < ${LowestPriority}
					{
						LowestLock:Set[${LockIterator.Key}]
						LowestPriority:Set[${LockIterator.Value}]
					}
				}
				while ${LockIterator:Next(exists)}
			}
			if ${LowestPriority} < ${Priority}
			{
				Entity[${LowestLock}]:UnlockTarget
				return FALSE
			}
		}
		This:InsertState[LockNewTarget, 250, ${ID}]
	}
	
	member:bool LockNewTarget(int64 ID)
	{
		if ${Entity[${ID}](exists)}
		{
			Entity[${ID}]:LockTarget
		}
		return TRUE
	}
	
	method ClearExclusions()
	{
		variable iterator ExclusionIterator
		variable queue:string EraseQueue
		
		IPCExclusion:GetIterator[ExclusionIterator]
		
		if ${ExclusionIterator:First(exists)}
		{
			do
			{
				if ${ExclusionIterator.Value.Equal[${Me.CharID}]}
				{
					EraseQueue:Queue[${ExclusionIterator.Key}]
				}
			}
			while ${ExclusionIterator:Next(exists)}
		}
		while ${EraseQueue.Used} > 0
		{
			IPCExclusion:Erase[${EraseQueue.Peek}]
			EraseQueue:Dequeue
		}
		
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
	
	method DeepCopyCollection(string From, string To)
	{
		variable iterator ColIterator
		${From}:GetIterator[ColIterator]
		if ${ColIterator:First(exists)}
		{
			do
			{
				${To}:Set[${ColIterator.Key}, ${ColIterator.Value}]
			}
			while ${ColIterator:Next(exists)}
		}
	}
	
}