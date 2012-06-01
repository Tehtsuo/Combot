
objectdef obj_Configuration_BaseConfig
{
	variable filepath CONFIG_PATH = "${Script.CurrentDirectory}/Config"
	variable string ORG_CONFIG_FILE = "combot.xml"
	variable string NEW_CONFIG_FILE = "${Me.Name} Config.xml"
	variable string CONFIG_FILE = "${Me.Name} Config.xml"
	variable settingsetref BaseRef

	method Initialize()
	{
		LavishSettings[ComBotSettings]:Clear
		LavishSettings:AddSet[ComBotSettings]
		LavishSettings[ComBotSettings]:AddSet[${Me.Name}]

		CONFIG_FILE:Set["${CONFIG_PATH}/${NEW_CONFIG_FILE}"]

		if !${CONFIG_PATH.FileExists[${NEW_CONFIG_FILE}]}
		{
			UI:Update["obj_Configuration", "${CONFIG_FILE} not found - looking for ${ORG_CONFIG_FILE}", "o"]
			UI:Update["obj_Configuration", "Configuration will be copied from ${ORG_CONFIG_FILE} to ${NEW_CONFIG_FILE}", "o"]

			LavishSettings[EVEBotSettings]:Import[${CONFIG_PATH}/${ORG_CONFIG_FILE}]
		}
		else
		{
			UI:Update["obj_Configuration", "Configuration file is ${CONFIG_FILE}", "g"]
			LavishSettings[EVEBotSettings]:Import[${CONFIG_FILE}]
		}

		BaseRef:Set[${LavishSettings[ComBotSettings].FindSet[${Me.Name}]}]
		UI:Update["obj_Configuration", "Initialized - beginning settings Initialization", "g"]
	}

	method Shutdown()
	{
		This:Save[]
		LavishSettings[EVEBotSettings]:Clear
	}

	method Save()
	{
		LavishSettings[EVEBotSettings]:Export[${CONFIG_FILE}]
	}
}




objectdef obj_Configuration
{
	variable obj_Configuration_Common Common
	
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

