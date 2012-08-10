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

objectdef obj_Client
{
	variable int PulseIntervalInMilliseconds = 500
	variable int NextPulse
	
	variable bool Ready=TRUE
	variable int64 SystemID=${Me.SolarSystemID}
	
	method Initialize()
	{
		Event[ISXEVE_onFrame]:AttachAtom[This:Pulse]
	}

	method Shutdown()
	{
		Event[ISXEVE_onFrame]:DetachAtom[This:Pulse]
	}	

	method Pulse()
	{
		if ${LavishScript.RunningTime} >= ${This.NextPulse}
		{
			if ${Me.SolarSystemID} != ${SystemID}
			{
				echo SolarSystemID:  ${Me.SolarSystemID}
				SystemID:Set[${Me.SolarSystemID}]
				This:Wait[5000]
				return
			}
			
			This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${PulseIntervalInMilliseconds} + ${Math.Rand[500]}]}]

			if ${ComBot.Paused}
			{
				return
			}			
			
			This.Ready:Set[TRUE]
		}
	}
	
	member:bool InSpace()
	{
		if ${Me.InStation}
		{
			if ${Ship.RetryUpdateModuleList} == 0
			{
				Ship.RetryUpdateModuleList:Set[1]
			}
		}
		if ${Me.InSpace(type).Name.Equal[bool]} && ${EVE.EntitiesCount} > 0
		{
			return ${Me.InSpace}
		}
		return FALSE
	}
	
	

	method Wait(int delay)
	{
		UI:Update["obj_Client", "Initiating ${delay} millisecond wait", "-o"]
		This.Ready:Set[FALSE]
		This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${delay}]}]
	}
	

}