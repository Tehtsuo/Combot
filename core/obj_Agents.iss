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

objectdef obj_MissionData
{
	variable string Type
	variable int Frequency
	variable string Args

	method Initialize(string arg_Name, int arg_Frequency, string arg_Args)
	{
		Name:Set[${arg_Name}]
		Frequency:Set[${arg_Frequency}]
		Args:Set["${arg_Args.Escape}"]
	}
	
	method Set(string arg_Name, int arg_Frequency, string arg_Args)
	{
		Name:Set[${arg_Name}]
		Frequency:Set[${arg_Frequency}]
		Args:Set["${arg_Args.Escape}"]
	}
}



objectdef obj_Agents inherits obj_State
{
	method Initialize()
	{
		This[parent]:Initialize
		;This.NonGameTiedPulse:Set[TRUE]
		
		;This:QueueState["CheckJournal"]
	}

	member:bool CheckJournal()
	{
		variable index:agentmission missions
		variable iterator mission
		
		EVE:GetAgentMissions[missions]
		missions:GetIterator[mission]
		if ${mission:First(exists)}
			do
			{
				echo ${mission.Value.Name} - ${mission.Value.Type} - ${mission.Value.State} - ${mission.Value.AgentID}
			}
			while ${mission:Next(exists)}
	}
	

}