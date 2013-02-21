/*

ComBot  Copyright � 2012  Tehtsuo and Vendan

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



#include temp/version.iss
#include core/Defines.iss
#include core/Macros.iss
#include core/obj_ComBot.iss
#include core/obj_Configuration.iss

#include core/obj_State.iss
#include core/obj_ComBotUI.iss
#include core/obj_Client.iss
#include core/obj_Move.iss
#include core/obj_ModuleBase.iss
#include core/obj_Module.iss
#include core/obj_ModuleList.iss
#include core/obj_Ship.iss
#include core/obj_Cargo.iss
#include core/obj_Jetcan.iss
#include core/obj_TargetList.iss
#include core/obj_Drones.iss
#include core/obj_Profiling.iss
#include core/obj_Delay.iss
#include core/obj_Fleet.iss
#include core/obj_Login.iss
#include core/obj_Dynamic.iss
#include core/obj_Busy.iss
#include core/obj_NPCData.iss
#include core/obj_PriorityTargets.iss

#include temp/behaviorincludes.iss

#include temp/minimodeincludes.iss

#include temp/thirdpartybehaviorincludes.iss

#include temp/thirdpartyminimodeincludes.iss

function atexit()
{

}

function main(string Character="")
{
	declarevariable MinimumISXEVE float64 script
	MinimumISXEVE:Set[20121210.0034]

	declarevariable EVEExtension obj_EVEExtension script
	EVEExtension.Character:Set[${Character}]
	call EVEExtension.Initialize

	module -require LSMIPC
	echo "${Time} ComBot: Starting"

	declarevariable UI obj_ComBotUI script
	declarevariable ComBot obj_ComBot script
	declarevariable BaseConfig obj_Configuration_BaseConfig script
	declarevariable Config obj_Configuration script
	UI:Reload
	
	

	declarevariable NPCData obj_NPCData script
	declarevariable PriorityTargets obj_PriorityTargets script
	declarevariable ComBotLogin obj_Login script
	declarevariable Dynamic obj_Dynamic script
	#include temp/behaviordeclares.iss
	
	#include temp/minimodedeclares.iss

	#include temp/thirdpartybehaviordeclares.iss
	
	#include temp/thirdpartyminimodedeclares.iss
	
	Dynamic:PopulateBehaviors
	Dynamic:PopulateMiniModes
	while TRUE
	{
		if ${Me(exists)} && ${MyShip(exists)} && (${Me.InSpace} || ${Me.InStation})
		{
			break
		}
		wait 10
	}
	Config.Common:SetCharID[${Me.CharID}]
	
	declarevariable Profiling obj_Profiling script
	declarevariable Client obj_Client script
	declarevariable Move obj_Move script
	declarevariable Ship obj_Ship script
	declarevariable Cargo obj_Cargo script
	declarevariable RefineData obj_Configuration_RefineData script
	declarevariable AgentDialog obj_AgentDialog script
	declarevariable Drones obj_Drones script
	declarevariable Jetcan obj_Jetcan script
	declarevariable Delay obj_Delay script
	declarevariable Fleets obj_Fleet script
	declarevariable Busy obj_Busy script
	
	
	UI:Update["ComBot", "Module initialization complete", "y"]
	
	if ${Config.Common.AutoStart}
	{
		ComBot:Resume
	}
	else
	{
		UI:Update["ComBot", "Paused", "r"]
	}
	

	while TRUE
	{
		wait 10
	}
}
