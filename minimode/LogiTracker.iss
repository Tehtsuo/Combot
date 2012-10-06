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
	
	variable IPCCollection:IPCCollection:float Health = "LogiTracker"
	variable IPCCollection:float MyHealth
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[500]
		;DynamicAddMiniMode("LogiTracker", "LogiTracker")
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
		if !${MyShip.Shield.Precision[3].Equal[${MyHealth.Element["Shield"]}]}
		{
			MyHealth:Set["Shield", ${MyShip.Shield.Precision[3]}]
		}
		if !${MyShip.MaxShield.Precision[3].Equal[${MyHealth.Element["MaxShield"]}]}
		{
			MyHealth:Set["MaxShield", ${MyShip.MaxShield.Precision[3]}]
		}
		if !${MyShip.Armor.Precision[3].Equal[${MyHealth.Element["Armor"]}]}
		{
			MyHealth:Set["Armor", ${MyShip.Armor.Precision[3]}]
		}
		if !${MyShip.MaxArmor.Precision[3].Equal[${MyHealth.Element["MaxArmor"]}]}
		{
			MyHealth:Set["MaxArmor", ${MyShip.MaxArmor.Precision[3]}]
		}
		if !${MyShip.Structure.Precision[3].Equal[${MyHealth.Element["Structure"]}]}
		{
			MyHealth:Set["Structure", ${MyShip.Structure.Precision[3]}]
		}
		if !${MyShip.MaxStructure.Precision[3].Equal[${MyHealth.Element["MaxStructure"]}]}
		{
			MyHealth:Set["MaxStructure", ${MyShip.MaxStructure.Precision[3]}]
		}
		
		
		return FALSE
	}
}