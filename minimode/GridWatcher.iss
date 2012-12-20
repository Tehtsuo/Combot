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

objectdef obj_Configuration_GridWatcher
{
	variable string SetName = "GridWatcher"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.CommonRef:AddSet["Names"]
		This.CommonRef:AddSetting["Created", True]
	}
}


objectdef obj_GridWatcher inherits obj_State
{
	variable obj_Configuration_GridWatcher Config
	variable set AlreadyDetected
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[1000]
		DynamicAddMiniMode("GridWatcher", "GridWatcher")
	}
	
	method Start()
	{
		UI:Update["obj_GridWatcher", "Starting Grid Watch", "g"]
		This:QueueState["WatchGrid"]
	}
	
	method Stop()
	{
		This:Clear
		UI:Update["obj_GridWatcher", "Stopping Grid Watch", "g"]
	}
	
	member:bool WatchGrid()
	{
		if !${Client.InSpace} || ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		variable iterator EntityNames
		This.Config.CommonRef.FindSet[Names]:GetSettingIterator[EntityNames]
		
		if ${EntityNames:First(exists)}
		{
			do
			{
				if ${Entity[Name =- "${EntityNames.Value.Name}"](exists)}
				{
					if !${AlreadyDetected.Contains[${Entity[Name =- "${EntityNames.Value.Name}"].ID}]}
					{
						uplink speak "${Entity[Name =- "${EntityNames.Value.Name}"].Name} Found"
						AlreadyDetected:Add[${Entity[Name =- "${EntityNames.Value.Name}"].ID}]
						EVE:CreateBookmark["${Entity[Name =- "${EntityNames.Value.Name}"].Name} ${EVETime.Time.Left[-3].Replace[":",""]}"]
					}
				}
			}
			while ${EntityNames:Next(exists)}
		}
		return FALSE
	}
}