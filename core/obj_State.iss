objectdef obj_StateQueue
{
	variable string Name
	variable int Frequency
	variable string Args

	method Initialize(string arg_Name, int arg_Frequency, string arg_Args)
	{
		Name:Set[${arg_Name}]
		Frequency:Set[${arg_Frequency}]
		Args:Set["${arg_Args.Escape}"]
	}
}

objectdef obj_State
	{
	variable queue:obj_StateQueue States

	variable int NextPulse

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
			if !${ComBot.Paused} && ${Game.Ready}
			{
				if This.${States.Peek.Name}[${States.Peek.Args}]
				{
					States:Dequeue
				}
			}
			
			if ${States.Used} == 0
			{
				States:Queue["Idle", 2000, ""];
			}

			This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${States.Frequency} + ${Math.Rand[500]}]}]
		}
	}

	method QueueState(string arg_Name, int arg_Frequency=2000, string arg_Args="")
	{
		States:Queue[${arg_Object},${arg_Frequency},"${arg_Args.Escape}"]
	}

	method Clear()
	{
		States:Clear
	}

	method:bool Idle()
	{
		return true
	}
}