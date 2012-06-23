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
	}

	member:string ComBot_Mode()
	{
		return ${This.CommonRef.FindSetting[ComBot_Mode]}
	}

	method SetComBot_Mode(string value)
	{
		This.CommonRef:AddSetting[ComBot_Mode,${value}]
	}

	member:bool AutoStart()
	{
		return ${This.CommonRef.FindSetting[AutoStart]}
	}

	method SetAutoStart(bool value)
	{
		This.CommonRef:AddSetting[AutoStart,${value}]
	}

	member:bool WarpPulse()
	{
		return ${This.CommonRef.FindSetting[WarpPulse]}
	}

	method SetWarpPulse(bool value)
	{
		This.CommonRef:AddSetting[WarpPulse,${value}]
	}
	
	member:bool Propulsion()
	{
		return ${This.CommonRef.FindSetting[Propulsion]}
	}

	method SetPropulsion(bool value)
	{
		This.CommonRef:AddSetting[Propulsion,${value}]
	}
	
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

	member:string Salvager_Prefix()
	{
		return ${This.CommonRef.FindSetting[Salvager_Prefix]}
	}

	method SetSalvager_Prefix(string value)
	{
		This.CommonRef:AddSetting[Salvager_Prefix,${value}]
	}
	
	member:string Salvager_Dropoff()
	{
		return ${This.CommonRef.FindSetting[Salvager_Dropoff]}
	}

	method SetSalvager_Dropoff(string value)
	{
		This.CommonRef:AddSetting[Salvager_Dropoff,${value}]
	}

	member:string Salvager_Dropoff_Type()
	{
		return ${This.CommonRef.FindSetting[Salvager_Dropoff_Type]}
	}

	method SetSalvager_Dropoff_Type(string value)
	{
		This.CommonRef:AddSetting[Salvager_Dropoff_Type,${value}]
	}
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
	
	
	member:string PriceMode()
	{
		return ${This.CommonRef.FindSetting[PriceMode]}
	}

	method SetPriceMode(string value)
	{
		This.CommonRef:AddSetting[PriceMode,${value}]
	}

	member:int UndercutPercent()
	{
		return ${This.CommonRef.FindSetting[UndercutPercent]}
	}

	method SetUndercutPercent(int value)
	{
		This.CommonRef:AddSetting[UndercutPercent,${value}]
	}

	member:int UndercutValue()
	{
		return ${This.CommonRef.FindSetting[UndercutValue]}
	}

	method SetUndercutValue(int value)
	{
		This.CommonRef:AddSetting[UndercutValue,${value}]
	}

	member:bool RePrice()
	{
		return ${This.CommonRef.FindSetting[RePrice]}
	}

	method SetRePrice(bool value)
	{
		This.CommonRef:AddSetting[RePrice,${value}]
	}
	
	member:bool Sell()
	{
		return ${This.CommonRef.FindSetting[Sell]}
	}

	method SetSell(bool value)
	{
		This.CommonRef:AddSetting[Sell,${value}]
	}
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
	
	
	member:string MiningSystem()
	{
		return ${This.CommonRef.FindSetting[MiningSystem]}
	}

	method SetMiningSystem(string value)
	{
		This.CommonRef:AddSetting[MiningSystem,${value}]
	}

	member:string JetCanMode()
	{
		return ${This.CommonRef.FindSetting[JetCanMode]}
	}

	method SetJetCanMode(string value)
	{
		This.CommonRef:AddSetting[JetCanMode,${value}]
	}

	member:string Dropoff_Bookmark()
	{
		return ${This.CommonRef.FindSetting[Dropoff_Bookmark]}
	}

	method SetDropoff_Bookmark(string value)
	{
		This.CommonRef:AddSetting[Dropoff_Bookmark,${value}]
	}

	member:string Pickup_Bookmark()
	{
		return ${This.CommonRef.FindSetting[Pickup_Bookmark]}
	}

	method SetPickup_Bookmark(string value)
	{
		This.CommonRef:AddSetting[Pickup_Bookmark,${value}]
	}

	member:string Dropoff_Type()
	{
		return ${This.CommonRef.FindSetting[Dropoff_Type]}
	}

	method SetDropoff_Type(string value)
	{
		This.CommonRef:AddSetting[Dropoff_Type,${value}]
	}
	
	member:string Pickup_Type()
	{
		return ${This.CommonRef.FindSetting[Pickup_Type]}
	}

	method SetPickup_Type(string value)
	{
		This.CommonRef:AddSetting[Pickup_Type,${value}]
	}
	
	member:string Dropoff_ContainerName()
	{
		return ${This.CommonRef.FindSetting[Dropoff_ContainerName]}
	}

	method SetDropoff_ContainerName(string value)
	{
		This.CommonRef:AddSetting[Dropoff_ContainerName,${value}]
	}
	
	member:string Pickup_ContainerName()
	{
		return ${This.CommonRef.FindSetting[Pickup_ContainerName]}
	}

	method SetPickup_ContainerName(string value)
	{
		This.CommonRef:AddSetting[Pickup_ContainerName,${value}]
	}

	member:int Threshold()
	{
		return ${This.CommonRef.FindSetting[Threshold]}
	}

	method SetThreshold(int value)
	{
		This.CommonRef:AddSetting[Threshold,${value}]
	}
	
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
		This.CommonRef:AddSetting[Miner_OrcaName,""]
		
	}

	member:string MiningSystem()
	{
		return ${This.CommonRef.FindSetting[MiningSystem]}
	}

	method SetMiningSystem(string value)
	{
		This.CommonRef:AddSetting[MiningSystem,${value}]
	}

	member:string Miner_Dropoff()
	{
		return ${This.CommonRef.FindSetting[Miner_Dropoff]}
	}

	method SetMiner_Dropoff(string value)
	{
		This.CommonRef:AddSetting[Miner_Dropoff,${value}]
	}

	member:string Miner_Dropoff_Type()
	{
		return ${This.CommonRef.FindSetting[Miner_Dropoff_Type]}
	}

	method SetMiner_Dropoff_Type(string value)
	{
		This.CommonRef:AddSetting[Miner_Dropoff_Type,${value}]
	}
	
	member:string Miner_OrcaName()
	{
		return ${This.CommonRef.FindSetting[Miner_OrcaName]}
	}

	method SetMiner_OrcaName(string value)
	{
		This.CommonRef:AddSetting[Miner_OrcaName,${value}]
	}
	
	member:bool IceMining()
	{
		return ${This.CommonRef.FindSetting[IceMining]}
	}

	method SetIceMining(bool value)
	{
		This.CommonRef:AddSetting[IceMining,${value}]
	}
	
	member:bool OrcaMode()
	{
		return ${This.CommonRef.FindSetting[OrcaMode]}
	}

	method SetOrcaMode(bool value)
	{
		This.CommonRef:AddSetting[OrcaMode,${value}]
	}
	
	member:bool UseBookmarks()
	{
		return ${This.CommonRef.FindSetting[UseBookmarks]}
	}

	method SetUseBookmarks(bool value)
	{
		This.CommonRef:AddSetting[UseBookmarks,${value}]
	}

	member:bool AlwaysShieldBoost()
	{
		return ${This.CommonRef.FindSetting[AlwaysShieldBoost]}
	}

	method SetAlwaysShieldBoost(bool value)
	{
		This.CommonRef:AddSetting[AlwaysShieldBoost,${value}]
	}
	
	member:string BeltPrefix()
	{
		return ${This.CommonRef.FindSetting[BeltPrefix]}
	}

	method SetBeltPrefix(string value)
	{
		This.CommonRef:AddSetting[BeltPrefix,${value}]
	}

	member:string IceBeltPrefix()
	{
		return ${This.CommonRef.FindSetting[IceBeltPrefix]}
	}

	method SetIceBeltPrefix(string value)
	{
		This.CommonRef:AddSetting[IceBeltPrefix,${value}]
	}
	
	member:int Threshold()
	{
		return ${This.CommonRef.FindSetting[Threshold]}
	}

	method SetThreshold(int value)
	{
		This.CommonRef:AddSetting[Threshold,${value}]
	}
	
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

	member:bool MeToPilot()
	{
		return ${This.CommonRef.FindSetting[MeToPilot]}
	}

	method SetMeToPilot(bool value)
	{
		This.CommonRef:AddSetting[MeToPilot,${value}]
	}

	member:bool MeToCorp()
	{
		return ${This.CommonRef.FindSetting[MeToCorp]}
	}

	method SetMeToCorp(bool value)
	{
		This.CommonRef:AddSetting[MeToCorp,${value}]
	}

	member:bool MeToAlliance()
	{
		return ${This.CommonRef.FindSetting[MeToAlliance]}
	}

	method SetMeToAlliance(bool value)
	{
		This.CommonRef:AddSetting[MeToAlliance,${value}]
	}

	member:bool CorpToPilot()
	{
		return ${This.CommonRef.FindSetting[CorpToPilot]}
	}

	method SetCorpToPilot(bool value)
	{
		This.CommonRef:AddSetting[CorpToPilot,${value}]
	}

	member:bool CorpToCorp()
	{
		return ${This.CommonRef.FindSetting[CorpToCorp]}
	}

	method SetCorpToCorp(bool value)
	{
		This.CommonRef:AddSetting[CorpToCorp,${value}]
	}

	member:bool CorpToAlliance()
	{
		return ${This.CommonRef.FindSetting[CorpToAlliance]}
	}

	method SetCorpToAlliance(bool value)
	{
		This.CommonRef:AddSetting[CorpToAlliance,${value}]
	}
	
	member:bool AllianceToPilot()
	{
		return ${This.CommonRef.FindSetting[AllianceToPilot]}
	}

	method SetAllianceToPilot(bool value)
	{
		This.CommonRef:AddSetting[AllianceToPilot,${value}]
	}

	member:bool AllianceToCorp()
	{
		return ${This.CommonRef.FindSetting[AllianceToCorp]}
	}

	method SetAllianceToCorp(bool value)
	{
		This.CommonRef:AddSetting[AllianceToCorp,${value}]
	}

	member:bool AllianceToAlliance()
	{
		return ${This.CommonRef.FindSetting[AllianceToAlliance]}
	}

	method SetAllianceToAlliance(bool value)
	{
		This.CommonRef:AddSetting[AllianceToAlliance,${value}]
	}
	
	member:int MeToPilot_Value()
	{
		return ${This.CommonRef.FindSetting[MeToPilot_Value]}
	}

	method SetMeToPilot_Value(int value)
	{
		This.CommonRef:AddSetting[MeToPilot_Value,${value}]
	}
	
	member:int MeToCorp_Value()
	{
		return ${This.CommonRef.FindSetting[MeToCorp_Value]}
	}

	method SetMeToCorp_Value(int value)
	{
		This.CommonRef:AddSetting[MeToCorp_Value,${value}]
	}
	
	member:int MeToAlliance_Value()
	{
		return ${This.CommonRef.FindSetting[MeToAlliance_Value]}
	}

	method SetMeToAlliance_Value(int value)
	{
		This.CommonRef:AddSetting[MeToAlliance_Value,${value}]
	}
	
	member:int CorpToPilot_Value()
	{
		return ${This.CommonRef.FindSetting[CorpToPilot_Value]}
	}

	method SetCorpToPilot_Value(int value)
	{
		This.CommonRef:AddSetting[CorpToPilot_Value,${value}]
	}
	
	member:int CorpToCorp_Value()
	{
		return ${This.CommonRef.FindSetting[CorpToCorp_Value]}
	}

	method SetCorpToCorp_Value(int value)
	{
		This.CommonRef:AddSetting[CorpToCorp_Value,${value}]
	}
	
	member:int CorpToAlliance_Value()
	{
		return ${This.CommonRef.FindSetting[CorpToAlliance_Value]}
	}

	method SetCorpToAlliance_Value(int value)
	{
		This.CommonRef:AddSetting[CorpToAlliance_Value,${value}]
	}
	
	member:int AllianceToPilot_Value()
	{
		return ${This.CommonRef.FindSetting[AllianceToPilot_Value]}
	}

	method SetAllianceToPilot_Value(int value)
	{
		This.CommonRef:AddSetting[AllianceToPilot_Value,${value}]
	}
	
	member:int AllianceToCorp_Value()
	{
		return ${This.CommonRef.FindSetting[AllianceToCorp_Value]}
	}

	method SetAllianceToCorp_Value(int value)
	{
		This.CommonRef:AddSetting[AllianceToCorp_Value,${value}]
	}
	
	member:int AllianceToAlliance_Value()
	{
		return ${This.CommonRef.FindSetting[AllianceToAlliance_Value]}
	}

	method SetAllianceToAlliance_Value(int value)
	{
		This.CommonRef:AddSetting[AllianceToAlliance_Value,${value}]
	}
	
	member:bool FleeWaitTime_Enabled()
	{
		return ${This.CommonRef.FindSetting[FleeWaitTime_Enabled]}
	}

	method SetFleeWaitTime_Enabled(bool value)
	{
		This.CommonRef:AddSetting[FleeWaitTime_Enabled,${value}]
	}

	member:int FleeWaitTime()
	{
		return ${This.CommonRef.FindSetting[FleeWaitTime]}
	}

	method SetFleeWaitTime(int value)
	{
		This.CommonRef:AddSetting[FleeWaitTime,${value}]
	}
	
	member:bool Break_Enabled()
	{
		return ${This.CommonRef.FindSetting[Break_Enabled]}
	}

	method SetBreak_Enabled(bool value)
	{
		This.CommonRef:AddSetting[Break_Enabled,${value}]
	}

	member:int Break_Duration()
	{
		return ${This.CommonRef.FindSetting[Break_Duration]}
	}

	method SetBreak_Duration(int value)
	{
		This.CommonRef:AddSetting[Break_Duration,${value}]
	}
	
	member:int Break_Interval()
	{
		return ${This.CommonRef.FindSetting[Break_Interval]}
	}

	method SetBreak_Interval(int value)
	{
		This.CommonRef:AddSetting[Break_Interval,${value}]
	}
	
	member:bool OverrideFleeBookmark_Enabled()
	{
		return ${This.CommonRef.FindSetting[OverrideFleeBookmark_Enabled]}
	}

	method SetOverrideFleeBookmark_Enabled(bool value)
	{
		This.CommonRef:AddSetting[OverrideFleeBookmark_Enabled,${value}]
	}

	member:string OverrideFleeBookmark()
	{
		return ${This.CommonRef.FindSetting[OverrideFleeBookmark]}
	}

	method SetOverrideFleeBookmark(string value)
	{
		This.CommonRef:AddSetting[OverrideFleeBookmark,${value}]
	}

	member:bool TargetFlee()
	{
		return ${This.CommonRef.FindSetting[TargetFlee]}
	}

	method SetTargetFlee(bool value)
	{
		This.CommonRef:AddSetting[TargetFlee,${value}]
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
