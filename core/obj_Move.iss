objectdef obj_WarpDestination
{
	variable int Distance
	variable string Bookmark
	variable int AgentID

	method Initialize(int arg_Distance, string arg_Bookmark, int arg_Agent=0)
	{
		Distance:Set[${arg_Distance}]	
		Bookmark:Set[${arg_Bookmark}]	
		AgentID:Set[${arg_Agent}]	
	}
	
	method Set(int arg_Distance, string arg_Bookmark, int arg_Agent=0)
	{
		Distance:Set[${arg_Distance}]	
		Bookmark:Set[${arg_Bookmark}]	
		AgentID:Set[${arg_Agent}]
		
	}
}


objectdef obj_Move inherits obj_State
{

	variable bool Approaching=FALSE
	variable int64 ApproachingID
	variable int ApproachingDistance
	variable int TimeStartedApproaching = 0


	variable bool Traveling=FALSE
	
	variable obj_WarpDestination WarpDestination
	variable int64 TargetGate = -1


	method Initialize()
	{
		This[parent]:Initialize
		UI:Update["obj_Move", "Initialized", "g"]
	}



	
	
	method Warp(int64 ID, int Distance)
	{
		Entity[${ID}]:WarpTo[${Distance}]
		Client:Wait[5000]
	}
	
	method ActivateAutoPilot()
	{
		if !${Me.AutoPilotOn}
		{
			UI:Update["obj_Move", "Activating autopilot", "g"]
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
			UI:Update["obj_Move", "Setting destination to ${Universe[${DestinationSystemID}].Name}", "g"]
			Universe[${DestinationSystemID}]:SetDestination
			return
		}
		
		This:ActivateAutoPilot
	}

	method DockAtStation(int64 StationID)
	{
		if ${Entity[${StationID}](exists)}
		{
			UI:Update["obj_Move", "Docking: ${Entity[${StationID}].Name}", "g"]
			Entity[${StationID}]:Dock
			Client:Wait[10000]
		}
		else
		{
			UI:Update["obj_Move", "Station Requested does not exist.  StationID: ${StationID}", "r"]
		}
	}	
	
	method Undock()
	{
			EVE:Execute[CmdExitStation]
			Client:Wait[10000]
	}	
	
	
	
	
	
	
	method Bookmark(string DestinationBookmarkLabel, int Distance=0)
	{
		if ${This.Traveling}
		{
			return
		}
		
		if !${EVE.Bookmark[${DestinationBookmarkLabel}](exists)}
		{
			UI:Update["obj_Move", "Attempted to travel to a bookmark which does not exist", "r"]
			UI:Update["obj_Move", "Bookmark label: ${DestinationBookmarkLabel}", "r"]
			return
		}

		UI:Update["obj_Move", "Movement queued.  Destination: ${DestinationBookmarkLabel}", "g"]
		This.WarpDestination:Set[${Distance}, ${DestinationBookmarkLabel}]
		This.Traveling:Set[TRUE]
		This:QueueState["BookmarkMove"]
	}

	method AgentName(string AgentName)
	{
		if ${This.Traveling}
		{
			return
		}
		
		if !${Agent[${AgentName}](exists)}
		{
			UI:Update["obj_Move", "Attempted to travel to an agent which does not exist", "r"]
			UI:Update["obj_Move", "Agent name: ${AgentName}", "r"]
			return
		}

		UI:Update["obj_Move", "Movement queued.  Destination: ${AgentName}", "g"]
		This.WarpDestination:Set[0, "", ${Agent[AgentName].Index}]
		This.Traveling:Set[TRUE]
		This:QueueState["AgentMove"]
	}	

	method Gate(int64 ID)
	{
		UI:Update["obj_Move", "Movement queued.  Destination: ${Entity[${ID}].Name}", "g"]
		TargetGate:Set[${ID}]
		This.Traveling:Set[TRUE]
		This:QueueState["GateMove"]
	}

	member:bool GateMove()
	{
		echo GATEMOVE
		if !${This.CheckApproach}
		{
			return FALSE
		}
		if ${Entity[${TargetGate}].Distance} > 3000
		{
			This:Approach[${TargetGate}, 3000]
			return FALSE
		}
		Entity[${TargetGate}]:Activate
		Client:Wait[5000]
		This.Traveling:Set[FALSE]
		return TRUE
	}
	
	
	member:bool BookmarkMove()
	{

		if ${Me.InStation}
		{
			if ${Me.StationID} == ${EVE.Bookmark[${This.WarpDestination.Bookmark}].ItemID}
			{
				UI:Update["obj_Move", "Docked at ${This.WarpDestination.Bookmark}", "g"]
				This.Traveling:Set[FALSE]
				return TRUE
			}
			else
			{
				UI:Update["obj_Move", "Undocking from ${Me.Station.Name}", "g"]
				This:Undock
				return FALSE
			}
		}

		if ${Me.ToEntity.Mode} == 3 || !${Client.InSpace}
		{
			return FALSE
		}
		
		if  ${EVE.Bookmark[${This.WarpDestination.Bookmark}].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:TravelToSystem[${EVE.Bookmark[${This.WarpDestination.Bookmark}].SolarSystemID}]
			return FALSE
		}
		
		if ${EVE.Bookmark[${This.WarpDestination.Bookmark}].ItemID} == -1
		{
			if ${EVE.Bookmark[${This.WarpDestination.Bookmark}].Distance} > WARP_RANGE
			{
				if ${Entity[GroupID == GROUP_WARPGATE](exists)}
				{
					UI:Update["obj_Move", "Gate found, activating", "g"]
					This:Clear
					This:Gate[${Entity[GroupID == GROUP_WARPGATE].ID}]
				}			
				
				UI:Update["obj_Move", "Warping to ${This.WarpDestination.Bookmark}", "g"]
				EVE.Bookmark[${This.WarpDestination.Bookmark}]:WarpTo[${This.WarpDestination.Distance}]
				Client:Wait[5000]
				return FALSE
			}
			else
			{
				UI:Update["obj_Move", "Reached ${This.WarpDestination.Bookmark}", "g"]
				This.Traveling:Set[FALSE]
				return TRUE
			}
		}
		else
		{
			if ${EVE.Bookmark[${This.WarpDestination.Bookmark}].ToEntity(exists)}
			{
				if ${EVE.Bookmark[${This.WarpDestination.Bookmark}].ToEntity.Distance} > WARP_RANGE
				{
					UI:Update["obj_Move", "Warping to ${This.WarpDestination.Bookmark}", "g"]
					This:Warp[${EVE.Bookmark[${This.WarpDestination.Bookmark}].ToEntity}, ${This.WarpDestination.Distance}]
					return FALSE
				}
				else
				{
					UI:Update["obj_Move", "Reached ${This.WarpDestination.Bookmark}, docking", "g"]
					This:DockAtStation[${EVE.Bookmark[${This.WarpDestination.Bookmark}].ItemID}]
					return FALSE
				}
			}
			else
			{
				if ${EVE.Bookmark[${This.WarpDestination.Bookmark}].Distance} > WARP_RANGE
				{
					UI:Update["obj_Move", "Warping to ${This.WarpDestination.Bookmark}", "g"]
					EVE.Bookmark[${This.WarpDestination.Bookmark}]:WarpTo[${This.WarpDestination.Distance}]
					Client:Wait[5000]
					return FALSE
				}
				else
				{
					UI:Update["obj_Move", "Reached ${This.WarpDestination.Bookmark}", "g"]
					This.Traveling:Set[FALSE]
					return TRUE
				}
			}
		}
	}
	

	member:bool AgentMove()
	{

		if ${Me.InStation}
		{
			if ${Me.StationID} == ${Agent[${This.WarpDestination.AgentID}].StationID}
			{
				UI:Update["obj_Move", "Docked at ${Agent[${This.WarpDestination.AgentID}].Station}", "g"]
				This.Traveling:Set[FALSE]
				return TRUE
			}
			else
			{
				UI:Update["obj_Move", "Undocking from ${Me.Station.Name}", "g"]
				This:Undock
				return FALSE
			}
		}

		if ${Me.ToEntity.Mode} == 3 || !${Client.InSpace}
		{
			return FALSE
		}
			
		if  ${Agent[${This.WarpDestination.AgentID}].SolarSystem.ID} != ${Me.SolarSystemID}
		{
			This:TravelToSystem[${Agent[${This.WarpDestination.AgentID}].SolarSystem.ID}]
			return FALSE
		}
		
		if ${Entity[${Agent[${This.WarpDestination.AgentID}].StationID}](exists)}
		{
			if ${Entity[${Agent[${This.WarpDestination.AgentID}].StationID}].Distance} > WARP_RANGE
			{
				UI:Update["obj_Move", "Warping to ${Agent[${This.WarpDestination.AgentID}].Station}", "g"]
				This:Warp[${Agent[${This.WarpDestination.AgentID}].StationID}]
				return FALSE
			}
			else
			{
				UI:Update["obj_Move", "Reached ${Agent[${This.WarpDestination.AgentID}].Station}, docking", "g"]
				This:DockAtStation[${Agent[${This.WarpDestination.AgentID}].StationID}]
				This.Traveling:Set[FALSE]
				return TRUE
			}
		}
	}

	
	
	method Approach(int64 target, int distance=0)
	{
		echo APPROACH - ${target} == ${This.ApproachingID} && ${This.Approaching}
		;	If we're already approaching the target, ignore the request
		if ${target} == ${This.ApproachingID} && ${This.Approaching}
		{
			return
		}
		echo AFTER
		if !${Entity[${target}](exists)}
		{
			UI:Update["obj_Move", "Attempted to approach a target that does not exist", "r"]
			UI:Update["obj_Move", "Target ID: ${target}", "r"]
			return
		}
		echo EVEN AFTER
		if ${Entity[${target}].Distance} <= ${distance}
		{
			return
		}

		This.ApproachingID:Set[${target}]
		This.ApproachingDistance:Set[${distance}]
		This.TimeStartedApproaching:Set[-1]
		This.Approaching:Set[TRUE]
		This:QueueState["CheckApproach"]
	}
	
	
	member:bool CheckApproach()
	{
		;	Clear approach if we're in warp or the entity no longer exists
		if ${Me.ToEntity.Mode} == 3 || !${Entity[${This.ApproachingID}](exists)}
		{
			This.Approaching:Set[FALSE]
			return TRUE
		}			
		
		;	Find out if we need to warp to the target
		if ${Entity[${This.ApproachingID}].Distance} > WARP_RANGE 
		{
			UI:Update["obj_Move", "${Entity[${This.ApproachingID}].Name} is a long way away.  Warping to it", "g"]
			This:Warp[${This.ApproachingID}]
			return FALSE
		}
		
		;	Find out if we need to approach the target
		if ${Entity[${This.ApproachingID}].Distance} > ${This.ApproachingDistance} && ${This.TimeStartedApproaching} == -1
		{
			UI:Update["obj_Move", "Approaching to within ${ComBot.MetersToKM_Str[${distance}]} of ${Entity[${This.ApproachingID}].Name}", "g"]
			Entity[${This.ApproachingID}]:Approach[${distance}]
			This.TimeStartedApproaching:Set[${Time.Timestamp}]
			return FALSE
		}
		
		;	If we've been approaching for more than 1 minute, we need to give up
		if ${Math.Calc[${This.TimeStartedApproaching}-${Time.Timestamp}]} < -60
		{
			This.Approaching:Set[FALSE]
			return TRUE
		}
		
		;	If we're approaching a target, find out if we need to stop doing so 
		if ${Entity[${This.ApproachingID}].Distance} <= ${This.ApproachingDistance}
		{
			UI:Update["obj_Move", "Within ${ComBot.MetersToKM_Str[${This.ApproachingDistance}]} of ${Entity[${This.ApproachingID}].Name}", "g"]
			EVE:Execute[CmdStopShip]
			This.Approaching:Set[FALSE]
			return TRUE
		}
		return FALSE
	}

}
	
	
	
objectdef obj_InstaWarp inherits obj_State
{
	variable bool InstaWarp_Cooldown=FALSE

	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		UI:Update["obj_InstaWarp", "Initialized", "g"]
		This:QueueState["InstaWarp_Check"]
	}
	
	member:bool InstaWarp_Check()
	{
		if !${Client.InSpace}
		{
			return FALSE
		}
		if ${Me.ToEntity.Mode} == 3 && ${InstaWarp_Cooldown} && ${Ship.AfterBurner_Active}
		{
			Ship:Deactivate_AfterBurner
			return FALSE
		}
		if ${Me.ToEntity.Mode} == 3 && !${InstaWarp_Cooldown}
		{
			Ship:Activate_AfterBurner
			InstaWarp_Cooldown:Set[TRUE]
			return FALSE
		}
		if ${Me.ToEntity.Mode} != 3
		{
			InstaWarp_Cooldown:Set[FALSE]
			return FALSE
		}
	}
}