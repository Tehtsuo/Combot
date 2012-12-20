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

objectdef obj_Move inherits obj_State
{
	variable obj_Approach ApproachModule

	variable bool Traveling=FALSE
	
	
	variable string SavedSpot = ""

	method Initialize()
	{
		This[parent]:Initialize
	}



	
	
	method Warp(int64 ID, int Dist=0, bool FleetWarp=FALSE)
	{
		if ${Me.Fleet.IsMember[${Me.CharID}]}
		{
			if 	(${Me.ToFleetMember.IsFleetCommander} ||\
				${Me.ToFleetMember.IsWingCommander} ||\
				${Me.ToFleetMember.IsSquadCommander}) &&\
				${FleetWarp}
			{	
				Entity[${ID}]:WarpFleetTo[${Dist}]
			}
			else
			{
				Entity[${ID}]:WarpTo[${Dist}]
			}
		}
		else
		{
			Entity[${ID}]:WarpTo[${Dist}]
		}
		Client:Wait[5000]
	}
	
	method ActivateAutoPilot()
	{
		if !${Me.AutoPilotOn}
		{
			UI:Update["Move", "Activating autopilot", "o"]
			EVE:Execute[CmdToggleAutopilot]
		}
	}

	method TravelToSystem(int64 DestinationSystemID)
	{
		if ${Me.ToEntity.Mode} == 3 || ${DestinationSystemID.Equal[${Me.SolarSystemID}]} || ${Me.AutoPilotOn}
		{
			return
		}

		variable index:int DestinationList
		EVE:GetWaypoints[DestinationList]
		
		if ${DestinationList[${DestinationList.Used}]} != ${DestinationSystemID}
		{
			UI:Update["Move", "Setting destination", "o", TRUE]
			UI:Update["Move", " ${Universe[${DestinationSystemID}].Name}", "-g", TRUE]
			UI:Log["Redacted:  obj_Move - Setting destination to XXXXXXX (SystemID)"]
			Universe[${DestinationSystemID}]:SetDestination
			return
		}
		
		This:ActivateAutoPilot
	}

	method TravelToStation(int64 StationID)
	{
		if ${Me.ToEntity.Mode} == 3 || ${Me.AutoPilotOn}
		{
			return
		}

		variable index:int DestinationList
		EVE:GetWaypoints[DestinationList]
		
		if ${DestinationList[${DestinationList.Used}]} != ${StationID}
		{
			UI:Update["Move", "Setting destination", "o", TRUE]
			UI:Update["Move", " ${EVE.Station[${StationID}].Name}", "-g", TRUE]
			UI:Log["Redacted:  obj_Move - Setting destination to XXXXXXX (StationID)"]
			EVE.Station[${StationID}]:SetDestination
			return
		}
		
		This:ActivateAutoPilot
	}
	
	method Undock()
	{
		EVE:Execute[CmdExitStation]
		Client:Wait[10000]
	}	

	method DockAtStation(int64 StationID)
	{
		if ${Entity[${StationID}](exists)}
		{
			UI:Update["Move", "Docking", "o", TRUE]
			UI:Update["Move", " ${Entity[${StationID}].Name}", "-g", TRUE]
			UI:Log["Redacted:  obj_Move - Docking: XXXXXXX"]
			Entity[${StationID}]:Dock
			Client:Wait[10000]
		}
		else
		{
			UI:Update["Move", "Station Requested does not exist", "r", TRUE]
			UI:Update["Move", "StationID: ${StationID}", "r", TRUE]
			UI:Log["Redacted:  obj_Move - Station Requested does not exist.  StationID: XXXXXXX"]
		}
	}	
	
	
	
	method Fleetmember(int64 ID, bool IgnoreGate=FALSE, int Distance=0)
	{
		if ${This.Traveling}
		{
			return
		}
		
		if !${Me.Fleet.Member[${ID}](exists)}
		{
			UI:Update["Move", "Fleet member does not exist", "r"]
			UI:Update["Move", "Fleet member CharID: ${ID}", "r", TRUE]
			UI:Log["Redacted:  obj_Move - Fleet member CharID: XXXXXXX"]
			return
		}

		UI:Update["Move", "Movement queued", "o", TRUE]
		UI:Update["Move", " ${Being[${ID}].Name}", "-g", TRUE]
		UI:Log["Redacted:  obj_Move - Movement queued.  Destination: XXXXXXX (Fleet Member)"]
		This.Traveling:Set[TRUE]
		This:QueueState["FleetmemberMove", 2000, "${ID}, ${IgnoreGate}, ${Distance}"]
	}

	method Bookmark(string DestinationBookmarkLabel, bool IgnoreGate=FALSE, int Distance=0, bool FleetWarp=FALSE)
	{
		if ${This.Traveling}
		{
			return
		}
		
		if !${EVE.Bookmark[${DestinationBookmarkLabel}](exists)} && !${EVE.Station[${DestinationBookmarkLabel}](exists)}
		{
			UI:Update["Move", "Attempted to travel to a bookmark which does not exist", "r"]
			UI:Update["Move", "Bookmark label: ${DestinationBookmarkLabel}", "r", TRUE]
			UI:Log["Redacted:  obj_Move - Bookmark label: XXXXXXX"]
			return
		}

		if ${EVE.Bookmark[${DestinationBookmarkLabel}](exists)}
		{
			UI:Update["Move", "Movement queued", "o", TRUE]
			UI:Update["Move", " ${DestinationBookmarkLabel}", "-g", TRUE]
		}
		if ${EVE.Station[${DestinationBookmarkLabel}](exists)}
		{
			UI:Update["Move", "Movement queued", "o", TRUE]
			UI:Update["Move", " ${EVE.Station[${DestinationBookmarkLabel}].Name}", "-g", TRUE]
		}
		UI:Log["Redacted:  obj_Move - Movement queued.  Destination: XXXXXXX (Bookmark)"]
		This.Traveling:Set[TRUE]
		This:QueueState["BookmarkMove", 2000, "${DestinationBookmarkLabel}, ${IgnoreGate}, ${Distance}, ${FleetWarp}"]
	}

	method System(string SystemID)
	{
		if ${This.Traveling}
		{
			return
		}
		
		if !${Universe[${SystemID}](exists)}
		{
			UI:Update["Move", "Attempted to travel to a system which does not exist", "r"]
			UI:Update["Move", "System ID: ${SystemID}", "r", TRUE]
			UI:Log["Redacted:  obj_Move - System ID: XXXXXXX"]
			return
		}

		UI:Update["Move", "Movement queued", "o", TRUE]
		UI:Update["Move", " ${Universe[${SystemID}].Name}", "-g", TRUE]
		UI:Log["Redacted:  obj_Move - Movement queued.  Destination: XXXXXXX (SystemID)"]
		This.Traveling:Set[TRUE]
		This:QueueState["SystemMove", 2000, ${SystemID}]
	}

	method Object(int64 ID, int Distance=0, bool FleetWarp=FALSE)
	{
		if ${This.Traveling}
		{
			return
		}
		
		UI:Update["Move", "Movement queued", "o", TRUE]
		UI:Update["Move", " ${Entity[${ID}].Name}", "-g", TRUE]
		UI:Log["Redacted:  obj_Move - Movement to XXXXXXX queued."]
		This.Traveling:Set[TRUE]
		This:QueueState["ObjectMove", 2000, "${ID},${Distance},${FleetWarp}"]
	}	
	
	method Agent(string AgentName)
	{
		if ${This.Traveling}
		{
			return
		}
		
		if !${Agent[${AgentName}](exists)}
		{
			UI:Update["Move", "Attempted to travel to an agent which does not exist", "r"]
			UI:Update["Move", "Agent name: ${AgentName}", "r", TRUE]
			UI:Log["Redacted:  obj_Move - Agent name: XXXXXXX"]
			return
		}

		UI:Update["Move", "Movement queued", "o", TRUE]
		UI:Update["Move", " ${AgentName}", "-g", TRUE]
		UI:Log["Redacted:  obj_Move - Movement queued.  Destination: XXXXXXX (Agent)"]
		This.Traveling:Set[TRUE]
		This:QueueState["AgentMove", 2000, ${Agent[AgentName].Index}]
	}	

	method Gate(int64 ID, bool CalledFromMove=FALSE)
	{
		UI:Update["Move", "Movement queued", "o", TRUE]
		UI:Update["Move", " ${Entity[${ID}].Name}", "-g", TRUE]
		UI:Log["Redacted:  obj_Move - Movement queued.  Destination: XXXXXXX (Gate)"]
		This.Traveling:Set[TRUE]
		This:QueueState["GateMove", 2000, "${ID}, ${CalledFromMove}"]
	}

	member:bool GateMove(int64 ID, bool CalledFromMove)
	{
		if !${Entity[${ID}](exists)}
		{
			if !${CalledFromMove}
			{
				This.Traveling:Set[FALSE]
			}
			return TRUE	
		}
		
		if ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}

		if ${Entity[${ID}].Distance} < -8000
		{
			UI:Update["Move", "Too close!  Orbiting ${Entity[${ID}].Name}", "g"]
			Entity[${ID}]:Orbit
			Client:Wait[10000]
			return FALSE
		}
		if ${Entity[${ID}].Distance} > 3000
		{
			This:Approach[${ID}, 3000]
			return FALSE
		}
		UI:Update["Move", "Activating ${Entity[${ID}].Name}", "g"]
		Entity[${ID}]:Activate
		Client:Wait[5000]
		if !${CalledFromMove}
		{
			This.Traveling:Set[FALSE]
		}
		return FALSE
	}
	
	
	member:bool FleetmemberMove(int64 ID, bool IgnoreGate=FALSE, int Distance=0)
	{
		if !${Me.Fleet.Member[${ID}].ToPilot(exists)}
		{
			UI:Update["Move", "Fleet member ${Being[${ID}].Name} is no longer in local, canceling Move", "g", TRUE]
			UI:Update["Redacted:  obj_Move - Fleet member XXXXXXX is no longer in local, canceling Move"]
			This.Traveling:Set[FALSE]
			return TRUE
		}
	
		if ${Me.InStation}
		{
			UI:Update["Move", "Undocking", "o", TRUE]
			UI:Update["Move", " ${Me.Station.Name}", "-g", TRUE]
			UI:Log["Redacted:  obj_Move - Undocking from XXXXXXX"]
			This:Undock
			return FALSE
		}

		if !${Client.InSpace}
		{
			return FALSE
		}

		if ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}

		if ${Me.Fleet.Member[${ID}].ToEntity(exists)}
		{
			if ${Me.Fleet.Member[${ID}].ToEntity.Distance} > 100000
			{
				
				UI:Update["Move", "Bounce warping", "o", TRUE]
				UI:Update["Move", " ${Entity[ID >= 40000000 && ID <= 50000000].Name}", "-g", TRUE]
				Entity[ID >= 40000000 && ID <= 50000000]:WarpTo
				Client:Wait[5000]
				return FALSE
			}
			else
			{
				UI:Update["Move", "Reached \ao${Me.Fleet.Member[${ID}].ToPilot.Name}", "g", TRUE]
				UI:Log["Redacted:  obj_Move - Reached XXXXXXX (FleetMember)"]
				This.Traveling:Set[FALSE]
				return TRUE
			}
		}
		else
		{
				if ${Entity[GroupID == GROUP_WARPGATE](exists)} && !${IgnoreGate}
				{
					UI:Update["Move", "Gate found, activating", "g"]
					This:Gate[${Entity[GroupID == GROUP_WARPGATE].ID}, TRUE]
					This:QueueState["FleetmemberMove", 2000, ${ID}]
					return TRUE
				}
				UI:Update["Move", "Warping", "o", TRUE]
				UI:Update["Move", " ${Me.Fleet.Member[${ID}].ToPilot.Name}", "-g", TRUE]
				UI:Log["Redacted:  obj_Move - Warping to XXXXXXX (FleetMember)"]
				Me.Fleet.Member[${ID}]:WarpTo[${Distance}]
				Client:Wait[5000]
				This:QueueState["FleetmemberMove", 2000, "${ID}, FALSE, ${Distance}"]
				
				return TRUE
		}
	}

	member:bool BookmarkMove(string Bookmark, bool IgnoreGate=FALSE, int Distance=0, bool FleetWarp=FALSE)
	{

		if ${Me.InStation}
		{
			if ${EVE.Bookmark[${Bookmark}](exists)}
			{
				if ${Me.StationID} == ${EVE.Bookmark[${Bookmark}].ItemID}
				{
					UI:Update["Move", "Docked", "o", TRUE]
					UI:Update["Move", " ${Bookmark}", "-g", TRUE]
					UI:Log["Redacted:  obj_Move - Docked at XXXXXXX"]
					This.Traveling:Set[FALSE]
					return TRUE
				}
				else
				{
					UI:Update["Move", "Undocking", "o", TRUE]
					UI:Update["Move", " ${Me.Station.Name}", "-g", TRUE]
					UI:Log["Redacted:  obj_Move - Undocking from XXXXXXX"]
					This:Undock
					return FALSE
				}
			}
			if ${EVE.Station[${Bookmark}](exists)}
			{
				if ${Me.StationID} == ${Bookmark}
				{
					UI:Update["Move", "Docked", "o", TRUE]
					UI:Update["Move", " ${EVE.Station[${Bookmark}].Name}", "-g", TRUE]
					UI:Log["Redacted:  obj_Move - Docked at XXXXXXX"]
					This.Traveling:Set[FALSE]
					return TRUE
				}
				else
				{
					UI:Update["Move", "Undocking", "o", TRUE]
					UI:Update["Move", " ${Me.Station.Name}", "-g", TRUE]
					UI:Log["Redacted:  obj_Move - Undocking from XXXXXXX"]
					This:Undock
					return FALSE
				}
			}
		}

		if !${Client.InSpace}
		{
			return FALSE
		}

		if ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		
		if ${EVE.Bookmark[${Bookmark}](exists)}
		{
			if  ${EVE.Bookmark[${Bookmark}].SolarSystemID} != ${Me.SolarSystemID}
			{
				This:TravelToSystem[${EVE.Bookmark[${Bookmark}].SolarSystemID}]
				return FALSE
			}
		}
		if ${EVE.Station[${Bookmark}](exists)}
		{
			This:TravelToStation[${Bookmark}]
		}
		
		if ${EVE.Bookmark[${Bookmark}].ItemID} == -1
		{
			if ${EVE.Bookmark[${Bookmark}].Distance} > WARP_RANGE
			{
				if ${Entity[GroupID == GROUP_WARPGATE](exists)} && !${IgnoreGate}
				{
					UI:Update["Move", "Gate found, activating", "g"]
					This:Gate[${Entity[GroupID == GROUP_WARPGATE].ID}, TRUE]
					This:QueueState["BookmarkMove", 2000, ${Bookmark}]
					return TRUE
				}			
				
				UI:Update["Move", "Warping", "o", TRUE]
				UI:Update["Move", " ${Bookmark}", "-g", TRUE]
				UI:Log["Redacted:  obj_Move - Warping to XXXXXXX (Bookmark)"]
				if ${Me.Fleet.IsMember[${Me.CharID}]} 
				{
					if 	(${Me.ToFleetMember.IsFleetCommander} ||\
						${Me.ToFleetMember.IsWingCommander} ||\
						${Me.ToFleetMember.IsSquadCommander}) &&\
						${FleetWarp}
					{	
						EVE.Bookmark[${Bookmark}]:WarpFleetTo[${Distance}]
					}
					else
					{
						EVE.Bookmark[${Bookmark}]:WarpTo[${Distance}]
					}
				}
				else
				{
					EVE.Bookmark[${Bookmark}]:WarpTo[${Distance}]
				}
				Client:Wait[5000]
				This:QueueState["BookmarkMove", 2000, ${Bookmark}]
				return TRUE
			}
			elseif ${EVE.Bookmark[${Bookmark}].Distance} != -1 && ${EVE.Bookmark[${Bookmark}].Distance(exists)}
			{
				UI:Update["Move", "Reached", "o", TRUE]
				UI:Update["Move", " ${Bookmark}", "-g", TRUE]
				UI:Log["Redacted:  obj_Move - Reached XXXXXXX (Bookmark)"]
				This.Traveling:Set[FALSE]
				return TRUE
			}
			else
			{
				return FALSE
			}
		}
		else
		{
			if ${EVE.Bookmark[${Bookmark}].ToEntity(exists)}
			{
				if ${EVE.Bookmark[${Bookmark}].ToEntity.Distance} > WARP_RANGE
				{
					UI:Update["Move", "Warping", "o", TRUE]
					UI:Update["Move", " ${Bookmark}", "-g", TRUE]
					UI:Log["Redacted:  obj_Move - Warping to XXXXXXX (Bookmark)"]
					if ${Me.Fleet.IsMember[${Me.CharID}]} 
					{
						if 	(${Me.ToFleetMember.IsFleetCommander} ||\
							${Me.ToFleetMember.IsWingCommander} ||\
							${Me.ToFleetMember.IsSquadCommander}) &&\
							${FleetWarp}
						{	
							EVE.Bookmark[${Bookmark}].ToEntity:WarpFleetTo[${Distance}]
						}
						else
						{
							EVE.Bookmark[${Bookmark}].ToEntity:WarpTo[${Distance}]
						}
					}
					else
					{
						EVE.Bookmark[${Bookmark}].ToEntity:WarpTo[${Distance}]
					}
					return FALSE
				}
				elseif ${EVE.Bookmark[${Bookmark}].ToEntity.Distance} != -1 && ${EVE.Bookmark[${Bookmark}].ToEntity.Distance(exists)}
				{
					UI:Update["Move", "Docking", "o", TRUE]
					UI:Update["Move", " ${Bookmark}", "-g", TRUE]
					UI:Log["Redacted:  obj_Move - Reached XXXXXXX (Bookmark), docking"]
					This:DockAtStation[${EVE.Bookmark[${Bookmark}].ItemID}]
					return FALSE
				}
				else
				{
					return FALSE
				}
			}
			else
			{
				if ${EVE.Bookmark[${Bookmark}].Distance} > WARP_RANGE
				{
					UI:Update["Move", "Warping", "o", TRUE]
					UI:Update["Move", " ${Bookmark}", "-g", TRUE]
					UI:Log["Redacted:  obj_Move - Warping to XXXXXXX (Bookmark)"]
					if ${Me.Fleet.IsMember[${Me.CharID}]} 
					{
						if 	(${Me.ToFleetMember.IsFleetCommander} ||\
							${Me.ToFleetMember.IsWingCommander} ||\
							${Me.ToFleetMember.IsSquadCommander}) &&\
							${FleetWarp}
						{	
							EVE.Bookmark[${Bookmark}]:WarpFleetTo[${Distance}]
						}
						else
						{
							EVE.Bookmark[${Bookmark}]:WarpTo[${Distance}]
						}
					}
					else
					{
						EVE.Bookmark[${Bookmark}]:WarpTo[${Distance}]
					}
					Client:Wait[5000]
					return FALSE
				}
				elseif ${EVE.Bookmark[${Bookmark}].Distance} != -1 && ${EVE.Bookmark[${Bookmark}].Distance(exists)}
				{
					UI:Update["Move", "Reached", "o", TRUE]
					UI:Update["Move", " ${Bookmark}", "-g", TRUE]
					UI:Log["Redacted:  obj_Move - Reached XXXXXXX (Bookmark)"]
					This.Traveling:Set[FALSE]
					return TRUE
				}
				else
				{
					return FALSE
				}
			}
		}
	}

	member:bool AgentMove(int ID)
	{

		if ${Me.InStation}
		{
			if ${Me.StationID} == ${Agent[${ID}].StationID}
			{
				UI:Update["Move", "Docked", "o", TRUE]
				UI:Update["Move", " ${Agent[${ID}].Station}", "-g", TRUE]
				UI:Log["Redacted:  obj_Move - Docked at XXXXXXX"]
				This.Traveling:Set[FALSE]
				return TRUE
			}
			else
			{
				UI:Update["Move", "Undocking", "o", TRUE]
				UI:Update["Move", " ${Me.Station.Name}", "-g", TRUE]
				UI:Log["Redacted:  obj_Move - Undocking from XXXXXXX"]
				This:Undock
				return FALSE
			}
		}

		if ${Me.ToEntity.Mode} == 3 || !${Client.InSpace}
		{
			return FALSE
		}
			
		if  ${Agent[${ID}].SolarSystem.ID} != ${Me.SolarSystemID}
		{
			This:TravelToSystem[${Agent[${ID}].SolarSystem.ID}]
			return FALSE
		}
		
		if ${Entity[${Agent[${ID}].StationID}](exists)}
		{
			if ${Entity[${Agent[${ID}].StationID}].Distance} > WARP_RANGE
			{
				UI:Update["Move", "Warping", "o", TRUE]
				UI:Update["Move", " ${Agent[${ID}].Station}", "-g", TRUE]
				UI:Log["Redacted:  obj_Move - Warping to XXXXXXX (Agent Station)"]
				This:Warp[${Agent[${ID}].StationID}]
				return FALSE
			}
			else
			{
				UI:Update["Move", "Docking", "o", TRUE]
				UI:Update["Move", " ${Agent[${ID}].Station}", "-g", TRUE]
				UI:Log["Redacted:  obj_Move - Reached XXXXXXX (Agent Station), docking"]
				This:DockAtStation[${Agent[${ID}].StationID}]
				This.Traveling:Set[FALSE]
				return TRUE
			}
		}
	}

	member:bool SystemMove(int64 ID)
	{

		if ${Me.InStation}
		{
			if ${Me.SolarSystemID} == ${ID}
			{
				UI:Update["Move", "Reached ${Universe[${ID}].Name", "g", TRUE]
				UI:Log["Redacted:  obj_Move - Reached XXXXXXX (SystemID)"]
				This.Traveling:Set[FALSE]
				return TRUE
			}
			else
			{
				UI:Update["Move", "Undocking", "o", TRUE]
				UI:Update["Move", " ${Me.Station.Name}", "-g", TRUE]
				UI:Log["Redacted:  obj_Move - Undocking from XXXXXXX"]
				This:Undock
				return FALSE
			}
		}

		if !${Client.InSpace}
		{
			return FALSE
		}

		if ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		
		if  ${ID} != ${Me.SolarSystemID}
		{
			This:TravelToSystem[${ID}]
			return FALSE
		}
		This.Traveling:Set[FALSE]
		return TRUE
	}

	member:bool ObjectMove(int64 ID, int Distance=0, bool FleetWarp=FALSE)
	{

		if ${Me.InStation}
		{
			UI:Update["Move", "Undocking", "o", TRUE]
			UI:Update["Move", " ${Me.Station.Name}", "-g", TRUE]
			UI:Log["Redacted:  obj_Move - Undocking from XXXXXXX"]
			This:Undock
			return FALSE
		}

		if !${Client.InSpace}
		{
			return FALSE
		}

		if ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		
		if !${Entity[${ID}](exists)}
		{
			UI:Update["Move", "Attempted to warp to object ${ID} which does not exist", "r", TRUE]
			UI:Log["Redacted:  obj_Move - Attempted to warp to object XXXXXXX which does not exist"]
		}
		
		if  ${Entity[${ID}].Distance} > WARP_RANGE
		{
			This:Warp[${ID}, ${Distance}, ${FleetWarp}]
			return FALSE
		}
		
		This.Traveling:Set[FALSE]
		return TRUE
	}

	
	
	method Approach(int64 ID, int distance=0)
	{
		;	If we're already approaching the target, ignore the request
		if !${ApproachModule.IsIdle}
		{
			return
		}
		if !${Entity[${ID}](exists)}
		{
			UI:Update["Move", "Attempted to approach a target that does not exist", "r"]
			UI:Update["Move", "Target ID: ${ID}", "r", TRUE]
			UI:Log["Redacted:  obj_Move - Target ID: XXXXXXX"]
			return
		}
		if ${Entity[${ID}].Distance} <= ${distance}
		{
			return
		}

		ApproachModule:QueueState["CheckApproach", 1000, "${ID}, ${distance}"]
	}

	method SaveSpot()
	{
		UI:Update["Move", "Storing current location", "y"]
		This.SavedSpot:Set["Saved Spot ${EVETime.Time.Left[-3]}"]
		EVE:CreateBookmark["${This.SavedSpot}"]
	}
	
	member:bool SavedSpotExists()
	{
		if ${This.SavedSpot.Length} > 0
		{
			return ${EVE.Bookmark["${This.SavedSpot}"](exists)}
		}
		return FALSE
	}
	
	method RemoveSavedSpot()
	{
		if ${This.SavedSpotExists}
		{
			EVE.Bookmark["${This.SavedSpot}"]:Remove
			SavedSpot:Set[""]
		}
	}
	
	method GotoSavedSpot()
	{
		if ${This.SavedSpotExists}
		{
			This:Bookmark["${This.SavedSpot}"]
		}
	}
	
}
	
