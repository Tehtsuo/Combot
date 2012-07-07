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

#macro Setting(type, name, setname)
	member:type name()
	{
		return ${This.CommonRef.FindSetting[name]}
	}

	method setname(type value)
	{
		This.CommonRef:AddSetting[name,${value}]
		Config:Save
	}
#endmac

objectdef obj_Configuration_BaseConfig
{
	variable filepath CONFIG_PATH = "${Script.CurrentDirectory}/config"
	variable string CONFIG_FILE = "${Me.Name} Config.xml"
	variable settingsetref BaseRef

	method Initialize()
	{
		LavishSettings[ComBotSettings]:Clear
		LavishSettings:AddSet[ComBotSettings]
		LavishSettings[ComBotSettings]:AddSet[${Me.Name}]


		if !${CONFIG_PATH.FileExists["${CONFIG_PATH}/${CONFIG_FILE}"]}
		{
			UI:Update["obj_Configuration", "Configuration file is ${CONFIG_FILE}", "g"]
			LavishSettings[ComBotSettings]:Import["${CONFIG_PATH}/${CONFIG_FILE}"]
		}

		BaseRef:Set[${LavishSettings[ComBotSettings].FindSet[${Me.Name}]}]
	}

	method Shutdown()
	{
		This:Save[]
		LavishSettings[ComBotSettings]:Clear
	}

	method Save()
	{
		LavishSettings[ComBotSettings]:Export["${CONFIG_PATH}/${CONFIG_FILE}"]
	}
}




objectdef obj_Configuration
{
	variable obj_Configuration_Common Common
	variable obj_Configuration_Salvager Salvager
	variable obj_Configuration_Miner Miner
	variable obj_Configuration_Security Security
	variable obj_Configuration_HangarSale HangarSale
	variable obj_Configuration_Hauler Hauler
	variable obj_Configuration_Fleet Fleet
	method Save()
	{
		BaseConfig:Save[]
	}
}






objectdef obj_Configuration_Common
{
	variable string SetName = "Common"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["obj_Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["obj_Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.CommonRef:AddSetting[ComBot_Mode,Salvager]
		This.CommonRef:AddSetting[AlwaysShieldBoost, FALSE]
		This.CommonRef:AddSetting[ActiveTab,Status]
	}

	Setting(string, ComBot_Mode, SetComBot_Mode)
	Setting(bool, AutoStart, SetAutoStart)
	Setting(bool, WarpPulse, SetWarpPulse)
	Setting(bool, Propulsion, SetPropulsion)
	Setting(int, Propulsion_Threshold, SetPropulsion_Threshold)
	Setting(bool, AlwaysShieldBoost, SetAlwaysShieldBoost)
	Setting(string, ActiveTab, SetActiveTab)
}

objectdef obj_Configuration_Salvager
{
	variable string SetName = "Salvager"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["obj_Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["obj_Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.CommonRef:AddSetting[Salvager_Dropoff_Type,Personal Hangar]
		This.CommonRef:AddSetting[Salvager_Prefix,Salvage:]
	}

	Setting(string, Salvager_Prefix, SetSalvager_Prefix)
	Setting(string, Salvager_Dropoff, SetSalvager_Dropoff)
	Setting(string, Salvager_Dropoff_Type, SetSalvager_DropoffType)
	Setting(bool, BeltPatrol, SetBeltPatrol)
	Setting(string, BeltPatrolBookmark, SetBeltPatrolBookmark)
}

objectdef obj_Configuration_HangarSale
{
	variable string SetName = "HangarSale"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["obj_Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["obj_Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.CommonRef:AddSetting[PriceMode,Undercut Lowest]
		This.CommonRef:AddSetting[UndercutPercent,1]
		This.CommonRef:AddSetting[UndercutValue,1000]
	}
	
	Setting(string, PriceMode, SetPriceMode)
	Setting(int, UndercutPercent, SetUndercutPercent)
	Setting(int, UndercutValue, SetUndercutValue)
	Setting(bool, RePrice, SetRePrice)
	Setting(bool, Sell, SetSell)
	Setting(bool, MoveRefines, SetMoveRefines)
	Setting(int64, MoveRefinesTarget, SetMoveRefinesTarget)
}
	
