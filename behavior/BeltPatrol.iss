/*

ComBot Copyright © 2012 Tehtsuo and Vendan

This file is part of ComBot.

ComBot is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ComBot is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ComBot. If not, see <http://www.gnu.org/licenses/>.

*/

objectdef obj_BeltPatrol inherits obj_State
{

	variable index:entity Belts

	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[500]
		Dynamic:AddBehavior["BeltPatrol", "Belt Patrol", FALSE]
	}


	method Start()
	{
		UI:Update["obj_BeltPatrol", "Started", "g"]
		This:AssignStateQueueDisplay[DebugStateList@Debug@ComBotTab@ComBot]
		if ${This.IsIdle}
		{
			This:QueueState["BeltPatrol"]
		}
	}

	method Stop()
	{
		This:DeactivateStateQueueDisplay
		This:Clear
	}


	member:bool Traveling()
	{
		if ${Move.Traveling} || ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		return TRUE
	}


	member:bool MoveToBelt()
	{
		variable int curBelt
		variable int TryCount

		if ${Belts.Used} == 0
		{
			EVE:QueryEntities[Belts, "GroupID = GROUP_ASTEROIDBELT"]
		}

		Move:Object[${Entity[${Belts[1].ID}]}]
		Belts:Remove[1]
		Belts:Collapse
		return TRUE
	}

	member:bool Undock()
	{
		Move:Undock
		return TRUE
	}

	
	member:bool BeltPatrol()
	{
		if !${Client.InSpace}
		{
			This:QueueState["Undock"]
			This:QueueState["MoveToBelt"]
			This:QueueState["Traveling"]
			This:QueueState["BeltPatrol"]
			return TRUE
		}

		This:QueueState["MoveToBelt"]
		This:QueueState["Traveling"]
		This:QueueState["BeltPatrol"]
		return TRUE
	} 
}