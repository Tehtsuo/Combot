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

objectdef obj_Configuration_AutoLogout
{
	variable string SetName = "AutoLogout"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["obj_AutoLogout", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["obj_AutoLogout", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.CommonRef:AddSetting[Hour, 20]
		This.CommonRef:AddSetting[Minute, 0]
	}

	Setting(int, Hour, SetHour)
	Setting(int, Minute, SetMinute)
	Setting(string, Bookmark, SetBookmark)
}


objectdef obj_AutoLogout inherits obj_State
{
	variable obj_Configuration_AutoLogout Config
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[500]
		DynamicAddMiniMode("AutoLogout", "AutoLogout")
	}
	
	method Start()
	{
		UI:Update["obj_AutoLogout", "Starting AutoLogout", "g"]
		This:QueueState["AutoLogout"]
	}
	
	method Stop()
	{
		This:Clear
		UI:Update["obj_AutoLogout", "Stopping AutoLogout", "g"]
	}
	
	member:bool AutoLogout()
	{
		if ${Time.Hour} == ${Config.Hour} && ${Time.Minute} == ${Config.Minute}
		{
			This:QueueState["PrepForMove"]
			This:QueueState["MoveToLogout"]
			This:QueueState["Traveling"]
			This:QueueState["Logout"]
			return TRUE
		}
		return FALSE
	}
	
	member:bool PrepForMove()
	{
		variable iterator Behaviors
		UI:Update["obj_AutoLogout", "Logout time!", "r"]
		Dynamic.Behaviors:GetIterator[Behaviors]
		if ${Behaviors:First(exists)}
		{
			do
			{
				${Behaviors.Value.Name}:Clear
			}
			while ${Behaviors:Next(exists)}
		}
		Move:Clear
		Move.Traveling:Set[FALSE]
		return TRUE
	}
	
	member:bool MoveToLogout()
	{
		Move:Bookmark[${Config.Bookmark}]
		return TRUE
	}
	
	member:bool Traveling()
	{
		if ${Move.Traveling} || ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		return TRUE
	}
	
	member:bool Logout()
	{
		EVE:Execute[CmdQuitGame]
		endscript combot
	}
}