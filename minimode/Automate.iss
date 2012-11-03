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

objectdef obj_Configuration_Automate
{
	variable string SetName = "Automate"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["Automate", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["Automate", " ${This.SetName}: Initialized", "-g"]
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
		This.CommonRef:AddSetting[Bookmark, ""]
		This.CommonRef:AddSetting[LaunchCommand, ""]
	}

	Setting(int, Hour, SetHour)
	Setting(int, Minute, SetMinute)
	Setting(int, StartHour, SetStartHour)
	Setting(int, StartMinute, SetStartMinute)
	Setting(int, StartDelta, SetStartDelta)
	Setting(bool, DelayLogin, SetDelayLogin)
	Setting(bool, DelayLoginDelta, SetDelayLoginDelta)
	Setting(string, Bookmark, SetBookmark)
	Setting(bool, Launch, SetLaunch)
	Setting(string, LaunchCommand, SetLaunchCommand)
}


objectdef obj_Automate inherits obj_State
{
	variable obj_Configuration_Automate Config
	variable obj_AutomateUI LocalUI
	variable bool StartComplete=FALSE
	
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		PulseFrequency:Set[500]
		DynamicAddMiniMode("Automate", "Automate")
	}
	
	method Start()
	{
		UI:Update["Automate", "Starting Automate", "g"]
		StartComplete:Set[FALSE]
		if ${Config.DelayLogin}
		{
			UI:Update["Automate", "Login will proceed at \ag${Config.StartHour}:${Config.StartMinute}\ay plus ~\ag${Config.StartDelta}\ay minutes", "y"]
			ComBotLogin.Wait:Set[TRUE]
		}
		if ${Config.DelayLoginDelta}
		{
			UI:Update["Automate", "Login will proceed in ~\ag${Config.StartDelta}\ay minutes", "y"]
			ComBotLogin.Wait:Set[TRUE]
			variable int Delta=${Math.Rand[${Config.StartDelta} + 1]}
			StartComplete:Set[TRUE]
			UI:Update["Automate", "Starting in \ao${Delta}\ag minutes", "g"]
			This:QueueState["AllowLogin", ${Math.Calc[${Delta} * 60000]}]
			This:QueueState["WaitForLogin"]
			This:QueueState["AutoStart"]
			This:QueueState["Launch"]
		}
		This:QueueState["Automate"]
	}
	
	method Stop()
	{
		This:Clear
		UI:Update["Automate", "Stopping Automate", "g"]
	}
	
	member:bool Automate()
	{
		if ${Time.Hour} == ${Config.Hour} && ${Time.Minute} == ${Config.Minute}
		{
			Move:NonGameTiedPulse:Set[TRUE]
			This:QueueState["MoveToLogout"]
			This:QueueState["Traveling"]
			This:QueueState["Logout"]
			return TRUE
		}
		if ${Time.Hour} == ${Config.StartHour} && ${Time.Minute} == ${Config.StartMinute} && !${StartComplete}
		{
			variable int Delta=${Math.Rand[${Config.StartDelta} + 1]}
			StartComplete:Set[TRUE]
			UI:Update["Automate", "Starting in \ao${Delta}\ag minutes", "g"]
			This:QueueState["AllowLogin", ${Math.Calc[${Delta} * 60000]}]
			This:QueueState["WaitForLogin"]
			This:QueueState["AutoStart"]
			This:QueueState["Launch"]
			This:QueueState["Automate"]
			return TRUE
		}
		return FALSE
	}
	
	member:bool AllowLogin()
	{
		ComBotLogin.Wait:Set[FALSE]
		return TRUE
	}
	
	member:bool WaitForLogin()
	{
		if ${Me(exists)} && ${MyShip(exists)} && (${Me.InSpace} || ${Me.InStation})
		{
			return TRUE
		}
		return FALSE
	}
	
	member:bool AutoStart()
	{
		ComBot:Resume
		return TRUE
	}
	
	member:bool Launch()
	{
		if ${Config.Launch}
		execute ${Config.LaunchCommand}
		return TRUE
	}
	
	method LogoutNow()
	{
		Move:NonGameTiedPulse:Set[TRUE]
		This:Clear
		This:QueueState["MoveToLogout"]
		This:QueueState["Traveling"]
		This:QueueState["Logout"]
	}

	method StationaryLogoutNow()
	{
		This:Clear
		This:QueueState["Logout"]
	}
	
	
	member:bool MoveToLogout()
	{
		variable iterator Behaviors
		UI:Update["Automate", "Logout time!", "r"]
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


objectdef obj_AutomateUI inherits obj_State
{


	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
	}
	
	method Start()
	{
		This:QueueState["UpdateBookmarkLists", 5]
	}
	
	method Stop()
	{
		This:Clear
	}

	member:bool UpdateBookmarkLists()
	{
		variable index:bookmark Bookmarks
		variable iterator BookmarkIterator

		EVE:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		

		UIElement[BookmarkList@AutoLogout@ComBot_Automate_Frame@ComBot_Automate]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[Bookmark@AutoLogout@ComBot_Automate_Frame@ComBot_Automate].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Automate.Config.Bookmark.Length}].Equal[${Automate.Config.Bookmark}]}
						UIElement[BookmarkList@AutoLogout@ComBot_Automate_Frame@ComBot_Automate]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[BookmarkList@AutoLogout@ComBot_Automate_Frame@ComBot_Automate]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}
			
			
		return FALSE
	}

}