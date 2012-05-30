objectdef obj_Module inherits obj_State
{
	method Initialize()
	{
		This[parent]:Initialize
		This:QueueState["CheckActives", 100]
		DeclareVariable ModuleList${This.ObjectName} index:module object
		DeclareVariable ModuleActive${This.ObjectName} index:module object
		DeclareVariable ModuleTarget${This.ObjectName} index:module object
	}
	
	member:int GetInactive()
	{
		variable iterator ModuleIterator
		ModuleList${This.ObjectName}:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if !${This.IsActive[ModuleIterator.Key]}
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
		if ${ModuleActive$${This.ObjectName}[${Key}]}
		{
			return TRUE
		}
		else
		{
			return ${ModuleList${This.ObjectName}[${Key}].IsActive}
		}
	}
	
	method Activate(int64 target = -1)
	{
		variable int Module = ${This.GetInactive}
		if ${target} == -1
		{
			ModuleList${This.ObjectName}[${Module}]:Activate
			ModuleTarget${This.ObjectName}:Set[${Module}, ${Me.ActiveTarget.ID}]
		}
		else
		{
			ModuleList${This.ObjectName}[${Module}]:Activate
			ModuleTarget${This.ObjectName}:Set[${Module}, ${target}]
		}
		ModuleActive${This.ObjectName}:Set[${Module}, TRUE]
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
		variable int actualTarget
		if ${target} == -1
		{
			actualTarget:Set[${Me.ActiveTarget.ID}]
		}
		else
		{
			actualTarget:Set[${target}]
		}
		ModuleActive${This.ObjectName}:Set[${Module}, TRUE]
		ModuleTarget${This.ObjectName}:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if (${ModuleIterator.Value} == ${actualTarget}) && (${ModuleActive${This.ObjectName}[${ModuleIterator.Key}]} || ${ModuleList${This.ObjectName}[${ModuleIterator.Key}].IsActive} )
				{
					ModuleList${This.ObjectName}[${ModuleIterator.Key}]:Deactivate
					ModuleActive${This.ObjectName}:Set[${ModuleIterator.Key}, FALSE]
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
	
	member:bool IsActiveOn(int64 target = -1)
	{
		variable iterator ModuleIterator
		variable int actualTarget
		if ${target} == -1
		{
			actualTarget:Set[${Me.ActiveTarget.ID}]
		}
		else
		{
			actualTarget:Set[${target}]
		}
		ModuleTarget${This.ObjectName}:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if (${ModuleIterator.Value} == ${actualTarget}) && (${ModuleActive${This.ObjectName}[${ModuleIterator.Key}]})
				{
					return TRUE
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return FALSE
	}
	
	member:bool CheckActives()
	{
		variable iterator ModuleIterator
		if !${Client.InSpace}
		{
			return FALSE
		}
		ModuleList${This.ObjectName}:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if !${ModuleIterator.Value.IsActive}
				{
					ModuleActive${This.ObjectName}:Set[${ModuleIterator.Key}, FALSE]
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
	}

	member:int ActiveCount()
	{
		variable int varActiveCount = 0
		variable iterator ModuleIterator
		ModuleList${This.ObjectName}:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if ${ModuleIterator.Value.IsActive} || ${ModuleActive${This.ObjectName}[${ModuleIterator.Key}]}
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
		variable int varInctiveCount = 0
		variable iterator ModuleIterator
		ModuleList${This.ObjectName}:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if !${ModuleIterator.Value.IsActive} && !${ModuleActive${This.ObjectName}[${ModuleIterator.Key}]}
				{
					varInctiveCount:Inc
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return ${varInctiveCount}
	}

	member:int Count()
	{
		return ${ModuleList${This.ObjectName}.Used}
	}
	
	member:double Range()
	{
		return ${ModuleList${This.ObjectName}.Get[1].OptimalRange}
	}
	
	member:module GetIndex(int id)
	{
		return ${ModuleList${This.ObjectName}[${id}]}
	}
	
	method GetIterator(iterator Iterator)
	{
		ModuleList${This.ObjectName}:GetIterator[Iterator]
	}
	
	method Insert(int64 ID)
	{
		ModuleList${This.ObjectName}:Insert[${ID}]
		ModuleActive${This.ObjectName}:Insert[FALSE]
		ModuleTarget${This.ObjectName}:Insert[-1]
	}
	
	method Clear()
	{
		ModuleList${This.ObjectName}:Clear
		ModuleActive${This.ObjectName}:Clear
		ModuleTarget${This.ObjectName}:Clear
	}
}