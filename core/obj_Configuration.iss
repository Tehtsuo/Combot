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


objectdef obj_Base_Configuration
{
	variable string SetName = ""

	method Initialize(string name)
	{
		SetName:Set[${name}]
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["Configuration", " ${This.SetName} settings missing - initializing", "o"]
			BaseConfig.BaseRef:AddSet[${This.SetName}]
			This:Set_Default_Values[]
		}
		UI:Update["Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}
	
	method Set_Default_Values()
	{
		
	}

}


objectdef obj_Configuration_BaseConfig
{
	variable string CONFIG_FILE = "${Me.Name} Config.xml"
	variable filepath CONFIG_PATH = "${Script.CurrentDirectory}/config"
	variable settingsetref BaseRef

	method Initialize()
	{
		if ${EVEExtension.Character.Length}
		{
			CONFIG_FILE:Set["${EVEExtension.Character} Config.xml"]
		}

		LavishSettings[ComBotSettings]:Clear
		LavishSettings:AddSet[ComBotSettings]
		if ${EVEExtension.Character.Length}
		{
			LavishSettings[ComBotSettings]:AddSet[${EVEExtension.Character}]
		}
		else
		{
			LavishSettings[ComBotSettings]:AddSet[${Me.Name}]
		}
		


		if !${CONFIG_PATH.FileExists["${CONFIG_PATH}/${CONFIG_FILE}"]}
		{
			UI:Update["Configuration", "Configuration file is ${CONFIG_FILE}", "g", TRUE]
			LavishSettings[ComBotSettings]:Import["${CONFIG_PATH}/${CONFIG_FILE}"]
		}

		if ${EVEExtension.Character.Length}
		{
			BaseRef:Set[${LavishSettings[ComBotSettings].FindSet[${EVEExtension.Character}]}]
		}
		else
		{
			BaseRef:Set[${LavishSettings[ComBotSettings].FindSet[${Me.Name}]}]
		}
		
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
	variable obj_Configuration_Fleets Fleets
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
			UI:Update["Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["Configuration", " ${This.SetName}: Initialized", "-g"]
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
		This.CommonRef:AddSetting[Account,""]
		This.CommonRef:AddSetting[Password,""]
		This.CommonRef:AddSetting[LogUser,""]
	}

	Setting(string, ComBot_Mode, SetComBot_Mode)
	Setting(bool, AutoStart, SetAutoStart)
	Setting(bool, Propulsion, SetPropulsion)
	Setting(int, Propulsion_Threshold, SetPropulsion_Threshold)
	Setting(bool, Undock, SetUndock)
	Setting(bool, Disable3D, SetDisable3D)
	Setting(bool, DisableUI, SetDisableUI)
	Setting(bool, DisableTexture, SetDisableTexture)
	Setting(bool, CloseChatInvites, SetCloseChatInvites)
	Setting(string, ActiveTab, SetActiveTab)
	Setting(bool, Hidden, SetHidden)
	Setting(int64, CharID, SetCharID)
	Setting(string, Account, SetAccount)
	Setting(string, Password, SetPassword)
	Setting(bool, Verbose, SetVerbose)
	Setting(string, LogUser, SetLogUser)
}


	


objectdef obj_Configuration_Fleets
{
	variable string SetName = "Fleets"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}
	
	member:obj_Configuration_Fleet GetFleet(string FleetID)
	{
		if !${This.CommonRef.FindSet[Fleets](exists)}
		{
			This.CommonRef:AddSet[Fleets]
		}
		if !${This.CommonRef.FindSet[Fleets].FindSet[${FleetID}](exists)}
		{
			This.CommonRef.FindSet[Fleets]:AddSet[${FleetID}]
			Config:Save
		}
		return ${This.CommonRef.FindSet[Fleets].FindSet[${FleetID}]}
	}
	
	method ClearFleet(string FleetID)
	{
		if ${This.CommonRef.FindSet[Fleets].FindSet[${FleetID}](exists)}
		{
			This.CommonRef.FindSet[Fleets]:Clear
			Config:Save
		}
	}
	
	member:settingsetref Fleets()
	{
		return ${This.CommonRef.FindSet[Fleets]}
	}
	
	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.CommonRef:AddSet[Fleets]
		This.CommonRef:AddSetting[Active,"No Fleet"]
		Config:Save
	}
	
	Setting(string, Active, SetActive)
}