objectdef obj_Approach inherits obj_State
{

	method Initialize()
	{
		This[parent]:Initialize
		This.PulseFrequency:Set[3000]
		This.NonGameTiedPulse:Set[TRUE]
	}


	member:bool CheckApproach(int64 ID, int distance)
	{
		;	Clear approach if we're in warp or the entity no longer exists
		if ${Me.ToEntity.Mode} == 3 || !${Entity[${ID}](exists)}
		{
			return TRUE
		}			
		
		;	Find out if we need to approach the target
		if ${Entity[${ID}].Distance} > ${distance} && ${Me.ToEntity.Mode} != 1
		{
			UI:Update["Move", "Approaching to within ${ComBot.MetersToKM_Str[${distance}]} of ${Entity[${ID}].Name}", "g", TRUE]
			UI:Log["Redacted:  obj_Move - Approaching to within ${ComBot.MetersToKM_Str[${distance}]} of XXXXXXX"]
			Entity[${ID}]:Approach[${distance}]
			return FALSE
		}
		
		;	If we're approaching a target, find out if we need to stop doing so 
		if ${Entity[${ID}].Distance} <= ${distance} && ${Me.ToEntity.Mode} == 1
		{
			UI:Update["Move", "Within ${ComBot.MetersToKM_Str[${distance}]} of ${Entity[${ID}].Name}", "g", TRUE]
			UI:Log["Redacted:  obj_Move - Within ${ComBot.MetersToKM_Str[${distance}]} of XXXXXXX"]
			EVE:Execute[CmdStopShip]
			Ship.ModuleList_AB_MWD:Deactivate
			return TRUE
		}
		
		return FALSE
	}
}