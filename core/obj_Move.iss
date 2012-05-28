objectdef obj_WarpDestination
{
	variable string WarpType
	variable string BookmarkMoveLabel

	method Initialize(string arg_WarpType, string arg_BookmarkMoveLabel="")
	{
		WarpType:Set[${arg_WarpType}]
		BookmarkMoveLabel:Set[${arg_BookmarkMoveLabel}]	
	}
}


objectdef obj_Move
{
	variable int NextPulse
	variable int PulseIntervalInMilliseconds = 2000
	
	variable bool Approaching=FALSE
	variable int64 ApproachingID
	variable int ApproachingDistance
	variable int TimeStartedApproaching = 0

	variable bool InWarp_Cooldown=FALSE

	variable bool Traveling=FALSE
	
	variable obj_WarpDestination WarpDestination


	method Initialize()
	{
		Event[ISXEVE_onFrame]:AttachAtom[This:Pulse]
		UI:Update["obj_Move: Initialized", "g"]
	}

	method Shutdown()
	{
		Event[ISXEVE_onFrame]:DetachAtom[This:Pulse]
	}	

	method Pulse()
	{
	    if ${LavishScript.RunningTime} >= ${This.NextPulse}
		{
    		This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${PulseIntervalInMilliseconds} + ${Math.Rand[500]}]}]

			This:InWarp_Check

			if ${CommandQueue.Queued} == 0 && ${Game.Ready} && !${ComBot.Paused}
			{
				This:Travel
				This:CheckApproach
			}
		}
	}	

	
	
	
	method Warp(int64 ID)
	{
		Entity[${ID}]:WarpTo
		Game:Wait[5000]
	}
	
	method ActivateAutoPilot()
	{
		if !${Me.AutoPilotOn}
		{
			UI:Update["Activating autopilot", "g"]
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
			UI:Update["Setting destination to ${Universe[${DestinationSystemID}].Name}", "g"]
			Universe[${DestinationSystemID}]:SetDestination
			return
		}
		
		This:ActivateAutoPilot
	}

	method DockAtStation(int64 StationID)
	{
		if ${Entity[${StationID}](exists)}
		{
			UI:Update["Docking: ${Entity[${StationID}].Name}", "g"]
			Entity[${StationID}]:Dock
			Game:Wait[10000]
		}
		else
		{
			UI:Update["Station Requested does not exist.  StationID: ${StationID}", "r"]
		}
	}	
	
	method Undock()
	{
			EVE:Execute[CmdExitStation]
			Game:Wait[10000]
	}	
	
	
	
	
	
	
	method Bookmark(string DestinationBookmarkLabel)
	{
		${This.Traveling}
		{
			return
		}
		
		if !${EVE.Bookmark[${DestinationBookmarkLabel}](exists)}
		{
			UI:Update["Attempted to travel to a bookmark which does not exist", "r"]
			UI:Update["Bookmark label: ${DestinationBookmarkLabel}", "r"]
			return
		}

		UI:Update["Movement queued.  Destination: ${DestinationBookmarkLabel}", "g"]
		This.WarpDestination:Set[BOOKMARK, ${DestinationBookmarkLabel}]
		This.Traveling:Set[TRUE]
	}

	method Travel()
	{
		if !${This.Traveling}
		{
			return
		}
		
		switch ${This.WarpDestination.WarpType}
		{
			case BOOKMARK
				This:BookmarkMove
				break
		}
	}
	
	method BookmarkMove()
	{

		if ${Me.InStation}
		{
			if ${Me.StationID} == ${EVE.Bookmark[${This.WarpDestination.BookmarkMoveLabel}].ItemID}
			{
				UI:Update["Docked at ${This.WarpDestination.BookmarkMoveLabel}", "g"]
				This.Traveling:Set[FALSE]
			}
			else
			{
				UI:Update["Undocking from ${Me.Station.Name}", "g"]
				This:Undock
			}
			return
		}

		if ${Me.ToEntity.Mode} == 3 || !${Me.InSpace}
		{
			return
		}
		
		
		if  ${EVE.Bookmark[${This.WarpDestination.BookmarkMoveLabel}].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:TravelToSystem[${EVE.Bookmark[${This.WarpDestination.BookmarkMoveLabel}].SolarSystemID}]
			return
		}
		
		
		if ${EVE.Bookmark[${This.WarpDestination.DestinationBookmarkLabel}].ItemID} == -1
		{
			if ${EVE.Bookmark[${This.WarpDestination.BookmarkMoveLabel}].Distance} > WARP_RANGE
			{
				UI:Update["Warping to ${This.WarpDestination.BookmarkMoveLabel}", "g"]
				This:Warp[${EVE.Bookmark[${This.WarpDestination.BookmarkMoveLabel}].ID}]
			}
			else
			{
				UI:Update["Reached ${This.WarpDestination.BookmarkMoveLabel}", "g"]
				This.Traveling:Set[FALSE]
			}
			return
		}
		else
		{
			if ${EVE.Bookmark[${This.WarpDestination.BookmarkMoveLabel}].ToEntity(exists)}
			{
				if ${EVE.Bookmark[${This.WarpDestination.BookmarkMoveLabel}].ToEntity.Distance} > WARP_RANGE
				{
					UI:Update["Warping to ${This.WarpDestination.BookmarkMoveLabel}", "g"]
					This:Warp[${EVE.Bookmark[${This.WarpDestination.BookmarkMoveLabel}].ToEntity}]
				}
				else
				{
					UI:Update["Reached ${This.WarpDestination.BookmarkMoveLabel}, docking", "g"]
					This:DockAtStation[${EVE.Bookmark[${This.WarpDestination.BookmarkMoveLabel}].ItemID}]
				}
				return
			}
			else
			{
				if ${EVE.Bookmark[${This.WarpDestination.BookmarkMoveLabel}].Distance} > WARP_RANGE
				{
					UI:Update["Warping to ${This.WarpDestination.BookmarkMoveLabel}", "g"]
					EVE.Bookmark[${This.WarpDestination.BookmarkMoveLabel}]:WarpTo
					Game:Wait[5000]
				}
				else
				{
					UI:Update["Reached ${This.WarpDestination.BookmarkMoveLabel}", "g"]
					This.Traveling:Set[FALSE]
				}
				return
			}
		}
	}
	


	
	
	method Approach(int64 target, int distance=0)
	{
		;	If we're already approaching the target, ignore the request
		if ${target} == ${This.ApproachingID} && ${This.Approaching}
		{
			return
		}
		
		if !${Entity[${target}](exists)}
		{
			UI:Update["Attempted to approach a target that does not exist.  Target ID: ${target}", "r"]
			return
		}
		
		if ${Entity[${target}].Distance} <= ${distance}
		{
			return
		}

		This.ApproachingID:Set[${target}]
		This.ApproachingDistance:Set[${distance}]
		This.TimeStartedApproaching:Set[-1]
		This.Approaching:Set[TRUE]
	}
	
	
	
	method CheckApproach()
	{
		;	Return immediately if we're not approaching
		if !${This.Approaching} || !${Me.InSpace}
		{
			return
		}
		
		
		;	Clear approach if we're in warp or the entity no longer exists
		if ${Me.ToEntity.Mode} == 3 || !${Entity[${This.ApproachingID}](exists)}
		{
			This.Approaching:Set[FALSE]
			return
		}			
		
		;	Find out if we need to warp to the target
		if ${Entity[${This.ApproachingID}].Distance} > WARP_RANGE 
		{
			UI:Update["${Entity[${This.ApproachingID}].Name} is a long way away.  Warping to it", "g"]
			Entity[${This.ApproachingID}]:WarpTo[1000]
			return
		}
		
		;	Find out if we need to approach the target
		if ${Entity[${This.ApproachingID}].Distance} > ${This.ApproachingDistance} && ${This.TimeStartedApproaching} == -1
		{
			UI:Update["Approaching to within ${ComBot.MetersToKM_Str[${distance}]} of ${Entity[${target}].Name}", "g"]
			Entity[${This.ApproachingID}]:Approach[${distance}]
			This.TimeStartedApproaching:Set[${Time.Timestamp}]
			return
		}
		
		;	If we've been approaching for more than 1 minute, we need to give up
		if ${Math.Calc[${This.TimeStartedApproaching}-${Time.Timestamp}]} < -60
		{
			This.Approaching:Set[FALSE]
			return
		}
		
		;	If we're approaching a target, find out if we need to stop doing so 
		if ${Entity[${This.ApproachingID}].Distance} <= ${This.ApproachingDistance}
		{
			UI:Update["Within ${EVEBot.MetersToKM_Str[${This.ApproachingDistance}]} of ${Entity[${This.ApproachingID}].Name}", "g"]
			EVE:Execute[CmdStopShip]
			This.Approaching:Set[FALSE]
			return
		}
	}

	method InWarp_Check()
	{
		if !${Me.InSpace}
		{
			return
		}
		if ${Me.ToEntity.Mode} == 3 && ${InWarp_Cooldown} && ${Ship.AfterBurner_Active}
		{
			Ship:Deactivate_AfterBurner
			return
		}
		if ${Me.ToEntity.Mode} == 3 && !${InWarp_Cooldown}
		{
			Ship:Activate_AfterBurner
			InWarp_Cooldown:Set[TRUE]
			return
		}
		if ${Me.ToEntity.Mode} != 3
		{
			InWarp_Cooldown:Set[FALSE]
			return
		}
	}
}
	
