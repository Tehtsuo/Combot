
objectdef obj_Configuration_BaseConfig
{
	variable filepath CONFIG_PATH = "${Script.CurrentDirectory}/Config"
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
		UI:Update["obj_Configuration", "Initialized - beginning settings Initialization", "g"]
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
	
	method Save()
	{
		BaseConfig:Save[]
	}
}






objectdef obj_Configuration_Common
{
	variable string SetName = "Common"
	variable int AboutCount = 0

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

}

objectdef obj_Configuration_Salvager
{
	variable string SetName = "Salvager"
	variable int AboutCount = 0

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
