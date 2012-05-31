objectdef obj_Module inherits obj_State
{
	variable index:module ModList
	variable index:bool ModuleActive
	variable index:int64 ModuleTarget
	variable index:bool ModuleDeactivating
	
	method Initialize()
	{
		This[parent]:Initialize
		This:QueueState["CheckActives", 100]
	}
	
	member:int GetInactive()
	{
		variable iterator ModuleIterator
		This.ModList:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if !${This.IsActive[${ModuleIterator.Key}]}
				{
					return ${ModuleIterator.Key}
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return -1
	}
	
	member:bool IsActive(int Key)
	{
		if ${ModuleActive[${Key}]}
		{
			return TRUE
		}
		else
		{
			return ${This.ModList[${Key}].IsActive}
		}
	}

	member:bool IsDeactivating(int Key)
	{
		if ${ModuleDeactivating[${Key}]}
		{
			return TRUE
		}
		else
		{
			return ${This.ModList[${Key}].IsDeactivating}
		}
	}
	
	method Activate(int64 target = -1)
	{
		variable int modToActivate
		modToActivate:Set[${This.GetInactive}]
		if ${target} == -1
		{
			This.ModList[${modToActivate}]:Activate
			ModuleTarget:Set[${modToActivate}, -1]
		}
		else
		{
			This.ModList[${modToActivate}]:Activate[${target}]
			ModuleTarget:Set[${modToActivate}, ${target}]
		}
		ModuleActive:Set[${modToActivate}, TRUE]
	}
	
	method ActivateCount(int moduleCount, int64 target = -1)
	{
		variable int varActivated = 0
		for (${varActivated}<${moduleCount} ; varActivated:Inc)
		{
			This:Activate[${target}]
		}
	}

	method ActivateAll(int64 target = -1)
	{
		This:Activate[${This.InactiveCount}, ${target}]
	}
	
	method Deactivate(int64 target = -1)
	{
		variable iterator ModuleIterator
		ModuleTarget:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if (${ModuleIterator.Value} == ${target}) && ${This.IsActive[${ModuleIterator.Key}]}
				{
					This.ModList[${ModuleIterator.Key}]:Deactivate
					ModuleActive:Set[${ModuleIterator.Key}, FALSE]
					ModuleDeactivating:Set[${ModuleIterator.Key}, TRUE]
					return
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
	}

	method DeactivateCount(int moduleCount, int64 target = -1)
	{
		variable int varDeactivated = 0
		for (${varDeactivated}<${moduleCount} ; varDeactivated:Inc)
		{
			This:Deactivate[${target}]
		}
	}

	method DeactivateAll(int64 target = -1)
	{
		This:Deactivate[${This.ActiveCount}, ${target}]
	}
	
	member:int CountActiveOn(int64 target = -1)
	{
		variable iterator ModuleIterator
		variable int ActiveOnCount = 0
		ModuleTarget:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if (${ModuleIterator.Value} == ${target}) && (${This.IsActive[${ModuleIterator.Key}]})
				{
					ActiveOnCount:Inc
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return ${ActiveOnCount}
	}
	
	member:bool IsActiveOn(int64 target = -1)
	{
		return ${This.CountActiveOn[${target}]}
	}
	
	member:bool CheckActives()
	{
		variable iterator ModuleIterator
		if !${Client.InSpace}
		{
			return FALSE
		}
		This.ModList:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if !${ModuleIterator.Value.IsActive}
				{
					ModuleActive:Set[${ModuleIterator.Key}, FALSE]
				}
				if ${ModuleIterator.Value.IsDeactivating} || !${ModuleIterator.Value.IsActive}
				{
					ModuleDeactivating:Set[${ModuleIterator.Key}, FALSE]
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
	}

	member:int ActiveCount()
	{
		variable int varActiveCount = 0
		variable iterator ModuleIterator
		This.ModList:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if ${This.IsActive[${ModuleIterator.Key}]}
				{
					varActiveCount:Inc
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return ${varActiveCount}
	}

	member:int InactiveCount()
	{
		variable int varInactiveCount = 0
		variable iterator ModuleIterator
		This.ModList:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if !${This.IsActive[${ModuleIterator.Key}]}
				{
					varInactiveCount:Inc
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return ${varInactiveCount}
	}
	
	member:int DeactivatingCount()
	{
		variable int varDeactivatingCount = 0
		variable iterator ModuleIterator
		This.ModList:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if !${This.IsDeactivating[${ModuleIterator.Key}]}
				{
					varDeactivatingCount:Inc
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return ${varDeactivatingCount}
	}

	member:int Count()
	{
		return ${This.ModList.Used}
	}
	
	member:float Range()
	{
		return ${This.ModList.Get[1].OptimalRange}
	}
	
	member:module GetIndex(int id)
	{
		return ${This.ModList[${id}]}
	}

	member:string GetFallthroughObject()
	{
		return ${This.ObjectName}.ModList
	}
	
	method Insert(int64 ID)
	{
		This.ModList:Insert[${ID}]
		ModuleActive:Insert[FALSE]
		ModuleTarget:Insert[-1]
		ModuleDeactivating:Insert[FALSE]
	}
	
	method Clear()
	{
		This.ModList:Clear
		ModuleActive:Clear
		ModuleTarget:Clear
		ModuleDeactivating:Clear
	}
}