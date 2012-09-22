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
		This.CommonRef:AddSet["Names"]
	}
}


objectdef obj_GridWatcher inherits obj_State
{
	variable obj_Configuration_GridWatcher Config
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[1000]
	}
	
	method Start()
	{
		UI:Update["obj_GridWatcher", "Starting Grid Watch"]
		This:QueueState["WatchGrid"]
	}
	
	method Stop()
	{
		This:Clear
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
					UI:Update["obj_GridWatcher", "${Entity[Name =- "${EntityNames.Value.Name}"].Name} Found"]
				}
			}
			while ${EntityNames:Next(exists)}
		}
		return FALSE
	}
}