objectdef obj_Configuration_Fleet
{
	variable settingsetref CurrentRef

	method Initialize(settingsetref BaseRef)
	{
		CurrentRef:Set[${BaseRef}]
		if !${CurrentRef.FindSet[Wings](exists)}
		{
			This:Set_Default_Values[]
		}
	}
	
	member:obj_Configuration_Wing GetWing(int64 WingID)
	{
		if !${CurrentRef.FindSet[Wings].FindSet[${WingID}](exists)}
		{
			CurrentRef.FindSet[Wings]:AddSet[${WingID}]
			Config:Save
		}
		return ${CurrentRef.FindSet[Wings].FindSet[${WingID}]}
	}
	
	member:settingsetref Wings()
	{
		return ${CurrentRef.FindSet[Wings]}
	}

	member:settingsetref CommonRef()
	{
		return ${CurrentRef}
	}

	method Set_Default_Values()
	{
		CurrentRef:AddSet[Wings]
		This.CommonRef:AddSetting[Commander,0]
		This.CommonRef:AddSetting[Booster,0]
		
		Config:Save
	}
	
	Setting(int64, Commander, SetCommander)	
	Setting(int64, Booster, SetBooster)
}

objectdef obj_Configuration_Wing
{
	variable settingsetref CurrentRef

	method Initialize(settingsetref BaseRef)
	{
		CurrentRef:Set[${BaseRef}]
		if !${CurrentRef.FindSet[Squads](exists)}
		{
			This:Set_Default_Values[]
		}
	}
	
	member:obj_Configuration_Squad GetSquad(int64 SquadID)
	{
		if !${CurrentRef.FindSet[Squads].FindSet[${SquadID}](exists)}
		{
			CurrentRef.FindSet[Squads]:AddSet[${SquadID}]
			Config:Save
		}
		return ${CurrentRef.FindSet[Squads].FindSet[${SquadID}]}
	}
	
	member:settingsetref Squads()
	{
		return ${CurrentRef.FindSet[Squads]}
	}

	member:settingsetref CommonRef()
	{
		return ${CurrentRef}
	}
	
	method Set_Default_Values()
	{
		CurrentRef:AddSet[Squads]
		This.CommonRef:AddSetting[Commander,0]
		This.CommonRef:AddSetting[Booster,0]
		Config:Save
	}
	
	Setting(int64, Commander, SetCommander)	
	Setting(int64, Booster, SetBooster)	
}

objectdef obj_Configuration_Squad
{
	variable settingsetref CurrentRef

	method Initialize(settingsetref BaseRef)
	{
		CurrentRef:Set[${BaseRef}]
		if !${CurrentRef.FindSet[Members](exists)}
		{
			This:Set_Default_Values[]
		}
	}
	
	member:obj_Configuration_Member GetMember(int64 MemberID)
	{
		if !${CurrentRef.FindSet[Members].FindSet[${MemberID}](exists)}
		{
			CurrentRef.FindSet[Members]:AddSet[${MemberID}]
			Config:Save
		}
		return ${CurrentRef.FindSet[Members].FindSet[${MemberID}]}
	}
	
	member:settingsetref Members()
	{
		return ${CurrentRef.FindSet[Members]}
	}

	member:settingsetref CommonRef()
	{
		return ${CurrentRef}
	}
	
	method Set_Default_Values()
	{
		CurrentRef:AddSet[Members]
		This.CommonRef:AddSetting[Commander,0]
		This.CommonRef:AddSetting[Booster,0]
		Config:Save
	}
	
	Setting(int64, Commander, SetCommander)	
	Setting(int64, Booster, SetBooster)	
}

objectdef obj_Configuration_Member
{
	variable settingsetref CurrentRef

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
		Config:Save
	}
	
	Setting(bool, Created, SetCreated)	
}

objectdef obj_Configuration_RefineData
{
	variable string SetName = "Refine Amounts"

	variable filepath CONFIG_PATH = "${Script.CurrentDirectory}/data"
	variable string CONFIG_FILE = "RefineAmounts.xml"
	variable settingsetref BaseRef

	method Initialize()
	{
		UI:Update["Configuration", " ${This.SetName}: Load on demand", "-g"]
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

		UI:Update["Configuration", " ${This.SetName}: Initialized", "-g"]
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




