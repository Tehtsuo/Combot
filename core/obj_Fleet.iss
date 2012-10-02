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

objectdef obj_Fleet inherits obj_State
{
	variable collection:int64 WingTranslation
	variable collection:int64 SquadTranslation
	
	
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		
		This:QueueState["Start"]
	}

	member:bool Start()
	{
		if ${Me.Fleet.IsMember[${Me.CharID}]}
		{
			This:QueueState["InFleet"]
		}
		else
		{
			This:QueueState["OutFleet"]
		}
		return TRUE
	}
	
	member:bool InFleet()
	{
		if ${Config.Fleets.Active.Equal[No Fleet]}
		{
			return FALSE
		}

		if !${Me.Fleet.IsMember[${Me.CharID}]}
		{
			This:QueueState["OutFleet"]
			return TRUE
		}
		
		if ${This.ActiveCommander} != ${Me.CharID} && !${Me.Fleet.IsMember[${This.ActiveCommander}]}
		{
			Me.Fleet:LeaveFleet
		}
		
		if ${Me.ID} == ${This.ActiveCommander}
		{
			if ${This.StructureFleet}
			{
				This:QueueState["Idle", 5000]
				This:QueueState["InFleet"]
				return TRUE
			}
		
			if ${This.InviteFleetMembers}
			{
				return FALSE
			}
		}
		
		return FALSE
	}
	
	member:bool OutFleet()
	{
		if ${Config.Fleets.Active.Equal[No Fleet]}
		{
			return FALSE
		}

		if ${Me.Fleet.IsMember[${Me.CharID}]}
		{
			This.WingTranslation:Clear
			This.SquadTranslation:Clear
			This:QueueState["InFleet"]
			return TRUE
		}
		
		if ${Me.ID} == ${This.ActiveCommander}
		{
			if ${This.InviteFleetMembers}
			{
				return FALSE
			}
		}

		if ${Me.Fleet.Invited}
		{
			if ${Me.Fleet.InvitationText.Find[${This.ResolveName[${This.ActiveCommander}]}]}
			{
				Me.Fleet:AcceptInvite
				return FALSE
			}
		}
		
		return FALSE
	}

	method SaveFleet(string name)
	{
		Config.Fleets:ClearFleet[${name.Escape}]
	
		variable index:fleetmember Members
		variable iterator Member
		
		Me.Fleet:GetMembers[Members]
		Members:GetIterator[Member]
		if ${Member:First(exists)}
			do
			{
				if ${Member.Value.RoleID} == 4
				{
					echo Adding Member
					Config.Fleets.GetFleet[${name.Escape}].GetWing[${Member.Value.WingID}].GetSquad[${Member.Value.SquadID}].GetMember[${Member.Value.ID}]:SetCreated[TRUE]
				}
				if ${Member.Value.RoleID} == 1
				{
					echo Adding Fleet Commander
					Config.Fleets.GetFleet[${name.Escape}]:SetCommander[${Member.Value.ID}]
				}
				if ${Member.Value.RoleID} == 2
				{
					echo Adding Wing Commander
					Config.Fleets.GetFleet[${name.Escape}].GetWing[${Member.Value.WingID}]:SetCommander[${Member.Value.ID}]
				}
				if ${Member.Value.RoleID} == 3
				{
					echo Adding Squad Commander
					Config.Fleets.GetFleet[${name.Escape}].GetWing[${Member.Value.WingID}].GetSquad[${Member.Value.SquadID}]:SetCommander[${Member.Value.ID}]
				}
			}
			while ${Member:Next(exists)}

		This:UpdateFleetUI
	}
	
	method DeleteFleet(string name)
	{
		Config.Fleets:ClearFleet[${name}]
		This:UpdateFleetUI
	}
	
	method UpdateFleetUI()
	{
		UIElement[FleetSelection@Settings@ComBotTab@ComBot]:ClearItems
		UIElement[FleetSelection@Settings@ComBotTab@ComBot]:AddItem[No Fleet]
		variable iterator FleetIterator
		Config.Fleets.Fleets:GetSetIterator[FleetIterator]
		if ${FleetIterator:First(exists)}
		{
			do
			{
				UIElement[FleetSelection@Settings@ComBotTab@ComBot]:AddItem[${FleetIterator.Key}]
			}
			while ${FleetIterator:Next(exists)}
		}
		UIElement[FleetSelection@Settings@ComBotTab@ComBot].ItemByText[No Fleet]:Select
		
	}


	
	member:int64 ActiveCommander()
	{
		if ${Config.Fleets.GetFleet[${Config.Fleets.Active}].Commander} > 0
		{
			return ${Config.Fleets.GetFleet[${Config.Fleets.Active}].Commander}
		}
	
		variable iterator Wing
		Config.Fleets.GetFleet[${Config.Fleets.Active}].Wings:GetSetIterator[Wing]
		if ${Wing:First(exists)}
			do
			{
				if ${Wing.Value.FindSetting[Commander].Int}
					return ${Wing.Value.FindSetting[Commander].Int}
					
				variable iterator Squad
				Wing.Value.FindSet[Squads]:GetSetIterator[Squad]
				if ${Squad:First(exists)}
					do
					{
						if ${Squad.Value.FindSetting[Commander].Int}
							return ${Squad.Value.FindSetting[Commander].Int}
					}
					while ${Squad:Next(exists)}
			}
			while ${Wing:Next(exists)}
			
		return 0		
		
	}
	
	member:string ResolveName(int64 value)
	{
		variable index:pilot CorpMembers
		variable iterator CorpMember

		EVE:GetOnlineCorpMembers[CorpMembers]
		CorpMembers:GetIterator[CorpMember]
		if ${CorpMember:First(exists)}
			do
			{
				if ${CorpMember.Value.CharID} == ${value}
				{
					return ${CorpMember.Value.Name}
				}
			}
			while ${CorpMember:Next(exists)}

		variable index:being Buddies
		variable iterator Buddy

		EVE:GetBuddies[Buddies]
		Buddies:GetIterator[Buddy]
		if ${Buddy:First(exists)}
			do
			{
				if ${Buddy.Value.CharID} == ${value}
				{
					return ${Buddy.Value.Name}
				}
			}
			while ${Buddy:Next(exists)}

		variable index:pilot LocalPilots
		variable iterator LocalPilot

		EVE:GetLocalPilots[LocalPilots]
		LocalPilots:GetIterator[LocalPilot]
		if ${LocalPilot:First(exists)}
			do
			{
				if ${LocalPilot.Value.CharID} == ${value}
				{
					return ${LocalPilot.Value.Name}
				}
			}
			while ${LocalPilot:Next(exists)}
			
		return "FALSE"
	}
	
	member:bool StructureFleet()
	{
		variable iterator Wing
		variable iterator Squad
		variable iterator Member
		Config.Fleets.GetFleet[${Config.Fleets.Active}].Wings:GetSetIterator[Wing]
		if ${Wing:First(exists)}
			do
			{
				if !${This.WingExists[${Wing.Key}]}
				{
					Me.Fleet:CreateWing
					return TRUE
				}
				Wing.Value.FindSet[Squads]:GetSetIterator[Squad]
				if ${Squad:First(exists)}
					do
					{
						if !${This.SquadExists[${Wing.Key}, ${Squad.Key}]}
						{
							Me.Fleet:CreateSquad[${This.WingTranslation.Element[${Wing.Key}]}]
							return TRUE
						}
						
						Squad.Value.FindSet[Members]:GetSetIterator[Member]
						if ${Member:First(exists)}
							do
							{
								echo Member ${Member.Key} is supposed to be in Wing ${Wing.Key}, Squad ${Squad.Key}
								if ${This.MoveMember[${Wing.Key}, ${Squad.Key}, ${Member.Key}]}
								{
									return TRUE
								}
							}
							while ${Member:Next(exists)}
					}
					while ${Squad:Next(exists)}
			}
			while ${Wing:Next(exists)}
		

		return FALSE
	}
	
	member:bool WingExists(int64 value)
	{
		;	Say yes if the wing from settings is already translated
		if ${This.WingTranslation.Element[${value}](exists)}
		{
			return TRUE
		}

		;	Otherwise, find a wing in-game that isn't in WingTranslation
		variable index:int64 Wings
		variable iterator Wing
		variable bool Untranslated
		variable iterator Translated
		Me.Fleet:GetWings[Wings]
		Wings:GetIterator[Wing]
		if ${Wing:First(exists)}
			do
			{
				Untranslated:Set[TRUE]
				This.WingTranslation:GetIterator[Translated]
				if ${Translated:First(exists)}
					do
					{
						if ${Translated.Value} == ${Wing.Value}
						{
							Untranslated:Set[FALSE]
						}
					}
					while ${Translated:Next(exists)}	
				if ${Untranslated}
				{
					This.WingTranslation:Set[${value}, ${Wing.Value}]
					return TRUE
				}
			}
			while ${Wing:Next(exists)}	
		return FALSE
	}

	member:bool SquadExists(int64 wing, int64 value)
	{
		;	Say yes if the squad from settings is already translated
		if ${This.SquadTranslation.Element[${value}](exists)}
		{
			return TRUE
		}

		;	Otherwise, find a squad in-game that isn't in WingTranslation
		variable index:int64 Squads
		variable iterator Squad
		variable bool Untranslated
		variable iterator Translated
		Me.Fleet:GetSquads[Squads, ${This.WingTranslation.Element[${wing}]}]
		Squads:GetIterator[Squad]
		if ${Squad:First(exists)}
			do
			{
				Untranslated:Set[TRUE]
				This.SquadTranslation:GetIterator[Translated]
				if ${Translated:First(exists)}
					do
					{
						if ${Translated.Value} == ${Squad.Value}
						{
							Untranslated:Set[FALSE]
						}
					}
					while ${Translated:Next(exists)}	
				if ${Untranslated}
				{
					This.SquadTranslation:Set[${value}, ${Squad.Value}]
					return TRUE
				}
			}
			while ${Squad:Next(exists)}	
		return FALSE
	}
	
	member:bool MoveMember(int64 wing, int64 squad, int64 value)
	{
		if ${Me.Fleet.Member[${value}](exists)}
		{
			if 	${Me.Fleet.Member[${value}].WingID} != ${This.WingTranslation.Element[${wing}]} ||\
				${Me.Fleet.Member[${value}].SquadID} != ${This.SquadTranslation.Element[${squad}]}
			{
				Me.Fleet.Member[${value}]:Move[${This.WingTranslation.Element[${wing}]}, ${This.SquadTranslation.Element[${squad}]}]
				return TRUE
			}
		}
		return FALSE
	}
	
	member:bool InviteFleetMembers()
	{
		variable iterator Wing
		Config.Fleets.GetFleet[${Config.Fleets.Active}].Wings:GetSetIterator[Wing]
		if ${Wing:First(exists)}
			do
			{
				if ${This.InviteToFleet[${Wing.Value.FindSetting[Commander]}]}
					return TRUE
				variable iterator Squad
				Wing.Value.FindSet[Squads]:GetSetIterator[Squad]
				if ${Squad:First(exists)}
					do
					{
						if ${This.InviteToFleet[${Squad.Value.FindSetting[Commander]}]}
							return TRUE
						
						variable iterator Member
						Squad.Value.FindSet[Members]:GetSetIterator[Member]
						if ${Member:First(exists)}
							do
							{
								if ${This.InviteToFleet[${Member.Value.Name}]}
									return TRUE
							}
							while ${Member:Next(exists)}
					}
					while ${Squad:Next(exists)}
			}
			while ${Wing:Next(exists)}
			
		return FALSE
	}	

	
	member:bool InviteToFleet(int64 value)
	{

		if ${Me.Fleet.Member[${value}](exists)} || ${value} == 0
		{
			return FALSE
		}
		
	
		variable index:pilot CorpMembers
		variable iterator CorpMember

		EVE:GetOnlineCorpMembers[CorpMembers]
		CorpMembers:GetIterator[CorpMember]
		if ${CorpMember:First(exists)}
			do
			{
				if ${CorpMember.Value.CharID} == ${value}
				{
					CorpMember.Value:InviteToFleet
					return TRUE
				}
			}
			while ${CorpMember:Next(exists)}

		variable index:being Buddies
		variable iterator Buddy

		EVE:GetBuddies[Buddies]
		Buddies:GetIterator[Buddy]
		if ${Buddy:First(exists)}
			do
			{
				if ${Buddy.Value.CharID} == ${value}
				{
					Buddy.Value:InviteToFleet
					return TRUE
				}
			}
			while ${Buddy:Next(exists)}

		variable index:pilot LocalPilots
		variable iterator LocalPilot

		EVE:GetLocalPilots[LocalPilots]
		LocalPilots:GetIterator[LocalPilot]
		if ${LocalPilot:First(exists)}
			do
			{
				if ${LocalPilot.Value.CharID} == ${value}
				{
					LocalPilot.Value:InviteToFleet
					return TRUE
				}
			}
			while ${LocalPilot:Next(exists)}
		
		return FALSE
	}
	
	method Flee()
	{
		; This flee is here as an override to keep obj_Security from clearing the queue
	}
	
}