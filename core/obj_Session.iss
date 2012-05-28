
objectdef obj_Session
{
	variable int PulseIntervalInMilliseconds = 500
	variable int NextPulse
	
	variable bool Ready=TRUE
	variable int64 CurrentSystem=${Me.SolarSystemID}
	
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
			
			This:SystemChange_Check
		}
	}
  
	method SystemChange_Check()
	{
		if !${This.Ready}
		{
				This.Ready:Set[TRUE]
				return
		}
		if ${Me.SolarSystemID} != ${CurrentSystem}
		{
			UI:Update["System change detected: Initiating 5 second wait", "-o"]
			This.Ready:Set[FALSE]
			CurrentSystem:Set[${Me.SolarSystemID}]
			This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + 5000 + ${Math.Rand[500]}]}]
		}
	}	

}