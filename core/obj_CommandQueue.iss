
objectdef obj_Command
{
	variable string Object
	variable string Method
	variable string Args

	method Initialize(string arg_Object, string arg_Method, string arg_Args)
	{
		Object:Set[${arg_Object}]
		Method:Set[${arg_Method}]
		Args:Set["${arg_Args.Escape}"]
	}
}

objectdef obj_CommandQueue
{
	variable queue:obj_Command Commands

	variable int NextPulse
	variable int PulseIntervalInMilliseconds = 2000


	
	method Initialize()
	{
		Event[ISXEVE_onFrame]:AttachAtom[This:Pulse]
		UI:Update["obj_CommandQueue: Initialized", "g"]
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
			This:ProcessCommands

			if ${LavishScript.RunningTime} >= ${This.NextPulse}
			{
				This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${PulseIntervalInMilliseconds} + ${Math.Rand[500]}]}]
			}
		}
	}	

	
	;	Processes one command if the queue is not empty
	method ProcessCommands()
	{
		if ${Commands.Used} == 0
		{
			return
		}
		
		
		if ${Commands.Peek(exists)}
		{
			if ${Commands.Peek.Object.Equal[IGNORE]}
			{
				Commands:Dequeue
				return
			}
			if ${Commands.Peek.Object.Equal[WAIT]} 
			{
				This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${Commands.Peek.Method}]}]
				Commands:Dequeue
				This:QueueCommand[IGNORE]
				return
			}

			${Commands.Peek.Object}:${Commands.Peek.Method}[${Commands.Peek.Args}]
			Commands:Dequeue
		}

		
	}
	
	method InsertCommand(string arg_Object, string arg_Method="", string arg_Args="")
	{
		variable queue:obj_Command TempQueue
		TempQueue:Queue[${arg_Object},${arg_Method},"${arg_Args.Escape}"]
		if ${Commands.Peek(exists)}
		do
		{
			TempQueue:Queue[${Commands.Peek.Object},${Commands.Peek.Method},${Commands.Peek.Args}]
			Commands:Dequeue
		}
		while ${Commands.Peek(exists)}
		if ${TempQueue.Peek(exists)}
		do
		{
			Commands:Queue[${TempQueue.Peek.Object},${TempQueue.Peek.Method},${TempQueue.Peek.Args}]
			TempQueue:Dequeue
		}
		while ${TempQueue.Peek(exists)}
	}
	
	method QueueCommand(string arg_Object, string arg_Method="", string arg_Args="")
	{
		Commands:Queue[${arg_Object},${arg_Method},"${arg_Args.Escape}"]
	}
	
	member:int Queued()
	{
		return ${Commands.Used}
	}
	
	method Clear()
	{
		Commands:Clear
	}
}
