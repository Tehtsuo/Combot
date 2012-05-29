
objectdef obj_Client
{
	variable int PulseIntervalInMilliseconds = 500
	variable int NextPulse
	
	variable bool Ready=TRUE
	variable int64 CurrentSystem=${Me.SolarSystemID}
	variable bool InSpace=${Me.InSpace}
	variable bool InStation=${Me.InStation}
	
	method Initialize()
	{
		Event[ISXEVE_onFrame]:AttachAtom[This:Pulse]
		UI:Update["obj_Client", "Initialized", "g"]
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

			if ${ComBot.Paused}
			{
				return
			}			
			
			This.Ready:Set[TRUE]
		}
	}
	
	member:bool Space()
	{
		if ${Me.InSpace(type).Name.Equal[bool]} && ${EVE.EntitiesCount} > 0
		{
			return ${Me.InSpace}
		}
		return FALSE
	}

	method Wait(int delay)
	{
		UI:Update["obj_Client", "Initiating ${delay} millisecond wait", "-o"]
		This.Ready:Set[FALSE]
		This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${delay}]}]
	}
	
}