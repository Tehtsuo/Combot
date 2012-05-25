
objectdef obj_Move
{
	variable int NextPulse
	variable int PulseIntervalInMilliseconds = 2000
	
	variable bool Approaching=FALSE
	variable int64 ApproachingID
	variable int ApproachingDistance
	variable int TimeStartedApproaching = 0
	

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
		EVE:GetToDestinationPath[DestinationList]
		
		if ${DestinationList.Used} > 0
		{
			UI:Update["Setting destination to ${Universe[${DestinationSystemID}].Name}", "g"]
			Universe[${DestinationSystemID}]:SetDestination
			return
		}
		
		This:ActivateAutoPilot
	}


	method Bookmark(string DestinationBookmarkLabel, bool WarpFleet=FALSE)
	{
		if ${Me.ToEntity.Mode} == 3
		{
			return
		}
		
		if ${EVE.Bookmark[${DestinationBookmarkLabel}](exists)} && ${EVE.Bookmark[${DestinationBookmarkLabel}].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:TravelToSystem[${EVE.Bookmark[${Config.Miner.PanicLocation}].SolarSystemID}]
			return
		}
		
		
		if ${EVE.Bookmark[${DestinationBookmarkLabel}](exists)}
		{
			if ${EVE.Bookmark[${DestinationBookmarkLabel}].Distance} > WARP_RANGE
			{
				if ${WarpFleet}
				{
					UI:Update["Warping fleet to ${Universe[${EVE.Bookmark[${DestinationBookmarkLabel}].ID}].Name}", "g"]
					EVE.Bookmark[${DestinationBookmarkLabel}]:WarpFleetTo
				}
				else
				{
					UI:Update["Warping to ${Universe[${EVE.Bookmark[${DestinationBookmarkLabel}].ID}].Name}", "g"]
					EVE.Bookmark[${DestinationBookmarkLabel}]:WarpTo
				}
			}
		}
		else
		{
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
		if !${This.Approaching}
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

	
}
	