objectdef obj_Configuration_Hauler
{
	variable string SetName = "Hauler"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["obj_Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["obj_Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.CommonRef:AddSetting[Dropoff_ContainerName,""]
		This.CommonRef:AddSetting[Pickup_ContainerName,""]
		
	}
	
	Setting(string, MiningSystem, SetMiningSystem)	
	Setting(string, JetCanMode, SetJetCanMode)
	Setting(string, Dropoff_Bookmark, SetDropoff_Bookmark)
	Setting(string, Pickup_Bookmark, SetPickup_Bookmark)
	Setting(string, Dropoff_Type, SetDropoff_Type)
	Setting(string, Pickup_Type, SetPickup_Type)
	Setting(string, Dropoff_ContainerName, SetDropoff_ContainerName)
	Setting(string, Pickup_ContainerName, SetPickup_ContainerName)
	Setting(int, Threshold, SetThreshold)	
	
}

objectdef obj_Configuration_Miner
{
	variable string SetName = "Miner"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["obj_Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["obj_Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	member:settingsetref OreTypesRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Ore_Types]}
	}

	member:settingsetref IceTypesRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Ice_Types]}
	}

	
	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.CommonRef:AddSet[ORE_Types]
		This.OreTypesRef:AddSetting[Vitreous Mercoxit, 1]
		This.OreTypesRef:AddSetting[Magma Mercoxit, 1]
		This.OreTypesRef:AddSetting[Mercoxit, 1]
		This.OreTypesRef:AddSetting[Prime Arkonor, 1]
		This.OreTypesRef:AddSetting[Crimson Arkonor, 1]
		This.OreTypesRef:AddSetting[Arkonor, 1]
		This.OreTypesRef:AddSetting[Monoclinic Bistot, 1]
		This.OreTypesRef:AddSetting[Triclinic Bistot, 1]
		This.OreTypesRef:AddSetting[Bistot, 1]
		This.OreTypesRef:AddSetting[Crystalline Crokite, 1]
		This.OreTypesRef:AddSetting[Sharp Crokite, 1]
		This.OreTypesRef:AddSetting[Crokite, 1]
		This.OreTypesRef:AddSetting[Gleaming Spodumain, 1]
		This.OreTypesRef:AddSetting[Bright Spodumain, 1]
		This.OreTypesRef:AddSetting[Spodumain, 1]
		This.OreTypesRef:AddSetting[Obsidian Ochre, 1]
		This.OreTypesRef:AddSetting[Onyx Ochre, 1]
		This.OreTypesRef:AddSetting[Dark Ochre, 1]
		This.OreTypesRef:AddSetting[Prismatic Gneiss, 1]
		This.OreTypesRef:AddSetting[Iridescent Gneiss, 1]
		This.OreTypesRef:AddSetting[Gneiss, 1]
		This.OreTypesRef:AddSetting[Glazed Hedbergite, 1]
		This.OreTypesRef:AddSetting[Vitric Hedbergite, 1]
		This.OreTypesRef:AddSetting[Hedbergite, 1]
		This.OreTypesRef:AddSetting[Radiant Hemorphite, 1]
		This.OreTypesRef:AddSetting[Vivid Hemorphite, 1]
		This.OreTypesRef:AddSetting[Hemorphite, 1]
		This.OreTypesRef:AddSetting[Pristine Jaspet, 1]
		This.OreTypesRef:AddSetting[Pure Jaspet, 1]
		This.OreTypesRef:AddSetting[Jaspet, 1]
		This.OreTypesRef:AddSetting[Fiery Kernite, 1]
		This.OreTypesRef:AddSetting[Luminous Kernite, 1]
		This.OreTypesRef:AddSetting[Kernite, 1]
		This.OreTypesRef:AddSetting[Golden Omber, 1]
		This.OreTypesRef:AddSetting[Silvery Omber, 1]
		This.OreTypesRef:AddSetting[Omber, 1]
		This.OreTypesRef:AddSetting[Rich Plagioclase, 1]
		This.OreTypesRef:AddSetting[Azure Plagioclase, 1]
		This.OreTypesRef:AddSetting[Plagioclase, 1]
		This.OreTypesRef:AddSetting[Viscous Pyroxeres, 1]
		This.OreTypesRef:AddSetting[Solid Pyroxeres, 1]
		This.OreTypesRef:AddSetting[Pyroxeres, 1]
		This.OreTypesRef:AddSetting[Massive Scordite, 1]
		This.OreTypesRef:AddSetting[Condensed Scordite, 1]
		This.OreTypesRef:AddSetting[Scordite, 1]
		This.OreTypesRef:AddSetting[Dense Veldspar, 1]
		This.OreTypesRef:AddSetting[Concentrated Veldspar, 1]
		This.OreTypesRef:AddSetting[Veldspar, 1]

		This.CommonRef:AddSet[ICE_Types]
		This.IceTypesRef:AddSetting[Dark Glitter, 1]
		This.IceTypesRef:AddSetting[Gelidus, 1]
		This.IceTypesRef:AddSetting[Glare Crust, 1]
		This.IceTypesRef:AddSetting[Krystallos, 1]
		This.IceTypesRef:AddSetting[Clear Icicle, 1]
		This.IceTypesRef:AddSetting[Smooth Glacial Mass, 1]
		This.IceTypesRef:AddSetting[Glacial Mass, 1]
		This.IceTypesRef:AddSetting[Pristine White Glaze, 1]
		This.IceTypesRef:AddSetting[White Glaze, 1]
		This.IceTypesRef:AddSetting[Thick Blue Ice, 1]
		This.IceTypesRef:AddSetting[Enriched Clear Icicle, 1]
		This.IceTypesRef:AddSetting[Blue Ice, 1]
		
		This.CommonRef:AddSetting[Miner_Dropoff_Type,Personal Hangar]
		This.CommonRef:AddSetting[BeltPrefix,Belt:]
		This.CommonRef:AddSetting[IceBeltPrefix,Ice Belt:]
		This.CommonRef:AddSetting[MaxLasers,3]
		
	}
	
	Setting(string, MiningSystem, SetMiningSystem)	
	Setting(string, Dropoff, SetDropoff)	
	Setting(string, Dropoff_Type, SetDropoff_Type)	
	Setting(string, Dropoff_Type, SetDropoff_Type)	
	Setting(string, Container_Name, SetContainer_Name)	
	Setting(bool, IceMining, SetIceMining)	
	Setting(bool, OrcaMode, SetOrcaMode)	
	Setting(bool, UseBookmarks, SetUseBookmarks)	
	Setting(string, BeltPrefix, SetBeltPrefix)	
	Setting(string, IceBeltPrefix, SetIceBeltPrefix)	
	Setting(int, Threshold, SetThreshold)	
	Setting(int, MaxLaserLocks, SetMaxLaserLocks)	

}
	
