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

objectdef obj_Drones inherits obj_State
{
	variable obj_TargetList DroneTargets
	variable int64 CurrentTarget = -1
	variable bool DronesRemainDocked = FALSE
	variable bool DronesOut = FALSE
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[1000]
		UI:Update["obj_Drones", "Initialized", "g"]
		This:QueueState["DroneControl"]
		DroneTargets.MaxRange:Set[${Me.DroneControlDistance}]
		DroneTargets.AutoLock:Set[TRUE]
		DroneTargets.AutoRelock:Set[TRUE]
	}
	
	method Defensive()
	{
		DroneTargets:ClearQueryString
		DroneTargets:AddTargetingMe
	}
	
	method Aggressive()
	{
		DroneTargets:ClearQueryString
		DroneTargets:AddTargetingMe
		DroneTargets:AddAllNPCs
	}

	method Passive()
	{
		DroneTargets:ClearQueryString
	}

	method RemainDocked()
	{
		DronesRemainDocked:Set[TRUE]
	}

	method StayDeployed()
	{
		DronesRemainDocked:Set[FALSE]
	}

	method Recall()
	{		
		UI:Update["obj_Drone", "Recalling Drones", "g"]
		EVE:Execute[CmdDronesReturnToBay]
		DronesOut:Set[FALSE]
	}

	method Deploy()
	{
		UI:Update["obj_Drone", "Deploying Drones", "g"]
		MyShip:LaunchAllDrones
		DronesOut:Set[TRUE]
	}
	
	member:bool DroneControl()
	{
		variable index:activedrone drones
		variable iterator droneIterator
		variable index:int64 droneIDs
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
		
		
		Me:GetActiveDrones[drones]
		
		DroneTargets.LockedTargetList:GetIterator[TargetIterator]
		
		if !${Entity[${CurrentTarget}](exists)} || ${Entity[${CurrentTarget}].Distance} > ${Me.DroneControlDistance}
		{
			CurrentTarget:Set[-1]
		}
		
		if ${TargetIterator:First(exists)}
		{
			if !${DronesOut}
			{
				This:Deploy
				return FALSE
			}
			do
			{
				if ${CurrentTarget.Equal[-1]}
				{
					CurrentTarget:Set[${TargetIterator.Value.ID}]
					return FALSE
				}
				if ${CurrentTarget.Equal[${TargetIterator.Value.ID}]}
				{
					drones:GetIterator[droneIterator]
					if ${droneIterator:First(exists)}
					{
						do
						{
							if !${droneIterator.Value.Target.ID.Equal[${CurrentTarget}]}
							{
								droneIDs:Insert[${droneIterator.Value.ID}]
							}
						}
						while ${droneIterator:Next(exists)}
					}
					if ${droneIDs.Used}>0
					{
						if !${TargetIterator.Value.IsActiveTarget}
						{
							TargetIterator.Value:MakeActiveTarget
							return FALSE
						}
						EVE:DronesEngageMyTarget[droneIDs]
						return FALSE
					}
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		else
		{
			if ${DronesOut}
			{
				This:Recall
			}
		}
		return FALSE
	}
}