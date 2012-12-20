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

objectdef obj_Configuration_MemoryManager
{
	variable string SetName = "MemoryManager"

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

		This.CommonRef:AddSetting[Size, 500]
	}

	Setting(int, Size, SetSize)
	
}

objectdef obj_MemoryManager inherits obj_State
{
	variable obj_Configuration_MemoryManager Config
	
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		DynamicAddMiniMode("MemoryManager", "MemoryManager")
	}
	
	method Start()
	{
		execute dotnet memmanager memmanager ${Math.Calc[(${Config.Size}) * 1048576].Int}
		This:QueueState["Manage", 300000]
	}
	
	method Stop()
	{
		This:Clear
	}
	
	member:bool Manage()
	{
		execute dotnet memmanager memmanager ${Math.Calc[(${Config.Size}) * 1048576].Int}
		return FALSE
	}
}