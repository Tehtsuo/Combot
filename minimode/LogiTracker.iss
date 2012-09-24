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

objectdef obj_EntityHealth
{
	variable float64 Shield
	variable float64 MaxShield
	variable float64 Armor
	variable float64 MaxArmor
	variable float64 Hull
	variable float64 MaxHull
	method Initialize(float64 argShield, float64 argMaxShield, float64 argArmor, float64 argMaxArmor, float64 argHull, float64 argMaxHull)
	{
		Shield:Set[${argShield}]
		MaxShield:Set[${argMaxShield}]
		Armor:Set[${argArmor}]
		MaxArmor:Set[${argMaxArmor}]
		Hull:Set[${argHull}]
		MaxHull:Set[${argMaxHull}]
	}
	
}

objectdef obj_LogiTracker inherits obj_State
{
	
	variable IPCCollection:obj_EntityHealth Health
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[500]
		Dynamic:AddMiniMode["LogiTracker", "LogiTracker", FALSE]
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
		
		echo ${MyShip.ID}, ${MyShip.Shield}, ${MyShip.MaxShield}, ${MyShip.Armor}, ${MyShip.MaxArmor}, ${MyShip.Structure}, ${MyShip.MaxStructure}
		
		return FALSE
	}
}