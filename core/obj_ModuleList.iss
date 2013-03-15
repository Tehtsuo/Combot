/*

ComBot  Copyright � 2012  Tehtsuo and Vendan

This file is part of ComBot.

ComBot is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ComBot is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ComBot.  If not, see <http://www.gnu.org/licenses/>.

*/

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
				if !${ModuleIterator.Value.IsActive} && !${ModuleIterator.Value.IsReloading}
				{
					return ${ModuleIterator.Key}
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return -1
	}
	
	method Activate(int64 target=-1, bool DoDeactivate=TRUE, int DeactivatePercent=100)
	{
		This:ActivateCount[1, ${target}, ${DoDeactivate}, ${DeactivatePercent}]
	}
	
	method ActivateCount(int count, int64 target=-1, bool DoDeactivate=TRUE, int DeactivatePercent=100)
	{
		variable int activatedCount = 0
		variable iterator ModuleIterator
		Modules:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if !${ModuleIterator.Value.IsActive}
				{
					ModuleIterator.Value:Activate[${target}, ${DoDeactivate}, ${DeactivatePercent}]
					activatedCount:Inc
				}
				if ${activatedCount} >= ${count}
				{
					return
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
	}
	
	method Deactivate(int64 target=-1)
	{
		This:DeactivateCount[1, ${target}]
	}
	
	method DeactivateCount(int count, int64 target=-1)
	{
		variable int deactivatedCount = 0
		variable iterator ModuleIterator
		Modules:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if ${ModuleIterator.Value.IsActiveOn[${target}]} || ${target} == -1
				{
					ModuleIterator.Value:Deactivate
					deactivatedCount:Inc
				}
				if ${deactivatedCount} >= ${count}
				{
					return
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
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
	
	member:int ActiveCount()
	{
		variable int countActive=0
		variable iterator ModuleIterator
		Modules:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if ${ModuleIterator.Value.IsActive}
				{
					countActive:Inc
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return ${countActive}
	}
	
	member:int ActiveCountOn(int64 checkTarget)
	{
		variable int countActive=0
		variable iterator ModuleIterator
		Modules:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if ${ModuleIterator.Value.IsActiveOn[${checkTarget}]}
				{
					countActive:Inc
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return ${countActive}
	}
	
	member:int Count()
	{
		return ${Modules.Used}
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
	
	member:int GetActiveNotOn(int64 target)
	{
		variable iterator ModuleIterator
		Modules:GetIterator[ModuleIterator]
		if ${ModuleIterator:First(exists)}
		{
			do
			{
				if !${ModuleIterator.Value.IsActiveOn[${target}]} && ${ModuleIterator.Value.IsActive}
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
				if !${ModuleIterator.Value.IsActive} && !${ModuleIterator.Value.IsReloading}
				{
					countInactive:Inc
				}
			}
			while ${ModuleIterator:Next(exists)}
		}
		return ${countInactive}
	}
	
	member:float Range()
	{
		return ${Modules.Get[1].Range}
	}
	
	member:string GetFallthroughObject()
	{
		return "Ship.${This.ObjectName}.Modules"
	}
}