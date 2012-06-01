objectdef obj_Module inherits obj_State
{
	variable bool Activated
	variable bool Deactivated
	variable int64 CurrentTarget = -1
	variable int64 ModuleID
	
	method Initialize(int64 ID)
	{
		This[parent]:Initialize
		ModuleID:Set[${ID}]
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
	
	method Activate(int64 newTarget=-1, bool DoDeactivate=TRUE)
	{
		if ${DoDeactivate} && ${This.IsActive}
		{
			echo "Deactivating"
			MyShip.Module[${ModuleID}]:Deactivate
			This:Clear
			This:QueueState["WaitTillInactive", 100]
		}
		echo "QueueActivate on ${newTarget}"
		This:QueueState["ActivateOn", 100, "${newTarget}"]
		This:QueueState["WaitTillActive", 100]
		This:QueueState["WaitTillInactive", 100]
		if ${DoDeactivate}
		{
			CurrentTarget:Set[${newTarget}]
			Activated:Set[TRUE]
			Deactivated:Set[FALSE]
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
		Deactivated:Set[FALSE]
		CurrentTarget:Set[${newTarget}]
		return TRUE
	}
	
	member:bool WaitTillActive()
	{
		return ${MyShip.Module[${ModuleID}].IsActive}
	}
	
	member:bool WaitTillInactive()
	{
		if ${MyShip.Module[${ModuleID}].IsActive}
		{
			return FALSE
		}
		Activated:Set[FALSE]
		Deactivated:Set[FALSE]
		CurrentTarget:Set[-1]
		return TRUE
	}
}