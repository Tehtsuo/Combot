objectdef obj_Module inherits obj_State
{
	variable bool Activated = FALSE
	variable int64 CurrentTarget = -1
	variable int64 ModuleID
	
	method Initialize(int64 ID)
	{
		This[parent]:Initialize
		ModuleID:Set[${ID}]
		NonGameTiedPulse:Set[TRUE]
		PulseFrequency:Set[50]
	}
	
	member:bool IsActive()
	{
		return ${Activated}
	}
	
	member:bool IsActiveOn(int64 checkTarget)
	{
		echo IsActiveOn ${This.CurrentTarget} == ${checkTarget}
		if (${This.CurrentTarget.Equal[${checkTarget}]})
		{
			if ${This.IsActive}
			{
				echo TRUE
				return TRUE
			}
		}
		echo FALSE
		return FALSE
	}
	
	method Deactivate()
	{
		MyShip.Module[${ModuleID}]:Deactivate
		This:Clear
		This:QueueState["WaitTillInactive"]
	}
	
	method Activate(int64 newTarget=-1, bool DoDeactivate=TRUE)
	{
		if ${DoDeactivate} && ${This.IsActive}
		{
			echo "Deactivating"
			MyShip.Module[${ModuleID}]:Deactivate
			This:Clear
			This:QueueState["WaitTillInactive"]
		}
		This:QueueState["ActivateOn", 50, "${newTarget}"]
		This:QueueState["WaitTillActive", 50, 20]
		This:QueueState["WaitTillInactive"]
		if ${DoDeactivate}
		{
			CurrentTarget:Set[${newTarget}]
			Activated:Set[TRUE]
		}
	}
	
	member:bool ActivateOn(int64 newTarget)
	{
		echo "Activating on ${newTarget}"
		if ${newTarget} == -1
		{
			MyShip.Module[${ModuleID}]:Activate
		}
		else
		{
			MyShip.Module[${ModuleID}]:Activate[${newTarget}]
		}
		Activated:Set[TRUE]
		CurrentTarget:Set[${newTarget}]
		return TRUE
	}
	
	member:bool WaitTillActive(int countdown)
	{
		if ${countdown} > 0
		{
			This:SetStateArgs[${Math.Calc[${countdown}-1]}]
			return ${MyShip.Module[${ModuleID}].IsActive}
		}
		return TRUE
	}
	
	member:bool WaitTillInactive()
	{
		if ${MyShip.Module[${ModuleID}].IsActive}
		{
			return FALSE
		}
		Activated:Set[FALSE]
		CurrentTarget:Set[-1]
		return TRUE
	}
	
	member:string GetFallthroughObject()
	{
		return "MyShip.Module[${ModuleID}]"
	}
}