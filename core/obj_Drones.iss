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

objectdef obj_Configuration_DroneData
{
	variable string SetName = "Drone Data"

	variable filepath CONFIG_PATH = "${Script.CurrentDirectory}/data"
	variable string CONFIG_FILE = "DroneData.xml"
	variable settingsetref BaseRef

	method Initialize()
	{
		LavishSettings[DroneData]:Clear
		LavishSettings:AddSet[DroneData]

		if ${CONFIG_PATH.FileExists["${CONFIG_FILE}"]}
		{
			LavishSettings[DroneData]:Import["${CONFIG_PATH}/${CONFIG_FILE}"]
		}
		BaseRef:Set[${LavishSettings[DroneData].FindSet[DroneTypes]}]

		UI:Update["obj_Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	method Shutdown()
	{
		LavishSettings[DroneData]:Clear
	}
	
	member:string DroneType(int TypeID)
	{
		variable iterator DroneTypes
		BaseRef:GetSetIterator[DroneTypes]
		if ${DroneTypes:First(exists)}
		{
			do
			{
				if ${DroneTypes.Value.FindSetting[${TypeID}](exists)}
				{
					return ${DroneTypes.Key}
				}
			}
			while ${DroneTypes:Next(exists)}
		}
	}
	
	member:int FindType(string TypeName)
	{
		variable iterator DroneTypeIDs
		BaseRef.FindSet[${TypeName}]:GetSettingIterator[DroneTypeIDs]
		if ${DroneTypeIDs:First(exists)}
		{
			do
			{
				if ${Drones.InactiveDroneCount[${DroneTypeIDs.Key}]} > 0
				{
					return ${DroneTypeIDs.Key}
				}
			}
			while ${DroneTypeIDs:Next(exists)}
		}
	}
}


objectdef obj_Drones inherits obj_State
{
	variable obj_Configuration_DroneData Data
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[250]
	}

	method RecallAll()
	{		
		UI:Update["obj_Drone", "Recalling Drones", "g"]
		EVE:Execute[CmdDronesReturnToBay]
		DronesOut:Set[FALSE]
	}

	method Deploy(string TypeQuery, int Count=1)
	{
		variable index:item DroneBayDrones
		variable index:int64 DronesToLaunch
		variable iterator DroneIterator
		variable int Selected = 0
		MyShip:GetDrones[DroneBayDrones]
		DroneBayDrones:RemoveByQuery[${LavishScript.CreateQuery[${TypeQuery}]}, FALSE]
		DroneBayDrones:Collapse[]
		DroneBayDrones:GetIterator[DroneIterator]
		if ${DroneIterator:First(exists)}
		{
			do
			{
				if ${Selected} >= ${Count}
				{
					break
				}
				DronesToLaunch:Insert[${DroneIterator.Value.ID}]
				Selected:Inc
			}
			while ${DroneIterator:Next(exists)}
		}
		EVE:LaunchDrones[DronesToLaunch]
	}
	
	method Recall(string TypeQuery, int Count=1)
	{
		variable index:activedrone ActiveDrones
		variable index:int64 DronesToRecall
		variable iterator DroneIterator
		variable int Selected = 0
		Me:GetActiveDrones[ActiveDrones]
		ActiveDrones:RemoveByQuery[${LavishScript.CreateQuery[${TypeQuery}]}, FALSE]
		ActiveDrones:Collapse[]
		ActiveDrones:GetIterator[DroneIterator]
		if ${DroneIterator:First(exists)}
		{
			do
			{
				if ${Selected} >= ${Count}
				{
					break
				}
				DronesToRecall:Insert[${DroneIterator.Value.ID}]
				Selected:Inc
			}
			while ${DroneIterator:Next(exists)}
		}
		EVE:DronesReturnToDroneBay[DronesToRecall]
	}
	
	member:int GetTargeting(int64 TargetID)
	{
		variable index:activedrone ActiveDrones
		variable iterator DroneIterator
		variable int Targeting = 0
		Me:GetActiveDrones[ActiveDrones]
		ActiveDrones:GetIterator[DroneIterator]
		if ${DroneIterator:First(exists)}
		{
			do
			{
				if ${DroneIterator.Value.Target.ID.Equal[${TargetID}]}
				{
					Targeting:Inc
				}
			}
			while ${DroneIterator:Next(exists)}
		}
		return ${Targeting}
	}
	
	method Engage(string TypeQuery, int64 TargetID, int Count = 1)
	{
		if ${Entity[${TargetID}].IsLockedTarget}
		{
			This:QueueState["SwitchTarget", -1, ${TargetID}]
			This:QueueState["EngageTarget", -1, "${TypeQuery.Escape}, ${TargetID}, ${Count}"]
		}
	}
	
	member:int InactiveDroneCount(string TypeQuery)
	{
		variable index:item DroneBayDrones
		MyShip:GetDrones[DroneBayDrones]
		DroneBayDrones:RemoveByQuery[${LavishScript.CreateQuery[${TypeQuery}]}, FALSE]
		DroneBayDrones:Collapse[]
		return ${DroneBayDrones.Used}
	}
	
	member:int ActiveDroneCount(string TypeQuery)
	{
		variable index:activedrone ActiveDrones
		Me:GetActiveDrones[ActiveDrones]
		ActiveDrones:RemoveByQuery[${LavishScript.CreateQuery[${TypeQuery}]}, FALSE]
		ActiveDrones:Collapse[]
		return ${ActiveDrones.Used}
	}
	
	member:bool SwitchTarget(int64 TargetID)
	{
		if ${Entity[${TargetID}].IsLockedTarget}
		{
			Entity[${TargetID}]:MakeActiveTarget
		}
		return TRUE
	}
	
	member:bool EngageTarget(string TypeQuery, int64 TargetID, int Count = 1)
	{
		if ${Entity[${TargetID}].IsLockedTarget} && ${Entity[${TargetID}].IsActiveTarget}
		{
			variable index:activedrone ActiveDrones
			variable index:int64 DronesToEngage
			variable iterator DroneIterator
			variable int Selected = 0
			Me:GetActiveDrones[ActiveDrones]
			ActiveDrones:RemoveByQuery[${LavishScript.CreateQuery[${TypeQuery}]}, FALSE]
			ActiveDrones:Collapse[]
			ActiveDrones:GetIterator[DroneIterator]
			if ${DroneIterator:First(exists)}
			{
				do
				{
					if ${Selected} >= ${Count}
					{
						break
					}
					if !${DroneIterator.Value.Target.Equal[${TargetID}]}
					{
						DronesToEngage:Insert[${DroneIterator.Value.ID}]
					}
					Selected:Inc
				}
				while ${DroneIterator:Next(exists)}
			}
			EVE:DronesEngageMyTarget[DronesToEngage]
		}
		return TRUE
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
	
	

}