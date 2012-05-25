
objectdef obj_Warp
{
	variable int NextPulse
	variable int PulseIntervalInMilliseconds = 2000

	method Initialize()
	{
		Event[ISXEVE_onFrame]:AttachAtom[This:Pulse]

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
					EVE.Bookmark[${DestinationBookmarkLabel}]:WarpFleetTo
				}
				else
				{
					EVE.Bookmark[${DestinationBookmarkLabel}]:WarpTo
				}
			}
		}
		else
		{
		}
	}
	
	
	