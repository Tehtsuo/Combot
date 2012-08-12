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

objectdef obj_Security inherits obj_State
{
	variable obj_SecurityUI SecurityUI

	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[FALSE]
		This:AssignStateQueueDisplay[obj_SecurityStateList@Security@ComBotTab@ComBot]

		if !${Config.Security.FleeTo(exists)} || ${Config.Security.FleeTo.Equal[NULL]} || ${Config.Security.FleeTo.Equal[]}
		{
			UI:Update["obj_Security", "No flee bookmark set.  This is DANGEROUS!", "r"]
			UI:Update["obj_Security", "Specify a flee bookmark in the Security settings!", "r"]
		}
	}
	
	method Start()
	{
		if ${This.IsIdle}
		{
			This:QueueState["CheckSafe", 500]
		}
	}
	
	method Stop()
	{
		This:Clear
	}

	
	member:bool CheckSafe(bool ClearFlee=FALSE)
	{
		Profiling:StartTrack["Security_CheckSafe"]
		variable index:pilot Pilots
		variable iterator Pilot_Iterator
		
		if ${This.InPod}
		{
				This:QueueState["Flee", 500, "I am in a pod!"]
				Profiling:EndTrack
				return TRUE
		}

		Profiling:StartTrack["GetLocalPilots"]
		EVE:GetLocalPilots[Pilots]
		Profiling:EndTrack
		Pilots:GetIterator[Pilot_Iterator]
		
		if ${Pilot_Iterator:First(exists)}
		do
		{
		
			if ${Config.Security.MeToPilot} && ${Pilot_Iterator.Value.Standing.MeToPilot} < ${Config.Security.MeToPilot_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Name}(pilot) is ${Pilot_Iterator.Value.Standing.MeToPilot} standing to you"]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.Security.MeToCorp} && ${Pilot_Iterator.Value.Standing.MeToCorp} < ${Config.Security.MeToCorp_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Corp.Name}(corp) is ${Pilot_Iterator.Value.Standing.MeToCorp} standing to you"]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.Security.MeToAlliance} && ${Pilot_Iterator.Value.Standing.MeToAlliance} < ${Config.Security.MeToAlliance_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Alliance.Name}(alliance) is ${Pilot_Iterator.Value.Standing.MeToAlliance} standing to you"]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.Security.CorpToPilot} && ${Pilot_Iterator.Value.Standing.CorpToPilot} < ${Config.Security.CorpToPilot_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Name}(pilot) is ${Pilot_Iterator.Value.Standing.CorpToPilot} standing to your corporation"]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.Security.CorpToCorp} && ${Pilot_Iterator.Value.Standing.CorpToCorp} < ${Config.Security.CorpToCorp_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Corp.Name}(corp) is ${Pilot_Iterator.Value.Standing.CorpToCorp} standing to your corporation"]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.Security.CorpToAlliance} && ${Pilot_Iterator.Value.Standing.CorpToAlliance} < ${Config.Security.CorpToAlliance_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Alliance.Name}(alliance) is ${Pilot_Iterator.Value.Standing.CorpToAlliance} standing to your corporation"]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.Security.AllianceToPilot} && ${Pilot_Iterator.Value.Standing.AllianceToPilot} < ${Config.Security.AllianceToPilot_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Name}(pilot) is ${Pilot_Iterator.Value.Standing.AllianceToPilot} standing to your alliance"]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.Security.AllianceToCorp} && ${Pilot_Iterator.Value.Standing.AllianceToCorp} < ${Config.Security.AllianceToCorp_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Corp.Name}(corp) is ${Pilot_Iterator.Value.Standing.AllianceToCorp} standing to your alliance"]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.Security.AllianceToAlliance} && ${Pilot_Iterator.Value.Standing.AllianceToAlliance} < ${Config.Security.AllianceToAlliance_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Alliance.Name}(alliance) is ${Pilot_Iterator.Value.Standing.AllianceToAlliance} standing to your alliance"]
				Profiling:EndTrack
				return TRUE
			}
			
		}
		while ${Pilot_Iterator:Next(exists)}

		if ${Config.Security.TargetFlee}
		{
			variable index:entity Threats
			variable iterator Threat
			variable int MyAllianceID
			variable int MyCorpID

			Me:GetTargetedBy[Threats]
			Threats:RemoveByQuery[${LavishScript.CreateQuery[IsPC]}, FALSE]
			Threats:Collapse
			Threats:GetIterator[Threat]
			if ${Me.Corp.ID} == -1
			{
				MyCorpID:Set[0]
				MyAllianceID:Set[0]
			}
			else
			{
				MyCorpID:Set[${Me.Corp.ID}]
				if  ${Me.AllianceID} == -1
				{
					MyAllianceID:Set[0]
				}
				else
				{
					MyAllianceID:Set[${Me.AllianceID}]
				}
			}
			
			if ${Threat:First(exists)}
			do
			{
				if ${MyCorpID} == ${Threat.Value.CorpID} && !${Config.Security.CorpFlee}
				{
					continue
				}
				if ${MyAllianceID} == ${Threat.Value.AllianceID} && !${Config.Security.AllianceFlee}
				{
					continue
				}
				if ${Me.Fleet.IsMember[${Threat.Value.CharID}]} && !${Config.Security.FleetFlee}
				{
					continue
				}
				
				This:QueueState["Flee", 500, "${Threat.Value.Name} is targeting me!"]
				Profiling:EndTrack
				return TRUE
			}
			while ${Threat:Next(exists)}
		}
		

		
		if ${ClearFlee}
		{
			ComBot:Resume
			This:QueueState["CheckSafe", 500]
			Profiling:EndTrack
			return TRUE
		}
		Profiling:EndTrack
		return FALSE
	}
	
	member:bool Flee(string Message)
	{
		Profiling:StartTrack["Security_Flee"]
		UI:Update["obj_Security", "Flee triggered!", "r"]
		UI:Update["obj_Security", "${Message}", "r"]
		Event[ComBot_Flee]:Execute[]

		Move:Bookmark[${Config.Security.OverrideFleeBookmark}]
		This:QueueState["Traveling"]

		if ${Config.Security.FleeWaitTime_Enabled}
		{
			This:QueueState["Log", "Waiting for ${Config.Security.FleeWaitTime} minutes after flee"]
			This:QueueState["Idle", ${Math.Calc[${Config.Security.FleeWaitTime} * 60000]}]
		}

		This:QueueState["CheckSafe", 500, TRUE]
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool Log(string text)
	{
		UI:Update["obj_Security", "${text.Escape}", "g"]
		return TRUE
	}

	member:bool Traveling()
	{
		if ${Move.Traveling} || ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		return TRUE
	}
	
	member:bool InPod()
	{
		variable string ShipName = ${MyShip}
		variable int GroupID
		variable int TypeID

		if !${Client.Ready}
		{
			return FALSE
		}
		
		if ${Client.InSpace}
		{
			GroupID:Set[${MyShip.ToEntity.GroupID}]
			TypeID:Set[${MyShip.ToEntity.TypeID}]
		}
		else
		{
			GroupID:Set[${MyShip.ToItem.GroupID}]
			TypeID:Set[${MyShip.ToItem.TypeID}]
		}
		if ${ShipName.Right[10].Equal["'s Capsule"]} || \
			${GroupID} == GROUP_CAPSULE
		{
			return TRUE
		}
		return FALSE
	}	
}

objectdef obj_SecurityUI inherits obj_State
{


	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
	}
	
	method Start()
	{
		This:QueueState["UpdateBookmarkLists", 5]
	}
	
	method Stop()
	{
		This:Clear
	}

	member:bool UpdateBookmarkLists()
	{
		variable index:bookmark Bookmarks
		variable iterator BookmarkIterator

		EVE:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		
		UIElement[FleeToList@ComBot_Security_Frame@ComBot_Security]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[FleeTo@ComBot_Security_Frame@ComBot_Security].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Config.Security.FleeTo.Length}].Equal[${Config.Security.FleeTo}]} && ${BookmarkIterator.Value.Label.NotEqual[${Config.Security.FleeTo}]}
						UIElement[FleeToList@ComBot_Security_Frame@ComBot_Security]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[FleeToList@ComBot_Security_Frame@ComBot_Security]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}
			
		return FALSE
	}

}