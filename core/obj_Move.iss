
objectdef obj_Move
{
	variable int NextPulse
	variable int PulseIntervalInMilliseconds = 2000
	
	variable bool Approaching=FALSE
	variable int64 ApproachingID
	variable int ApproachingDistance
	variable int TimeStartedApproaching = 0

	variable bool InWarp_Cooldown=FALSE
	variable int StartWarpCooldown=0

	variable bool BookmarkMove
	variable string BookmarkMoveLabel
	variable int TimeStartedBookmarkMove = 0


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
		if ${ComBot.Paused}
		{
			return
		}

	    if ${LavishScript.RunningTime} >= ${This.NextPulse}
		{
			if ${CommandQueue.Queued} == 0
			{
				This:InWarp_Check
				This:StartWarp_Check
				This:CheckBookmarkMove
				This:CheckApproach
			}
				
    		This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${PulseIntervalInMilliseconds} + ${Math.Rand[500]}]}]
		}
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


	method MoveToBookmark(string DestinationBookmarkLabel)
	{
		;	If we're already traveling to the target, ignore the request
		if ${DestinationBookmarkLabel.Equal[${This.BookmarkMoveLabel}]} && ${This.BookmarkMove}
		{
			return
		}
		
		if !${EVE.Bookmark[${DestinationBookmarkLabel}](exists)}
		{
			UI:Update["Attempted to travel to a bookmark which does not exist", "r"]
			UI:Update["Bookmark label: ${DestinationBookmarkLabel}", "r"]
			return
		}

		if ${EVE.Bookmark[${DestinationBookmarkLabel}](exists)} && ${EVE.Bookmark[${DestinationBookmarkLabel}].SolarSystemID} == ${Me.SolarSystemID}
		{
			if ${EVE.Bookmark[${DestinationBookmarkLabel}].ItemID} == -1
			{
				if ${EVE.Bookmark[${DestinationBookmarkLabel}].Distance} < WARP_RANGE
				{
					UI:Update["Already at ${DestinationBookmarkLabel}", "o"]
					return
				}
			}
			else
			{
				if ${EVE.Bookmark[${DestinationBookmarkLabel}].ToEntity(exists)}
				{
					if ${EVE.Bookmark[${DestinationBookmarkLabel}].ToEntity.Distance} < WARP_RANGE
					{
						UI:Update["Already at ${DestinationBookmarkLabel}", "o"]
						return
					}
				}
				else
				{
					if ${EVE.Bookmark[${DestinationBookmarkLabel}].Distance} < WARP_RANGE
					{
						UI:Update["Already at ${DestinationBookmarkLabel}", "o"]
						return
					}
				}
			}
		}

		UI:Update["Movement queued.  Destination: ${DestinationBookmarkLabel}", "g"]
		This.BookmarkMoveLabel:Set[${DestinationBookmarkLabel}]
		This.TimeStartedBookmarkMove:Set[-1]
		This.BookmarkMove:Set[TRUE]	
	}


	
	method CheckBookmarkMove()
	{
		if !${This.BookmarkMove}
		{
			return
		}
		
		if ${Me.InStation}
		{
			if ${Me.StationID} == ${EVE.Bookmark[${BookmarkMoveLabel}].ItemID}
			{
				UI:Update["Docked at ${BookmarkMoveLabel}", "g"]
				This.BookmarkMove:Set[FALSE]
				return
			}
			else
			{
				UI:Update["Undocking from ${Me.Station.Name}", "g"]
				
				CommandQueue:QueueCommand[Move,Undock]
				CommandQueue:QueueCommand[WAIT,10000]
				return
			}
		}

		if ${Me.ToEntity.Mode} == 3 || !${Me.InSpace} || ${This.SystemChangeCooldown} > 0 || ${This.StartWarpCooldown} > 0
		{
			return
		}
		
		if ${EVE.Bookmark[${BookmarkMoveLabel}](exists)} && ${EVE.Bookmark[${BookmarkMoveLabel}].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:TravelToSystem[${EVE.Bookmark[${BookmarkMoveLabel}].SolarSystemID}]
			return
		}
		
		
		if ${EVE.Bookmark[${BookmarkMoveLabel}](exists)}
		{
			if ${EVE.Bookmark[${DestinationBookmarkLabel}].ItemID} == -1
			{
				if ${EVE.Bookmark[${BookmarkMoveLabel}].Distance} > WARP_RANGE
				{
					UI:Update["Warping to ${BookmarkMoveLabel}", "g"]
					EVE.Bookmark[${BookmarkMoveLabel}]:WarpTo
					StartWarpCooldown:Set[2]
					return
				}
				else
				{
					UI:Update["Reached ${BookmarkMoveLabel}", "g"]
					This.BookmarkMove:Set[FALSE]
					return
				}
			}
			else
			{
				if ${EVE.Bookmark[${BookmarkMoveLabel}].ToEntity(exists)}
				{
					if ${EVE.Bookmark[${BookmarkMoveLabel}].ToEntity.Distance} > WARP_RANGE
					{
						UI:Update["Warping to ${BookmarkMoveLabel}", "g"]
						EVE.Bookmark[${BookmarkMoveLabel}].ToEntity:WarpTo
						StartWarpCooldown:Set[2]
						return
					}
					else
					{
						UI:Update["Reached ${BookmarkMoveLabel}, docking", "g"]
						CommandQueue:QueueCommand[Move,DockAtStation,${EVE.Bookmark[${BookmarkMoveLabel}].ItemID}]
						CommandQueue:QueueCommand[WAIT,10000]
						return
					}
				}
				else
				{
					if ${EVE.Bookmark[${BookmarkMoveLabel}].Distance} > WARP_RANGE
					{
						UI:Update["Warping to ${BookmarkMoveLabel}", "g"]
						EVE.Bookmark[${BookmarkMoveLabel}]:WarpTo
						StartWarpCooldown:Set[2]
						return
					}
					else
					{
						UI:Update["Reached ${BookmarkMoveLabel}", "g"]
						This.BookmarkMove:Set[FALSE]
						return
					}
				}
			}
			
		}
		else
		{
			UI:Update["Attempted to travel to a bookmark which does not exist", "r"]
			UI:Update["Bookmark label: ${DestinationBookmarkLabel}", "r"]
			This.BookmarkMove:Set[FALSE]
		}
	}
	
	method DockAtStation(int64 StationID)
	{
		if ${Me.ToEntity.Mode} == 3
		{
			return
		}
		
		if ${Me.InStation}
		{	
			return
		}
		
		if !${Me.InSpace}
		{
			return
		}

		if ${Entity[${StationID}](exists)}
		{
			UI:Update["Docking: ${Entity[${StationID}].Name}", "g"]
			Entity[${StationID}]:Dock
		}
		else
		{
			UI:Update["Station Requested does not exist.  StationID: ${StationID}", "r"]
		}
	}	

	method Undock()
	{
			EVE:Execute[CmdExitStation]
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
	