objectdef obj_Configuration_Security
{
	variable string SetName = "Security"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["obj_Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["obj_Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		
	}

	Setting(bool, MeToPilot, SetMeToPilot)	
	Setting(bool, MeToCorp, SetMeToCorp)	
	Setting(bool, MeToAlliance, SetMeToAlliance)	
	Setting(bool, CorpToPilot, SetCorpToPilot)	
	Setting(bool, CorpToCorp, SetCorpToCorp)	
	Setting(bool, CorpToAlliance, SetCorpToAlliance)	
	Setting(bool, AllianceToPilot, SetAllianceToPilot)	
	Setting(bool, AllianceToCorp, SetAllianceToCorp)	
	Setting(bool, AllianceToAlliance, SetAllianceToAlliance)	
	Setting(int, MeToPilot_Value, SetMeToPilot_Value)	
	Setting(int, MeToCorp_Value, SetMeToCorp_Value)	
	Setting(int, MeToAlliance_Value, SetMeToAlliance_Value)	
	Setting(int, CorpToPilot_Value, SetCorpToPilot_Value)	
	Setting(int, CorpToCorp_Value, SetCorpToCorp_Value)	
	Setting(int, CorpToAlliance_Value, SetCorpToAlliance_Value)	
	Setting(int, AllianceToPilot_Value, SetAllianceToPilot_Value)	
	Setting(int, AllianceToCorp_Value, SetAllianceToCorp_Value)	
	Setting(int, AllianceToAlliance_Value, SetAllianceToAlliance_Value)	
	Setting(bool, FleeWaitTime_Enabled, SetFleeWaitTime_Enabled)	
	Setting(int, FleeWaitTime, SetFleeWaitTime)	
	Setting(bool, Break_Enabled, SetBreak_Enabled)	
	Setting(int, Break_Duration, SetBreak_Duration)	
	Setting(int, Break_Interval, SetBreak_Interval)	
	Setting(bool, OverrideFleeBookmark_Enabled, SetOverrideFleeBookmark_Enabled)	
	Setting(string, OverrideFleeBookmark, SetOverrideFleeBookmark)	
	Setting(bool, TargetFlee, SetTargetFlee)	
	Setting(bool, CorpFlee, SetCorpFlee)
	Setting(bool, AllianceFlee, SetAllianceFlee)
	Setting(bool, FleetFlee, SetFleetFlee)
	
}	
	


