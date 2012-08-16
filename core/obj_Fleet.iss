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
	
	
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		
		;This:QueueState["Start"]
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
		
		if ${ActiveCommander} && !${Me.Fleet.Member[${ActiveCommander}](exists)}
		{
			Me.Fleet:LeaveFleet
		}
		
		
		
		if ${Me.ID} == ${ActiveCommander}
		{
			if ${InviteFleetMembers}
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

		if !${Me.Fleet.IsMember[${Me.CharID}]}
		{
			This:QueueState["InFleet"]
			return TRUE
		}
		
		if ${Me.ID} == ${ActiveCommander}
		{
			if ${InviteFleetMembers}
			{
				return FALSE
			}
		}

		if ${Me.Fleet.Invited}
		{
			if ${Me.Fleet.InvitationText.Find[${ResolveName[${ActiveCommander}]}]}
			{
				Me.Fleet:AcceptInvite
				return FALSE
			}
		}
		
		return FALSE
	}

	method SaveFleet(string name)
	{
		variable index:fleetmember Members
		variable iterator Member
		
		
		Me.Fleet:GetMembers[Members]
		Members:GetIterator[Member]
		if ${Member:First(exists)}
			do
			{
				Config.Fleet.GetFleet[${name}].GetWing[${Me.Fleet.WingName[${Member.Value.WingID}]}].GetSquad[${Me.Fleet.SquadName[${Member.Value.SquadID}]}].GetMember[${Member.Value.ToPilot.Name}]:SetID[${Member.Value.ID}]
			}
			while ${Member:Next(exists)}
		
	}
	



	
	member:int64 ActiveCommander()
	{
		if ${Config.Fleets.GetFleet[${Config.Fleets.Active}].Commander} > 0
		{
			return ${Config.Fleets.GetFleet[${Config.Fleets.Active}].Commander}
		}
		variable iterator Wing
		Config.Fleets.GetFleet[${Config.Fleets.Active}].Wings:GetIterator[Wing]
		if ${Wing:First(exists)}
		{
			if ${Wing.Value.Commander} > 0
			{
				return ${Wing.Value.Commander}
			}
			variable iterator Squad
			Wing.Value.Squads:GetIterator[Squad]
			if ${Squad:First(exists)}
			{
				if ${Squad.Value.Commander} > 0
				{
					return ${Squad.Value.Commander}
				}
			}
		}
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
	
	member:bool ArrangeFleet()
	{
		variable set:string WingNames
		variable set:string SquadNames
	
		variable iterator ConfigWing
		variable iterator ConfigSquad

		
		Config.Fleets.GetFleet[${Config.Fleets.Active}].Wings:GetIterator[ConfigWing]
		if ${ConfigWing:First(exists)}
			do
			{
				if ${FindWing[${ConfigWing.Value.Name}]}
				{
				}
			
				ConfigWing.Value.Squads:GetIterator[ConfigSquad]
				if ${ConfigSquad:First(exists)}
					do
					{

					}
					while ${ConfigSquad:Next(exists)}
			}
			while ${ConfigWing:Next(exists)}
		
	
			
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
		Config.Fleets.GetFleet[${Config.Fleets.Active}].Wings:GetIterator[Wing]
		if ${Wing:First(exists)}
			do
			{
				if ${InviteToFleet[${Wing.Value.Commander}]}
					return TRUE
					
				variable iterator Squad
				Wing.Value.Squads:GetIterator[Squad]
				if ${Squad:First(exists)}
					do
					{
						if ${InviteToFleet[${Squad.Value.Commander}]}
							return TRUE
						
						variable iterator Member
						Squad.Value.Members:GetIterator[Member]
						if ${Member:First(exists)}
							do
							{
								if ${InviteToFleet[${Member.Value.ID}]}
									return TRUE
							}
							while ${Squad:Next(exists)}
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