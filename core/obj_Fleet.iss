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
	}

	
	
	method Process()
	{
		;	Step 1 - Accept fleet invites from my leader
		if ${Me.Fleet.Invited}
		{
			if ${Me.Fleet.InvitationText.Find[${Config.Fleet.FleetLeader}]}
			{
				Me.Fleet:AcceptInvite
			}
		}

		;	Step 2 - Send fleet invites if I'm leader
		if ${Config.Fleet.IsLeader}
		{
			Config.Fleet:RefreshFleetMembers
			variable iterator InfoFromSettings
			Config.Fleet.FleetMembers:GetIterator[InfoFromSettings]
			
			if ${InfoFromSettings:First(exists)}
				do
				{
					if !${Me.Fleet.IsMember[${This.ResolveCharID[${InfoFromSettings.Value.FleetMemberName}]}]}
					{
						This:InviteToFleet[${This.ResolveCharID[${InfoFromSettings.Value.FleetMemberName}]}]
					}
					else
					{
						variable index:int64 Wings
						variable index:int64 Squads
						variable int64 OtherWing
						variable int64 OtherSquad
						variable iterator Wing
						Me.Fleet:GetWings[Wings]
						if ${Wings.Used} == 1
						{
							Me.Fleet:CreateWing
							return
						}
						Me.Fleet:GetWings[Wings]
						Wings:GetIterator[Wing]
						if ${Wing:First(exists)}
							do
							{
								if ${Wing.Value} != ${Me.Fleet.Member[${Me.CharID}].WingID}
								{
									OtherWing:Set[${Wing.Value}]
									Me.Fleet:GetSquads[Squads, ${Wing.Value}]
									OtherSquad:Set[${Squads[1]}]
								}
							}
							while ${Wing:Next(exists)}

						if ${Config.Fleet.IsWing[${InfoFromSettings.Value.FleetMemberName}]}
						{
							if ${Me.Fleet.Member[${Me.CharID}].WingID} == ${Me.Fleet.Member[${This.ResolveCharID[${InfoFromSettings.Value.FleetMemberName}]}].WingID}
							{
								Me.Fleet.Member[${This.ResolveCharID[${InfoFromSettings.Value.FleetMemberName}]}]:Move[${OtherWing}, ${OtherSquad}]
							}
							
						}
						else
						{
							if ${Me.Fleet.Member[${Me.CharID}].WingID} != ${Me.Fleet.Member[${This.ResolveCharID[${InfoFromSettings.Value.FleetMemberName}]}].WingID}
							{
								Me.Fleet.Member[${This.ResolveCharID[${InfoFromSettings.Value.FleetMemberName}]}]:Move[${Me.Fleet.Member[${Me.CharID}].WingID}, ${Me.Fleet.Member[${Me.CharID}].SquadID}]
							}
						}
					}
				}
				while ${InfoFromSettings:Next(exists)}
		}
		else
		{
			if ${Me.Fleet.IsMember[${Me.CharID}]}
			{
				if !${Me.Fleet.IsMember[${This.ResolveCharID[${Config.Fleet.FleetLeader}]}]}
					{
					Me.Fleet:LeaveFleet
					}
			}
		}
		
				
	}
	
	member:int64 ResolveCharID(string value)
	{
		variable index:pilot CorpMembers
		variable iterator CorpMember

		EVE:GetOnlineCorpMembers[CorpMembers]
		CorpMembers:GetIterator[CorpMember]
		if ${CorpMember:First(exists)}
			do
			{
				if ${CorpMember.Value.Name.Equal[${value}]} && ${CorpMember.Value.IsOnline}
					return ${CorpMember.Value.CharID}
			}
			while ${CorpMember:Next(exists)}

		variable index:being Buddies
		variable iterator Buddy

		EVE:GetBuddies[Buddies]
		Buddies:GetIterator[Buddy]
		if ${Buddy:First(exists)}
			do
			{
				if ${Buddy.Value.Name.Equal[${value}]} && ${Buddy.Value.IsOnline}
					return ${Buddy.Value.CharID}
			}
			while ${Buddy:Next(exists)}

		variable index:pilot LocalPilots
		variable iterator LocalPilot

		EVE:GetLocalPilots[LocalPilots]
		LocalPilots:GetIterator[LocalPilot]
		if ${LocalPilot:First(exists)}
			do
			{
				if ${LocalPilot.Value.Name.Equal[${value}]}
					return ${LocalPilot.Value.CharID}
			}
			while ${LocalPilot:Next(exists)}
			

		return 0
	}
	
	method InviteToFleet(int64 value)
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
					CorpMember.Value:InviteToFleet
					return
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
					return
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
					return
				}
			}
			while ${LocalPilot:Next(exists)}
		
	}
	
}