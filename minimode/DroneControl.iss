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

objectdef obj_Configuration_DroneControl inherits obj_Base_Configuration
{
	method Initialize()
	{
		This[parent]:Initialize["DroneControl"]
	}

Setting(int, DroneType, SetDroneType)
Setting(int, SentryType, SetSentryType)
Setting(bool, Sentries, SetSentries)
Setting(int, SentryRange, SetSentryRange)

}



objectdef obj_DroneControl inherits obj_State
{
	variable obj_TargetList DroneTargets
	
	variable obj_Configuration_DroneControl Config
	
	variable int RecallDelay
	
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
			if !${Drones.DronesInSpace.Equal[0]}
			{
				Drones:Recall["", 5]
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
		else
		{
			RecallDelay:Set[${Math.Calc[${LavishScript.RunningTime}+30000]}]
			if ${Entity[${CurrentTarget}].Distance} < (${Config.SentryRange} * 1000)
			{
				if ${Drones.ActiveDroneCount["TypeID == ${Config.SentryType}"]} > 0
				{
					Drones:Recall["TypeID == ${Config.SentryType}", 5]
					This:QueueState["Idle", 5000]
					This:QueueState["DroneControl"]
					return TRUE
				}
			}
			if ${Entity[${CurrentTarget}].Distance} > (${Config.SentryRange} * 1000) && ${Config.Sentries}
			{
				if ${Drones.ActiveDroneCount["TypeID == ${Config.DroneType}"]} > 0
				{
					Drones:Recall["TypeID == ${Config.DroneType}", 5]
					This:QueueState["Idle", 5000]
					This:QueueState["DroneControl"]
					return TRUE
				}
			}
			if !${Drones.DronesInSpace.Equal[0]}
			{
				Drones:Engage["TypeID == ${Config.DroneType} || TypeID == ${Config.SentryType}", ${CurrentTarget}, 5]
			}
			else
			{
				if ${Entity[${CurrentTarget}].Distance} > (${Config.SentryRange} * 1000) && ${Config.Sentries}
				{
					Drones:Deploy["TypeID == ${Config.SentryType}", 5]
				}
				else
				{
					Drones:Deploy["TypeID == ${Config.DroneType}", 5]
				}
			}
		}
		
		if ${TargetIterator:First(exists)}
		{
			do
			{
				if ${CurrentTarget.Equal[-1]} && ${TargetIterator.Value.Distance} < ${Me.DroneControlDistance}
				{
					CurrentTarget:Set[${TargetIterator.Value.ID}]
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		else
		{
			if !${Drones.DronesInSpace.Equal[0]} && ${LavishScript.RunningTime} > ${RecallDelay}
			{
				Drones:Recall["TypeID = ${Config.DroneType} || TypeID == ${Config.SentryType}", 5]
				This:QueueState["Idle", 5000]
				This:QueueState["DroneControl"]
				return TRUE
			}
		}
		return FALSE
	}
}