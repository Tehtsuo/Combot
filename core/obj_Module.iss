objectdef obj_Module inherits obj_State
{
	variable bool Activated = FALSE
	variable bool Deactivated = FALSE
	variable int CurrentTarget = -1

	method Initialize(int64 ID)
	{
		This[parent]:Initialize
		DeclareVariable ActualModule module object = ${ID}
	}

	method Activate(int64 target = -1)
	{
		if ${IsActive}
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
		ActualModule:Deactivate
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
		return ${ActualModule.IsActive}
	}

	member:bool IsDeactivating()
	{
		if ${Deactivated}
		{
			return TRUE
		}
		return ${ActualModule.IsDeactivating}
	}
	
	
	
	member:bool WatchActivation(int countdown)
	{
		if ${countdown} <= 0
		{
			Activated:Set[FALSE]
			return TRUE
		}
		if ${ActualModule.IsActive}
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
			ActualModule:Activate
		}
		else
		{
			ActualModule:Activate[${target}]
		}
		This:QueueState["WatchActivation", 100, 10]
		This:QueueState["WatchFinish", 100]
	}

	member:bool WatchFinish()
	{
		if !${ActualModule.IsActive}
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
		if !${ActualModule.IsActive}
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
		if ${IsActive} && ${target} == ${CurrentTarget}
		{
			return TRUE
		}
		return FALSE
	}
	
	member:string GetFallthroughObject()
	{
		return ${This.ObjectName}.ActualModule
	}
}