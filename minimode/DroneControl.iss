/*

ComBot  Copyright © 2012  Tehtsuo and Vendan

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


objectdef obj_DroneControl inherits obj_State
{
	variable obj_TargetList DroneTargets
	variable int64 CurrentTarget = -1
	
	method Initialize()
	{
		This[parent]:Initialize
		DynamicAddMiniMode("DroneControl", "DroneControl")
		DroneTargets.MaxRange:Set[${Me.DroneControlDistance}]
		DroneTargets.AutoLock:Set[TRUE]
		DroneTargets.MinLockCount:Set[6]
		DroneTargets:AddTargetingMe
	}
	
	method Start()
	{
		This:QueueState["DroneControl"]
	}
	
	method Stop()
	{
		This:Clear
	}
	
	member:bool DroneControl()
	{
		variable iterator TargetIterator
		if !${Client.InSpace}
		{
			return FALSE
		}
		if ${Me.ToEntity.Mode} == 3
		{
			if ${DronesOut}
			{
				This:Recall
			}
			return FALSE
		}
		DroneTargets:RequestUpdate
		if ${Drones.DronesInBay.Equal[0]} && ${Drones.DronesInSpace.Equal[0]}
		{
			return FALSE
		}
		
		DroneTargets.LockedTargetList:GetIterator[TargetIterator]
		
		if !${Entity[${CurrentTarget}](exists)} || !${Entity[${CurrentTarget}].IsLockedTarget}
		{
			CurrentTarget:Set[-1]
		}
		
		if ${TargetIterator:First(exists)}
		{
			if ${Drones.DronesInSpace.Equal[0]}
			{
				Drones:Deploy["TypeID == 21638", 5]
				return FALSE
			}
			do
			{
				if ${CurrentTarget.Equal[-1]} && ${TargetIterator.Value.Distance} < ${Me.DroneControlDistance}
				{
					CurrentTarget:Set[${TargetIterator.Value.ID}]
					Drones:Engage["TypeID == 21638", ${CurrentTarget}, 5]
					return FALSE
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		else
		{
			if !${Drones.DronesInSpace.Equal[0]}
			{
				Drones:Recall["TypeID = 21638", 5]
				This:QueueState["Idle", 5000]
				This:QueueState["DroneControl"]
				return TRUE
			}
		}
		return FALSE
	}
}