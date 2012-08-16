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
	Setting(bool, Disable3D, SetDisable3D)
	Setting(bool, DisableUI, SetDisableUI)
	Setting(bool, DisableTexture, SetDisableTexture)
	Setting(string, ActiveTab, SetActiveTab)
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
		This.CommonRef:AddSetting[Dropoff,""]
		This.CommonRef:AddSetting[Pickup,""]
		
	}
	
	Setting(string, MiningSystem, SetMiningSystem)	
	Setting(string, Pickup_SubType, SetPickup_SubType)
	Setting(string, Dropoff, SetDropoff)
	Setting(string, Pickup, SetPickup)
	Setting(string, Dropoff_Type, SetDropoff_Type)
	Setting(string, Pickup_Type, SetPickup_Type)
	Setting(string, Dropoff_ContainerName, SetDropoff_ContainerName)
	Setting(string, Pickup_ContainerName, SetPickup_ContainerName)
	Setting(int, Threshold, SetThreshold)	
	
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
		
		This.CommonRef:AddSetting[FleeTo,""]
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
	Setting(string, FleeTo, SetFleeTo)	
	Setting(bool, TargetFlee, SetTargetFlee)	
	Setting(bool, CorpFlee, SetCorpFlee)
	Setting(bool, AllianceFlee, SetAllianceFlee)
	Setting(bool, FleetFlee, SetFleetFlee)
	
}	
	





objectdef obj_Configuration_Fleet
{
	variable string SetName = "Fleet"

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
	
	member:obj_Configuration_Wing GetWing(int WingID)
	{
		return ${This.CommonRef.FindSet[DefaultFleet].FindSet[Wings].FindSet[${WingID}]}
	}
	
	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.CommonRef:AddSet[DefaultFleet]
		This.CommonRef.FindSet[DefaultFleet]:AddSet[Wings]
	}
}

objectdef obj_Configuration_Wing
{
	variable settingsefref CurrentRef

	method Initialize(settingsetref BaseRef)
	{
		CurrentRef:Set[${BaseRef}]
		if !${CurrentRef.FindSet[Squads](exists)}
		{
			This:Set_Default_Values[]
		}
	}
	
	member:obj_Configuration_Squad GetSquad(int SquadID)
	{
		return ${CurrentRef.FindSet[Squads].FindSet[${SquadID}]}
	}
	
	method Set_Default_Values()
	{
		CurrentRef:AddSet[Squads]
	}
}

objectdef obj_Configuration_Squad
{
	variable settingsefref CurrentRef

	method Initialize(settingsetref BaseRef)
	{
		CurrentRef:Set[${BaseRef}]
		if !${CurrentRef.FindSet[Members](exists)}
		{
			This:Set_Default_Values[]
		}
	}
	
	member:obj_Configuration_Member GetMember(int MemberID)
	{
		return ${CurrentRef.FindSet[Members].FindSet[${MemberID}]}
	}
	
	method Set_Default_Values()
	{
		CurrentRef:AddSet[Members]
	}
}

objectdef obj_Configuration_Member
{
	variable settingsefref CurrentRef

	method Initialize(settingsetref BaseRef)
	{
		CurrentRef:Set[${BaseRef}]
		if !${CurrentRef.FindSetting[Created](exists)}
		{
			This:Set_Default_Values[]
		}
	}
	
	method Set_Default_Values()
	{
		CurrentRef:AddSetting[Created, TRUE]
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




