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
		This:QueueState["DroneControl"]
		DroneTargets.MaxRange:Set[${Me.DroneControlDistance}]
		DroneTargets.AutoLock:Set[TRUE]
		DroneTargets.AutoRelock:Set[TRUE]
		DroneTargets:SetIPCName["DroneTargets"]
		
		variable index:activedrone ActiveDrones
		Me:GetActiveDrones[ActiveDrones]
		if ${ActiveDrones.Used}
		{
			DronesOut:Set[TRUE]
		}
	}
	
	method Defensive()
	{
		DroneTargets:ClearQueryString
		DroneTargets:AddTargetingMe
	}
	
	method Aggressive()
	{
		DroneTargets:ClearQueryString
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
	
	member:int DronesInSpace()
	{
		variable index:activedrone ActiveDrones
		Me:GetActiveDrones[ActiveDrones]
		return ${ActiveDrones.Used}
	}
	
	member:int DronesInBay()
	{
		variable index:item Drones
		MyShip:GetDrones[Drones]
		return ${Drones.Used}
	}
	
	member:bool DroneControl()
	{
		Profiling:StartTrack["Drones_DroneControl"]
		variable index:activedrone drones
		variable iterator droneIterator
		variable index:int64 droneIDs
		variable iterator TargetIterator
		
		if !${Client.InSpace}
		{
			Profiling:EndTrack
			return FALSE
		}
		if ${Me.ToEntity.Mode} == 3
		{
			if ${DronesOut}
			{
				This:Recall
			}
			Profiling:EndTrack
			return FALSE
		}
		DroneTargets:RequestUpdate
		if ${This.DronesInBay.Equal[0]} && ${This.DronesInSpace.Equal[0]}
		{
			return FALSE
		}
		
		Me:GetActiveDrones[drones]
		
		DroneTargets.LockedTargetList:GetIterator[TargetIterator]
		
		
		if !${Entity[${CurrentTarget}](exists)} || !${Entity[${CurrentTarget}].IsLockedTarget}
		{
			CurrentTarget:Set[-1]
		}
		
		if ${TargetIterator:First(exists)}
		{
			if ${This.DronesInSpace.Equal[0]}
			{
				This:Deploy
				This:QueueState["Idle", 5000]
				This:QueueState["DroneControl"]
				Profiling:EndTrack
				return TRUE
			}
			do
			{
				if ${CurrentTarget.Equal[-1]} && ${TargetIterator.Value.Distance} < ${Me.DroneControlDistance}
				{
					CurrentTarget:Set[${TargetIterator.Value.ID}]
					Profiling:EndTrack
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
						Profiling:EndTrack
						return FALSE
					}
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		else
		{
			if !${This.DronesInSpace.Equal[0]}
			{
				This:Recall
				This:QueueState["Idle", 5000]
				This:QueueState["DroneControl"]
				return TRUE
			}
		}
		Profiling:EndTrack
		return FALSE
	}
}