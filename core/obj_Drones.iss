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

/*
Drone states

[22:55] <@CyberTech> STATE_OFFLINING = -7
[22:55] <@CyberTech> STATE_ANCHORING = -6
[22:55] <@CyberTech> STATE_ONLINING = -5
[22:55] <@CyberTech> STATE_ANCHORED = -4
[22:55] <@CyberTech> STATE_UNANCHORING = -3
[22:55] <@CyberTech> STATE_UNANCHORED = -2
[22:55] <@CyberTech> STATE_INCAPACITATED = -1
[22:55] <@CyberTech> STATE_IDLE = 0
[22:55] <@CyberTech> STATE_COMBAT = 1
[22:55] <@CyberTech> STATE_MINING = 2
[22:55] <@CyberTech> STATE_APPROACHING = 3
[22:55] <@CyberTech> STATE_DEPARTING = 4
[22:55] <@CyberTech> STATE_DEPARTING_2 = 5
[22:55] <@CyberTech> STATE_PURSUIT = 6
[22:55] <@CyberTech> STATE_FLEEING = 7
[22:55] <@CyberTech> STATE_REINFORCED = 8
[22:55] <@CyberTech> STATE_OPERATING = 9
[22:55] <@CyberTech> STATE_ENGAGE = 10
[22:55] <@CyberTech> STATE_VULNERABLE = 11
[22:55] <@CyberTech> STATE_SHIELD_REINFORCE = 12
[22:55] <@CyberTech> STATE_ARMOR_REINFORCE = 13
[22:55] <@CyberTech> STATE_INVULNERABLE = 14
[22:55] <@CyberTech> STATE_WARPAWAYANDDIE = 15
[22:55] <@CyberTech> STATE_WARPAWAYANDCOMEBACK = 16
[22:55] <@CyberTech> STATE_WARPTOPOSITION = 17
[22:55] <@CyberTech> You will not see all of those.
[22:56] <Vendan> hem
[22:56] <Vendan> I was hoping there was a returning state
[22:56] <Vendan> maybe it goes by a different name
[22:57] <@CyberTech>         droneStates = {const.entityIdle: 'UI/Inflight/Drone/Idle',
[22:57] <@CyberTech>          const.entityCombat: 'UI/Inflight/Drone/Fighting',
[22:57] <@CyberTech>          const.entityMining: 'UI/Inflight/Drone/Mining',
[22:57] <@CyberTech>          const.entityApproaching: 'UI/Inflight/Drone/Approaching',
[22:57] <@CyberTech>          const.entityDeparting: 'UI/Inflight/Drone/ReturningToShip',
[22:57] <@CyberTech>          const.entityDeparting2: 'UI/Inflight/Drone/ReturningToShip',
[22:57] <@CyberTech>          const.entityOperating: 'UI/Inflight/Drone/Operating',
[22:57] <@CyberTech>          const.entityPursuit: 'UI/Inflight/Drone/Following',
[22:57] <@CyberTech>          const.entityFleeing: 'UI/Inflight/Drone/Fleeing',
[22:57] <@CyberTech>          const.entityEngage: 'UI/Inflight/Drone/Repairing',
[22:57] <@CyberTech>          None: 'UI/Inflight/Drone/NoState'}
[22:57] <@CyberTech> if it's not in ^ list it's incapacitated






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

		UI:Update["Configuration", " ${This.SetName}: Initialized", "-g"]
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
				if ${Drones.InactiveDroneCount[TypeID = ${DroneTypeIDs.Key}]} > 0
				{
					return ${DroneTypeIDs.Key}
				}
			}
			while ${DroneTypeIDs:Next(exists)}
		}
		return -1
	}
}


objectdef obj_Drones inherits obj_State
{
	variable obj_Configuration_DroneData Data
	variable set ActiveTypes
	variable collection:queue TypeQueues
	
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
	
	method RefreshActiveTypes()
	{
		ActiveTypes:Clear
		variable index:activedrone ActiveDrones
		Me:GetActiveDrones[ActiveDrones]
		ActiveDrones:GetIterator[DroneIterator]
		if ${DroneIterator:First(exists)}
		{
			do
			{
				ActiveTypes:Add[${DroneIterator.Value.TypeID}]
			}
			while ${DroneIterator:Next(exists)}
		}
	}
	
	method Deploy(string TypeQuery, int Count=-1)
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
				if ${Selected} >= ${Count} && ${Count} > 0
				{
					break
				}
				ActiveTypes:Add[${DroneIterator.Value.TypeID}]
				DronesToLaunch:Insert[${DroneIterator.Value.ID}]
				Selected:Inc
			}
			while ${DroneIterator:Next(exists)}
		}
		EVE:LaunchDrones[DronesToLaunch]
	}
	
	method Recall(string TypeQuery, int Count=-1)
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
				if ${Selected} >= ${Count} && ${Count} > 0
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
	
	method Engage(string TypeQuery, int64 TargetID, int Count = -1)
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
	
	member:bool EngageTarget(string TypeQuery, int64 TargetID, int Count = -1)
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
			
			Count:Dec[${This.GetTargetting[${TargetID}]}]
			
			if ${DroneIterator:First(exists)}
			{
				do
				{
					if ${Selected} >= ${Count} && ${Count} > 0
					{
						break
					}
					if ${DroneIterator.Value.State} == 0
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