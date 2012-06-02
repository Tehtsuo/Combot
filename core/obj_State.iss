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
	variable string QueueListbox
	variable bool DisplayStateQueue=FALSE
	
	variable int NextPulse
	variable int PulseFrequency = 2000
	variable bool NonGameTiedPulse = false
	variable bool IsIdle

	method Initialize()
	{
		CurState:Set["Idle", 100, ""]
		IsIdle:Set[TRUE]
		Event[ISXEVE_onFrame]:AttachAtom[This:Pulse]
	}

	method Shutdown()
	{
		Event[ISXEVE_onFrame]:DetachAtom[This:Pulse]
	}
	
	method AssignStateQueueDisplay(string listbox)
	{
		variable iterator StateIterator
		QueueListbox:Set[${listbox}]
		DisplayStateQueue:Set[TRUE]
		UIElement[${QueueListbox}]:ClearItems
		States:GetIterator[StateIterator]
		
		UIElement[${QueueListbox}]:AddItem[${CurState.Name}]
		if ${StateIterator:First(exists)}
		{
			do
			{
				UIElement[${QueueListbox}]:AddItem[${StateIterator.Value.Name}]
			}
			while ${StateIterator:Next(exists)}
		}
		
	}
	
	method DeactivateStateQueueDisplay()
	{
		UIElement[${QueueListbox}]:ClearItems
		DisplayStateQueue:Set[FALSE]
	}

	method Pulse()
	{
		if ${LavishScript.RunningTime} >= ${This.NextPulse}
		{
			if (!${ComBot.Paused} && ${Client.Ready}) || ${This.NonGameTiedPulse}
			{
				if ${States.Used} == 0
				{
					This:QueueState["Idle", 100];
					IsIdle:Set[TRUE]
				}
				
				if ${This.${CurState.Name}[${CurState.Args}]}
				{
					CurState:Set[${States.Peek.Name}, ${States.Peek.Frequency}, "${States.Peek.Args.Escape}"]
					UIElement[${QueueListbox}].OrderedItem[1]:Remove
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
		UIElement[${QueueListbox}]:AddItem[${arg_Name}]
		This.IsIdle:Set[FALSE]
	}
	
	method SetStateArgs(string arg_Args="")
	{
		CurState:SetArgs["${arg_Args.Escape}"]
	}

	method Clear()
	{
		States:Clear
		UIElement[${QueueListbox}]:Clear
		UIElement[${QueueListbox}]:AddItem[${CurState.Name}]
	}

	member:bool Idle()
	{
		return TRUE
	}
}