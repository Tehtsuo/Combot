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

objectdef obj_Ship inherits obj_State
{
	variable int RetryUpdateModuleList=1
	
	variable index:string ModuleLists
	variable collection:uint ModuleQueries

	method Initialize(int64 ID)
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		ModuleLists:Insert[ArmorProjectors, "ToItem.GroupID = GROUP_ARMOR_PROJECTOR"]
		ModuleLists:Insert[ShieldTransporters, "ToItem.GroupID = GROUP_SHIELD_TRANSPORTERS"]
		ModuleLists:Insert[MiningLaser, "MiningAmount !~ NULL"]
		ModuleLists:Insert[Weapon, "ToItem.GroupID = GROUP_ENERGYWEAPON || ToItem.GroupID = GROUP_PROJECTILEWEAPON || ToItem.GroupID = GROUP_HYBRIDWEAPON || ToItem.GroupID = GROUP_MISSILELAUNCHER || ToItem.GroupID = GROUP_MISSILELAUNCHERASSAULT || ToItem.GroupID = GROUP_MISSILELAUNCHERBOMB || ToItem.GroupID = GROUP_MISSILELAUNCHERCITADEL || ToItem.GroupID = GROUP_MISSILELAUNCHERCRUISE || ToItem.GroupID = GROUP_MISSILELAUNCHERDEFENDER || ToItem.GroupID = GROUP_MISSILELAUNCHERHEAVY || ToItem.GroupID = GROUP_MISSILELAUNCHERHEAVYASSAULT || ToItem.GroupID = GROUP_MISSILELAUNCHERROCKET || ToItem.GroupID = GROUP_MISSILELAUNCHERSIEGE || ToItem.GroupID = GROUP_MISSILELAUNCHERSNOWBALL || ToItem.GroupID = GROUP_MISSILELAUNCHERSTANDARD"]
		ModuleLists:Insert[ECCM, "ToItem.GroupID = GROUP_ECCM"]
		ModuleLists:Insert[ActiveResists, "ToItem.GroupID = GROUP_DAMAGE_CONTROL || ToItem.GroupID = GROUP_SHIELD_HARDENER || ToItem.GroupID = GROUP_ARMOR_HARDENERS || ToItem.GroupID = GROUP_ARMOR_RESISTANCE_SHIFT_HARDENER"]
		ModuleLists:Insert[Regen_Shield, "ToItem.GroupID = GROUP_SHIELD_BOOSTER"]
		ModuleLists:Insert[Repair_Armor, "ToItem.GroupID = GROUP_ARMOR_REPAIRERS"]
		ModuleLists:Insert[Repair_Hull, "ToItem.GroupID = NONE"]
		ModuleLists:Insert[AB_MWD, "ToItem.GroupID = GROUP_AFTERBURNER"]
		ModuleLists:Insert[Passive, "!IsActivatable"]
		ModuleLists:Insert[Salvagers, "(ToItem.GroupID = GROUP_DATA_MINER && ToItem.TypeID = TYPE_SALVAGER) || ToItem.GroupID = GROUP_SALVAGER"]
		ModuleLists:Insert[TractorBeams, "ToItem.GroupID = GROUP_TRACTOR_BEAM"]
		ModuleLists:Insert[Cloaks, "ToItem.GroupID = GROUP_CLOAKING_DEVICE"]
		ModuleLists:Insert[StasisWeb, "ToItem.GroupID = GROUP_STASIS_WEB"]
		ModuleLists:Insert[SensorBoost, "ToItem.GroupID = GROUP_SENSORBOOSTER"]
		ModuleLists:Insert[TargetPainter, "ToItem.GroupID = GROUP_TARGETPAINTER"]
		ModuleLists:Insert[TrackingComputer, "ToItem.GroupID = GROUP_TRACKINGCOMPUTER"]
		ModuleLists:Insert[GangLinks, "ToItem.GroupID = GROUP_GANGLINK"]
		ModuleLists:Insert[EnergyTransfer, "ToItem.GroupID = GROUP_ENERGY_TRANSFER"]
		This:QueueState["WaitForSpace"]
		This:QueueState["UpdateModules"]
	}
	
	method AddModuleList(string Name, string QueryString)
	{
		This.ModuleLists:Insert[${Name}]
		This.ModuleQueries:Set[${This.ModuleLists.Used}, ${LavishScript.CreateQuery[${QueryString.Escape}]}]
		declarevariable ModuleList_${Name} obj_ModuleList object
		This:Clear
		This:QueueState["WaitForSpace"]
		This:QueueState["UpdateModules"]
	}
	
	member:bool WaitForSpace()
	{
		if ${Client.InSpace}
		{
			return TRUE
		}
		return FALSE
	}	
	
	method UpdateModules()
	{
		variable iterator List
		variable index:module ModuleList
		ModuleLists:GetIterator[List]

		if !${Client.InSpace}
		{
			UI:Update["obj_Ship", "UpdateModules called while in station", "o"]
			RetryUpdateModuleList:Set[1]
			return
		}

		/* build module lists */
		This.ModuleList:Clear

		if ${List:First(exists)}
			do
			{
				This.ModuleList_${List.Value}:Clear
			}
			while ${List:Next(exists)}		

		Me.Ship:GetModules[ModuleList]

		if !${ModuleList.Used} && ${Me.Ship.HighSlots} > 0
		{
			UI:Update["obj_Ship", "UpdateModuleList - No modules found. Retrying in a few seconds", "o"]
			UI:Update["obj_Ship", "If this ship has slots, you must have at least one module equipped, of any type.", "o"]
			RetryUpdateModuleList:Inc
			if ${RetryUpdateModuleList} >= 10
			{
				return TRUE
			}
			return FALSE
		}
		RetryUpdateModuleList:Set[0]
		
		variable iterator ModuleIter
		
		ModuleList:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			if !${ModuleIter.Value(exists)}
			{
				UI:Update["obj_Ship", "UpdateModuleList - Null module found. Retrying in a few seconds.", "o"]
				RetryUpdateModuleList:Inc
				return FALSE
			}
			if ${List:First(exists)}
			{
				do
				{
					if ${LavishScript.QueryEvaluate[${This.ModuleQueries.Element[${List.Key}]}, ModuleIter.Value]}
					{
						ModuleList_${List.Value}:Insert[${ModuleIter.Value.ID}]
					}
				}
				while ${List:Next(exists)}
			}
		}
		while ${ModuleIter:Next(exists)}

		UI:Update["obj_Ship", "Ship Module Inventory", "y"]
		
		if ${List:First(exists)}
			do
			{
				This.ModuleList_${List.Value}:GetIterator[ModuleIter]
				if ${ModuleIter:First(exists)}
				{
					UI:Update["obj_Ship", "${List.Value}:", "g"]
					do
					{
						UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot} ${ModuleIter.Value.ToItem.Name}", "-g"]
					}
					while ${ModuleIter:Next(exists)}
				}
			}
			while ${List:Next(exists)}

		if ${This.ModuleList_AB_MWD.Used} > 1
		{
			UI:Update["obj_Ship", "Warning: More than 1 Afterburner or MWD was detected, I will only use the first one.", "o"]
		}
		This:QueueState["WaitForStation"]
		This:QueueState["WaitForSpace"]
		This:QueueState["UpdateModules"]
	}
	
	member:bool WaitForStation()
	{
		if ${Me.InStation}
		{
			return TRUE
		}
		return FALSE
	}
	
}
