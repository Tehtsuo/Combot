
objectdef obj_ComBot
{
	variable bool Paused = TRUE

	variable int NextPulse
	variable int PulseIntervalInMilliseconds = 2000

	method Initialize()
	{
		Event[ISXEVE_onFrame]:AttachAtom[This:Pulse]
		UI:Update["obj_ComBot: Initialized", "g"]
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

	method Pause()
	{
		UI:Update["Combot Paused", "r"]
		This.Paused:Set[TRUE]
	}

	method Resume()
	{
		UI:Update["Combot Resumed", "g"]
		This.Paused:Set[FALSE]
	}



	member:string MetersToKM_Str(float64 Meters)
	{
		if ${Meters(exists)} && ${Meters} > 0
		{
			return "${Math.Calc[${Meters} / 1000].Centi}km"
		}
		else
		{
			return "0km"
		}
	}

	member:string ISK_To_Str(float64 Total)
	{
		if ${Total(exists)}
		{
			if ${Total} > 1000000000
			{
				return "${Math.Calc[${Total}/100000000].Precision[3]}b isk"
			}
			elseif ${Total} > 1000000
			{
				return "${Math.Calc[${Total}/1000000].Precision[2]}m isk"
			}
			elseif ${Total} > 1000
			{
				return "${Math.Calc[${Total}/1000].Round}k isk"
			}
			else
			{
				return "${Total.Round} isk"
			}
		}

		return "0 isk"
	}
}
