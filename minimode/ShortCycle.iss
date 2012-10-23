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



objectdef obj_ShortCycle inherits obj_State
{
	
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		This.RandomDelta:Set[10000]
		DynamicAddMiniMode("ShortCycle", "ShortCycle")
	}
	
	method Start()
	{
		This:QueueState["ShortCycle", 30000]
	}
	
	method Stop()
	{
		This:Clear
	}
	
	member:bool ShortCycle()
	{
		if !${Client.InSpace}
		{
			return FALSE
		}

		if ${Ship.ModuleList_MiningLaser.ActiveCount} && ${MyShip.CapacitorPct} > 30
		{
			Ship.ModuleList_MiningLaser:DeactivateCount[${Ship.ModuleList_MiningLaser.ActiveCount}]
		}

		return FALSE
	}

}