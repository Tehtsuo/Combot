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
		echo In Fleet: ${Me.Fleet.IsMember[${Me.CharID}]}
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
		
		echo ${This.ActiveCommander} != ${Me.CharID} && !${Me.Fleet.IsMember[${This.ActiveCommander}]}
		if ${This.ActiveCommander} != ${Me.CharID} && !${Me.Fleet.IsMember[${This.ActiveCommander}]}
		{
			Me.Fleet:LeaveFleet
		}
		
		if ${Me.ID} == ${This.ActiveCommander}
		{
			if ${This.StructureFleet}
			{
				return FALSE
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
		echo Before No Fleet check
		if ${Config.Fleets.Active.Equal[No Fleet]}
		{
			return FALSE
		}

		echo Before IsMember check
		if ${Me.Fleet.IsMember[${Me.CharID}]}
		{
			This:QueueState["InFleet"]
			return TRUE
		}
		
		echo ${Me.ID} == ${This.ActiveCommander}
		
		if ${Me.ID} == ${This.ActiveCommander}
		{
			echo Before Invite
			if ${This.InviteFleetMembers}
			{
				echo Invited
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
		Config.Fleets:ClearFleet[${name}]
	
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
					Config.Fleets.GetFleet[${name}].GetWing[${Member.Value.WingID}].GetSquad[${Member.Value.SquadID}].GetMember[${Member.Value.ID}]:SetCreated[TRUE]
				}
				if ${Member.Value.RoleID} == 1
				{
					echo Adding Fleet Commander
					Config.Fleets.GetFleet[${name}]:SetCommander[${Member.Value.ID}]
				}
				if ${Member.Value.RoleID} == 2
				{
					echo Adding Wing Commander
					Config.Fleets.GetFleet[${name}].GetWing[${Member.Value.WingID}]:SetCommander[${Member.Value.ID}]
				}
				if ${Member.Value.RoleID} == 3
				{
					echo Adding Squad Commander
					Config.Fleets.GetFleet[${name}].GetWing[${Member.Value.WingID}].GetSquad[${Member.Value.SquadID}]:SetCommander[${Member.Value.ID}]
				}
			}
			while ${Member:Next(exists)}

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
		UIElement[FleetSelection@Settings@ComBotTab@ComBot].ItemByText[${Config.Fleets.Active}]:Select
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
		Config.Fleets.GetFleet[${Config.Fleets.Active}].Wings:GetSetIterator[Wing]
		if ${Wing:First(exists)}
			do
			{
				if !${This.WingExists[${Wing.Value}]}
				{
					return TRUE
				}
			}
			while ${Wing:Next(exists)}		

		return FALSE
	}
	
	member:bool WingExists(int64 value)
	{
		variable iterator Wing
		Config.Fleets.GetFleet[${Config.Fleets.Active}].Wings:GetSetIterator[Wing]
		echo Check for already in Translation table
		if ${Wing:First(exists)}
			do
			{
				echo ${WingTranslation.Element[${Wing.Value}](exists)}
				if ${WingTranslation.Element[${Wing.Value}](exists)}
				{
					echo ${WingTranslation.Element[${Wing.Value}].Value} == ${value}
					if ${WingTranslation.Element[${Wing.Value}].Value} == ${value}
					{
						return TRUE
					}
				}
			}
			while ${Wing:Next(exists)}	
		echo Add to free spot in Translation table
		if ${Wing:First(exists)}
			do
			{
				echo ${WingTranslation.Element[${Wing.Value}](exists)}
				if ${WingTranslation.Element[${Wing.Value}](exists)}
				{
					WingTranslation.Set[${Wing.Value}, ${value}]
				}
			}
			while ${Wing:Next(exists)}
			
		Me.Fleet:CreateWing
		return FALSE
	}
	
	member:int64 FindWing(string name)
	{
		variable index:int64 Wings
		variable iterator Wing
		Me.Fleet:GetWings[Wings]
		Wings:GetIterator[Wing]
		if ${Wing:First(exists)}
			do
			{
				if ${Me.Fleet.WingName[${Wing.Value.ID}].Equal[${name}]}
				{
					return ${Wing.Value.ID}
				}
			
			}
			while ${Wing:Next(exists)}
		return 0
	}
	
	member:int64 FindSquad(string name, int64 WingID)
	{
		variable index:int64 Squads
		variable iterator Squad
		Me.Fleet:GetSquads[Squads]
		Squads:GetIterator[Squad]
		if ${Squad:First(exists)}
			do
			{
				if ${Me.Fleet.SquadName[${Squad.Value.ID}].Equal[${name}]}
				{
					return ${Squad.Value.ID}
				}
			
			}
			while ${Squad:Next(exists)}
		return 0
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
	
}