objectdef obj_Module inherits obj_State
{
	variable bool Activated = FALSE
	variable bool Deactivated = FALSE
	variable int CurrentTarget = -1
	variable int64 ModuleID

	method Initialize(int64 ID)
	{
		This[parent]:Initialize
		ModuleID:Set[${ID}]
	}

	method Activate(int64 target = -1)
	{
		if ${This.IsActive}
		{
			This:Deactivate
		}
		This:QueueState["ActivateOn", 100, ${target}]
		Activated:Set[TRUE]
		Deactivated:Set[FALSE]
		CurrentTarget:Set[${target}]
	}
	
	method Deactivate()
	{
		MyShip.Modules[${ModuleID}]:Deactivate
		Activated:Set[FALSE]
		Deactivated:Set[TRUE]
		This:Clear
		This:QueueState["WatchDeactivation", 100, 10]
		This:QueueState["WatchFinish", 100]
	}

	member:bool IsActive()
	{
		if ${Activated}
		{
			return TRUE
		}
		return ${MyShip.Modules[${ModuleID}].IsActive}
	}

	member:bool IsDeactivating()
	{
		if ${Deactivated}
		{
			return TRUE
		}
		return ${MyShip.Modules[${ModuleID}].IsDeactivating}
	}
	
	
	
	member:bool WatchActivation(int countdown)
	{
		if ${countdown} <= 0
		{
			Activated:Set[FALSE]
			return TRUE
		}
		if ${MyShip.Modules[${ModuleID}].IsActive}
		{
			Activated:Set[FALSE]
			return TRUE
		}
		This:SetArgs[${countdown}-1]
		return FALSE
	}

	member:bool ActivateOn(int64 target = -1)
	{
		if ${target} == -1
		{
			MyShip.Modules[${ModuleID}]:Activate
		}
		else
		{
			MyShip.Modules[${ModuleID}]:Activate[${target}]
		}
		This:QueueState["WatchActivation", 100, 10]
		This:QueueState["WatchFinish", 100]
	}

	member:bool WatchFinish()
	{
		if !${MyShip.Modules[${ModuleID}].IsActive}
		{
			CurrentTarget:Set[-1]
			return TRUE
		}
		return FALSE
	}

	member:bool WatchDeactivation(int countdown)
	{
		if ${countdown} <= 0
		{
			CurrentTarget:Set[-1]
			Deactivated:Set[FALSE]
			return TRUE
		}
		if !${MyShip.Modules[${ModuleID}].IsActive}
		{
			CurrentTarget:Set[-1]
			Deactivated:Set[FALSE]
			return TRUE
		}
		This:SetArgs[${countdown}-1]
		return FALSE
	}
	
	member:bool IsActiveOn(int64 target = -1)
	{
		if ${This.IsActive} && ${target} == ${CurrentTarget}
		{
			return TRUE
		}
		return FALSE
	}
	
	member:string GetFallthroughObject()
	{
		return MyShip.Module[${ModuleID}]
	}
}