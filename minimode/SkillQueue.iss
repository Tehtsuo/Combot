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

objectdef obj_Configuration_SkillQueue
{
	variable string SetName = "SkillQueue"

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

		This.CommonRef:AddSet[Skills]
	}

	member:settingsetref Skills
	{
		return ${This.CommonRef.FindSet[Skills]}
	}
	
}



objectdef obj_SkillQueue inherits obj_State
{
	variable obj_Configuration_SkillQueue Config
	variable index:string SkillIndex
	
	method Initialize()
	{
		This[parent]:Initialize
		This:PopulateIndex
		This.NonGameTiedPulse:Set[TRUE]
		DynamicAddMiniMode("SkillQueue", "SkillQueue")
	}
	
	method Start()
	{
		This:QueueState["SkillQueue"]
	}
	
	method Stop()
	{
		This:Clear
	}
	
	method PopulateIndex()
	{
		variable iterator Skills
		Config.Skills:GetSettingIterator[Skills]
		SkillIndex:Clear
		
		if ${Skills:First(exists)}
		do
		{
			SkillIndex:Insert[${Skills.Value}]
			UIElement[SkillQueue@ComBot_SkillQueue_Frame@ComBot_SkillQueue]:AddItem[${Skills.Value}]
		}
		while ${Skills:Next(exists)}
	}
	
	member:bool SkillQueue()
	{

		
		return FALSE
	}

}