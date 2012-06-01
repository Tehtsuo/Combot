objectdef obj_ModuleList
{
	variable index:obj_Module Modules
	
	method Insert(int64 ID)
	{
		Modules:Insert[${ID}]
	}
	
	member:int GetInactive()
	{
		variable iterator ModuleIterator
		Modules:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if !${ModuleIterator.Value.IsActive}
				{
					echo GetInactive - ${ModuleIterator.Key}
					return ${ModuleIterator.Key}
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return -1
	}
	
	method Activate(int64 target=-1)
	{
		variable int modToActivate = ${This.GetInactive}
		if ${modToActivate} == -1
		{
			return
		}
		Modules[${modToActivate}]:Activate[${target}]
	}
	
	method Reactivate(int ModuleID, int64 target=-1)
	{
		Modules[${ModuleID}]:Activate[${target}]
	}
	
	member:bool IsActiveOn(int64 checkTarget)
	{
		variable iterator ModuleIterator
		Modules:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if ${ModuleIterator.Value.IsActiveOn[${checkTarget}]}
				{
					return TRUE
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return FALSE
	}
	
	member:int GetActiveOn(int64 target)
	{
		variable iterator ModuleIterator
		Modules:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if ${ModuleIterator.Value.IsActiveOn[${target}]}
				{
					return ${ModuleIterator.Key}
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return -1
	}
	
	member:int InactiveCount()
	{
		variable iterator ModuleIterator
		variable int countInactive = 0
		Modules:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if !${ModuleIterator.Value.IsActive}
				{
					countInactive:Inc
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return ${countInactive}
	}
	
	member:string GetFallthroughObject()
	{
		return "Ship.${This.ObjectName}.Modules"
	}
}