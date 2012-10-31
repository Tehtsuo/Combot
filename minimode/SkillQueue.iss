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

	member:settingsetref Skills()
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
		This:LoadSkills
		This.PulseFrequency:Set[2000]
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
	
	method LoadSkills()
	{
		variable iterator Skills
		Config.Skills:GetSettingIterator[Skills]
		SkillIndex:Clear
		
		if ${Skills:First(exists)}
		do
		{
			SkillIndex:Insert[${Skills.Value}]
		}
		while ${Skills:Next(exists)}
	}
	method SaveSkills()
	{
		variable iterator Skills
		variable int Count=0
		SkillIndex:GetIterator[Skills]
		Config.Skills:Clear
		
		if ${Skills:First(exists)}
		do
		{
			Config.Skills:AddSetting[${Count},${Skills.Value}]
			Count:Inc
		}
		while ${Skills:Next(exists)}
	}
	
	method UpdateUI()
	{
		variable iterator Skills
		SkillIndex:GetIterator[Skills]
		UIElement[SkillQueue@ComBot_SkillQueue_Frame@ComBot_SkillQueue]:ClearItems
		if ${Skills:First(exists)}
		do
		{
			UIElement[SkillQueue@ComBot_SkillQueue_Frame@ComBot_SkillQueue]:AddItem[${Skills.Value}]
		}
		while ${Skills:Next(exists)}
	}
	
	method UpdateIndex()
	{
		variable int Count
		SkillIndex:Clear
		
		for (Count:Set[0] ; ${Count}<${UIElement[SkillQueue@ComBot_SkillQueue_Frame@ComBot_SkillQueue].Items:Dec} ; Count:Inc)
		{
			SkillIndex:Insert[${UIElement[SkillQueue@ComBot_SkillQueue_Frame@ComBot_SkillQueue].OrderedItem[${Count}].Text}]
		}
	
		This:SaveSkills
	}
	
	method Add(string Skill)
	{
		SkillIndex:Insert[${Skill}]
		This:UpdateUI
		This:SaveSkills
	}
	method Remove(int Skill)
	{
		SkillIndex:Remove[${Skill:Inc}]
		echo Removed #${Skill}
		SkillIndex:Collapse
		This:UpdateUI
		This:SaveSkills
	}
	
	member:bool SkillQueue()
	{
		variable int Count=1
		variable iterator Skill
	
		if ${Me.SkillQueueLength} > 864000000000
		{
			return FALSE
		}
		
		SkillIndex:GetIterator[Skill]
		
		if ${Skill:First(exists)}
		do
		{
			if !${Me.Skill[${Skill.Value}](exists)}
			{
				Cargo:PopulateCargoList[Ship]
				Cargo:Filter[Name == "${Skill.Value}"]
				if ${Cargo.CargoList.Used} > 0
				{
					UI:Update["SkillQueue", "Injecting ${Skill.Value} - skill will queue after 1 minute", "o"]
					Cargo.CargoList.Get[1]:InjectSkill
					return FALSE
				}
				Cargo:PopulateCargoList[Personal Hangar]
				Cargo:Filter[Name == "${Skill.Value}"]
				if ${Cargo.CargoList.Used} > 0
				{
					UI:Update["SkillQueue", "Injecting ${Skill.Value} - skill will queue after 1 minute", "o"]
					Cargo.CargoList.Get[1]:InjectSkill
					return FALSE
				}
			}

			if ${Me.Skill[${Skill.Value}].Level} == 5
			{
				UI:Update["SkillQueue", "Removing ${Skill.Value} from the queue, already at level 5", "o"]
				SkillIndex:RemoveByQuery[${LavishScript.CreateQuery[unistring = "${Skill.Value}"]}]
				SkillIndex:Collapse
				This:SaveSkills
				This:UpdateUI
				return FALSE
			}
			if ${Me.Skill[${Skill.Value}](exists)}
			{
				UI:Update["SkillQueue", "Adding ${Skill.Value} to the queue", "g"]
				Me.Skill[${Skill.Value}]:AddToQueue[${Math.Calc[${Skill[${Skill.Value}].Level}+1]}]
				SkillIndex:Remove[${Count}]
				SkillIndex:Collapse
				This:SaveSkills
				This:UpdateUI
				return FALSE
			}

			Count:Inc
		}
		while ${Skill:Next(exists)}
		
		
		return FALSE
	}

}