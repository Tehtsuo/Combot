/*

ComBot  Copyright ? 2012  Tehtsuo and Vendan

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

objectdef obj_Configuration_Dynamic
{
	variable string SetName = "Dynamic"

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
		This.CommonRef:AddSet[Enabled MiniModes]
	}
	
	method AddMiniMode(string name)
	{
		if !${This.CommonRef.FindSet[Enabled MiniModes](exists)}
		{
			This.CommonRef:AddSet[Enabled MiniModes]
		}
		This.CommonRef.FindSet[Enabled MiniModes]:AddSetting[${name.Escape}, 1]
		Config:Save
	}
	
	method RemMiniMode(string name)
	{
		if !${This.CommonRef.FindSet[Enabled MiniModes](exists)}
		{
			This.CommonRef:AddSet[Enabled MiniModes]
		}
		if ${This.CommonRef.FindSet[Enabled MiniModes].FindSetting[${name.Escape}](exists)}
		{
			This.CommonRef.FindSet[Enabled MiniModes].FindSetting[${name.Escape}]:Remove
		}
		Config:Save
	}
	
	member:settingsetref EnabledMiniModes()
	{
		if !${This.CommonRef.FindSet[Enabled MiniModes](exists)}
		{
			This.CommonRef:AddSet[Enabled MiniModes]
		}
		return ${This.CommonRef.FindSet[Enabled MiniModes]}
	}
}

objectdef obj_DynamicItem
{
	variable string Name
	variable string DisplayName
	variable bool ThirdParty
	method Initialize(string argName, string argDisplayName, bool argThirdParty)
	{
		Name:Set[${argName.Escape}]
		DisplayName:Set[${argDisplayName.Escape}]
		ThirdParty:Set[${argThirdParty}]
	}
}

objectdef obj_Dynamic
{
	variable collection:obj_DynamicItem Behaviors
	variable collection:obj_DynamicItem MiniModes
	variable obj_Configuration_Dynamic Config
	
	method AddBehavior(string argName, string argDisplayName, bool argThirdParty = TRUE)
	{
		Behaviors:Set[${argName.Escape}, ${argName.Escape}, ${argDisplayName.Escape}, ${argThirdParty}] 
	}
	
	method AddMiniMode(string argName, string argDisplayName, bool argThirdParty = TRUE)
	{
		MiniModes:Set[${argName.Escape}, ${argName.Escape}, ${argDisplayName.Escape}, ${argThirdParty}]
	}
	
	method PopulateMiniModes()
	{
		variable iterator MiniModeIterator
		MiniModes:GetIterator[MiniModeIterator]
		
		UIElement[MiniMode_Inactive@MiniMode@ComBotTab@ComBot]:ClearItems
		UIElement[MiniMode_Active@MiniMode@ComBotTab@ComBot]:ClearItems
		
		if ${MiniModeIterator:First(exists)}
		{
			do
			{
				if ${This.Config.EnabledMiniModes.FindSetting[${MiniModeIterator.Value.Name}](exists)}
				{
					UIElement[MiniMode_Active@MiniMode@ComBotTab@ComBot]:AddItem[${MiniModeIterator.Value.DisplayName.Escape}, ${MiniModeIterator.Value.Name.Escape}]
				}
				else
				{
					UIElement[MiniMode_Inactive@MiniMode@ComBotTab@ComBot]:AddItem[${MiniModeIterator.Value.DisplayName.Escape}, ${MiniModeIterator.Value.Name.Escape}]
				}
			}
			while ${MiniModeIterator:Next(exists)}
		}
	}
	
	method ActivateMiniMode(string name)
	{
		This.Config:AddMiniMode[${name.Escape}]
		${name}:Start
	}
	
	method DeactivateMiniMode(string name)
	{
		This.Config:RemMiniMode[${name.Escape}]
		${name}:Stop
	}
}