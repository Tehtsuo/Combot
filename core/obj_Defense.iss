/*

ComBot  Copyright ? 2012  Tehtsuo and Vendan

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

objectdef obj_Defense inherits obj_State
{
	variable index:entity Locked
	variable index:entity Asteroids

	method Initialize()
	{
		
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]

		This:QueueState["Defend", 50]
	}
	
	member:bool Defend()
	{
		Profiling:StartTrack["Defense_Defend"]
		if !${Client.InSpace}
		{
			Profiling:EndTrack
			return FALSE
		}
		if ${Ship.ModuleList_Regen_Shield.InactiveCount} && (${MyShip.ShieldPct} < 95 || ${Config.Common.AlwaysShieldBoost})
		{
			Ship.ModuleList_Regen_Shield:ActivateCount[${Ship.ModuleList_Regen_Shield.InactiveCount}]
		}
		if ${Ship.ModuleList_Regen_Shield.ActiveCount} && ${MyShip.ShieldPct} > 95 && !${Config.Common.AlwaysShieldBoost}
		{
			Ship.ModuleList_Regen_Shield:DeactivateCount[${Ship.ModuleList_Regen_Shield.ActiveCount}]
		}
		
		if ${Ship.ModuleList_ActiveResists.Count}
		{
			Ship.ModuleList_ActiveResists:ActivateCount[${Ship.ModuleList_ActiveResists.Count}]
		}
		if ${Ship.ModuleList_ActiveResists.Count}
		{
			Ship.ModuleList_ActiveResists:ActivateCount[${Ship.ModuleList_ActiveResists.Count}]
		}

		if ${Ship.ModuleList_Cloaks.Count}
		{
			Ship.ModuleList_Cloaks:Activate
		}

		if ${Ship.ModuleList_GangLinks.ActiveCount} < ${Ship.ModuleList_GangLinks.Count} && ${Me.ToEntity.Mode} != 3
		{
			Ship.ModuleList_GangLinks:ActivateCount[${Math.Calc[${Ship.ModuleList_GangLinks.Count} - ${Ship.ModuleList_GangLinks.ActiveCount}]}]
		}
		
		Profiling:EndTrack
		return FALSE	
	}
		
}