objectdef obj_FleetMember
{
	variable string FleetMemberName
	variable bool FleetCommander
	variable int Wing
	variable bool WingCommander
	variable int Squad
	variable bool SquadCommander

	method Initialize(string arg_FleetMemberName, bool arg_FleetCommander, int arg_Wing, bool arg_WingCommander, int arg_Squad, bool arg_SquadCommander)
	{
		FleetMemberName:Set[${arg_FleetMemberName}]
		FleetCommander:Set[${arg_FleetCommander}]
		Wing:Set[${arg_Wing}]
		WingCommander:Set[${arg_WingCommander}]
		Squad:Set[${arg_Squad}]
		SquadCommander:Set[${arg_SquadCommander}]
	}
}


objectdef obj_Configuration_Fleet
{
	variable string SetName = "Fleet"
	variable index:obj_FleetMember FleetMembers

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)} || !${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[FleetMembers](exists)}
		{
			UI:Update["obj_Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["obj_Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref FleetRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}
	member:settingsetref FleetMembersRef()
	{
		return ${This.FleetRef.FindSet[FleetMembers]}
	}
	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.FleetRef:AddSet[FleetMembers]
	}

	member:bool ManageFleet()
	{
		return ${This.FleetRef.FindSetting[Manage Fleet, FALSE]}
	}

	method SetManageFleet(bool value)
	{
		This.FleetRef:AddSetting[Manage Fleet, ${value}]
	}

	member:string FleetLeader()
	{
		return ${This.FleetRef.FindSetting[Fleet Leader, ""]}
	}

	method SetFleetLeader(string value)
	{
		This.FleetRef:AddSetting[Fleet Leader, ${value}]
	}

	
	

}	
	
	
	
	
objectdef obj_Configuration_RefineData
{
	variable string SetName = "Refine Amounts"

	variable filepath CONFIG_PATH = "${Script.CurrentDirectory}/data"
	variable string CONFIG_FILE = "RefineAmounts.xml"
	variable settingsetref BaseRef

	method Initialize()
	{
		UI:Update["obj_Configuration", " ${This.SetName}: Load on demand", "-g"]
	}

	method Shutdown()
	{
		LavishSettings[RefineData]:Clear
	}

	method Load()
	{
		LavishSettings[RefineData]:Clear
		LavishSettings:AddSet[RefineData]
		LavishSettings[RefineData]:AddSet[${Me.Name}]

		if !${CONFIG_PATH.FileExists["${CONFIG_PATH}/${CONFIG_FILE}"]}
		{
			LavishSettings[RefineData]:Import["${CONFIG_PATH}/${CONFIG_FILE}"]
		}
		BaseRef:Set[${LavishSettings[RefineData].FindSet[Refines]}]

		UI:Update["obj_Configuration", " ${This.SetName}: Initialized", "-g"]
	}
	
	member:int Tritanium(int ID)
	{
		return ${This.BaseRef.FindSet["${ID}"].FindSetting["34"]}
	}
	member:int Pyerite(int ID)
	{
		return ${This.BaseRef.FindSet["${ID}"].FindSetting["35"]}
	}
	member:int Mexallon(int ID)
	{
		return ${This.BaseRef.FindSet["${ID}"].FindSetting["36"]}
	}
	member:int Isogen(int ID)
	{
		return ${This.BaseRef.FindSet["${ID}"].FindSetting["37"]}
	}
	member:int Nocxium(int ID)
	{
		return ${This.BaseRef.FindSet["${ID}"].FindSetting["38"]}
	}
	member:int Zydrine(int ID)
	{
		return ${This.BaseRef.FindSet["${ID}"].FindSetting["39"]}
	}
	member:int Megacyte(int ID)
	{
		return ${This.BaseRef.FindSet["${ID}"].FindSetting["40"]}
	}
}




