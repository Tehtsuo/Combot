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

objectdef obj_LogiTracker inherits obj_State
{
	
	variable IPCCollection:IPCCollection:int Health = "LogiTracker"
	variable IPCCollection:int MyHealth
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[500]
		Dynamic:AddMiniMode["LogiTracker", "LogiTracker", FALSE]
		Health:Set[${MyShip.ID}, "LogiTracker_${MyShip.ID}"]
		MyHealth:Set["LogiTracker_${MyShip.ID}"]
	}
	
	method Start()
	{
		UI:Update["obj_LogiTracker", "Starting LogiTracker", "g"]
		This:QueueState["LogiTrack"]
	}
	
	method Stop()
	{
		This:Clear
		UI:Update["obj_LogiTracker", "Stopping LogiTracker", "g"]
	}
	
	member:bool LogiTrack()
	{
		if !${Client.InSpace} || ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		if ${MyShip.Shield.NotEqual[${MyHealth.Element["Shield"]}]}
		{
			MyHealth:Set["Shield", ${MyShip.Shield}]
		}
		if ${MyShip.MaxShield.NotEqual[${MyHealth.Element["MaxShield"]}]}
		{
			MyHealth:Set["MaxShield", ${MyShip.MaxShield}]
		}
		if ${MyShip.Armor.NotEqual[${MyHealth.Element["Armor"]}]}
		{
			MyHealth:Set["Armor", ${MyShip.Armor}]
		}
		if ${MyShip.MaxArmor.NotEqual[${MyHealth.Element["MaxArmor"]}]}
		{
			MyHealth:Set["MaxArmor", ${MyShip.MaxArmor}]
		}
		if ${MyShip.Structure.NotEqual[${MyHealth.Element["Structure"]}]}
		{
			MyHealth:Set["Structure", ${MyShip.Structure}]
		}
		if ${MyShip.MaxStructure.NotEqual[${MyHealth.Element["MaxStructure"]}]}
		{
			MyHealth:Set["MaxStructure", ${MyShip.MaxStructure}]
		}
		
		
		return FALSE
	}
}