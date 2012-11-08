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


objectdef obj_InstaWarp inherits obj_State
{
	variable bool InstaWarp_Cooldown=FALSE
	
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		DynamicAddMiniMode("InstaWarp", "InstaWarp")
	}
	
	method Start()
	{
		This:QueueState["InstaWarp"]
	}
	
	method Stop()
	{
		This:Clear
	}
	
	member:bool InstaWarp()
	{
		if !${Client.InSpace}
		{
			return FALSE
		}
		
		if ${Me.ToEntity.Mode} == 3 && ${InstaWarp_Cooldown} && ${Ship.ModuleList_AB_MWD.ActiveCount}
		{
			Ship.ModuleList_AB_MWD:Deactivate
			return FALSE
		}
		
		if ${Me.ToEntity.Mode} == 3 && !${InstaWarp_Cooldown}
		{
			Ship.ModuleList_AB_MWD:Activate[-1, FALSE]
			InstaWarp_Cooldown:Set[TRUE]
			return FALSE
		}
		if ${Me.ToEntity.Mode} != 3
		{
			InstaWarp_Cooldown:Set[FALSE]
			return FALSE
		}
	}

}