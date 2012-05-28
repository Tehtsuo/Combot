
objectdef obj_Game
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

			This:State_Check
		}
	}
	
	method State_Check()
	{
		if ${Me.SolarSystemID} != ${CurrentSystem}
		{
			UI:Update["System change detected: Initiating 5 second wait", "-o"]
			This.Ready:Set[FALSE]
			CurrentSystem:Set[${Me.SolarSystemID}]
			This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + 5000 + ${Math.Rand[500]}]}]
		}
		if ${Me.InSpace} != ${InSpace}
		{
			UI:Update["Dock/Undock detected: Initiating 5 second wait", "-o"]
			This.Ready:Set[FALSE]
			InSpace:Set[${Me.InSpace}]
			This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + 5000 + ${Math.Rand[500]}]}]
		}
		if ${Me.InStation} != ${InStation}
		{
			UI:Update["Dock/Undock detected: Initiating 5 second wait", "-o"]
			This.Ready:Set[FALSE]
			InStation:Set[${Me.InStation}]
			This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + 5000 + ${Math.Rand[500]}]}]
		}
	}	

	method Wait(int time)
	{
		UI:Update["obj_Game: Initiating 5 second wait", "-o"]
		This.Ready:Set[FALSE]
		This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${time} + ${Math.Rand[500]}]}]
	}
	
}