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
	
	method Set(string arg_Name, int arg_Frequency, string arg_Args)
	{
		Name:Set[${arg_Name}]
		Frequency:Set[${arg_Frequency}]
		Args:Set["${arg_Args.Escape}"]
	}
	
	method SetArgs(string arg_Args)
	{
		Args:Set["${arg_Args.Escape}"]
	}
}

objectdef obj_State
{
	variable queue:obj_StateQueue States
	variable obj_StateQueue CurState
	
	variable int NextPulse
	variable int PulseFrequency = 2000
	variable bool NonGameTiedPulse = false
	variable bool IsIdle=FALSE

	method Initialize()
	{
		CurState:Set["Idle", 100, ""]
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
			if (!${ComBot.Paused} && ${Client.Ready}) || ${This.NonGameTiedPulse}
			{
				if ${States.Used} == 0
				{
					This.IsIdle:Set[TRUE]
					This:QueueState["Idle", 100];
				}
				
				if ${This.${CurState.Name}[${CurState.Args}]}
				{
					CurState:Set[${States.Peek.Name}, ${States.Peek.Frequency}, "${States.Peek.Args.Escape}"]
					States:Dequeue
				}
			}
			This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${CurState.Frequency} + ${Math.Rand[500]}]}]
		}
	}

	method QueueState(string arg_Name, int arg_Frequency=-1, string arg_Args="")
	{
		variable int var_Frequency
		if ${arg_Frequency} == -1
		{
			var_Frequency:Set[${This.PulseFrequency}]
		}
		else
		{
			var_Frequency:Set[${arg_Frequency}]
		}
		States:Queue[${arg_Name},${var_Frequency},"${arg_Args.Escape}"]
		This.IsIdle:Set[TRUE]
	}
	
	method SetStateArgs(string arg_Args="")
	{
		States.Peek:SetArgs["${arg_Args.Escape}"]
	}

	method Clear()
	{
		States:Clear
	}

	member:bool Idle()
	{
		return TRUE
	}
}