/*

ComBot  Copyright © 2012  Tehtsuo and Vendan

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

variable collection:obj_ModuleBase ModuleBaseModules

objectdef obj_Module
{
	variable int64 ModuleID
	method Initialize(int64 ID)
	{
		ModuleID:Set[${MyShip.Module[${ID}].ID}]
		if !${ModuleBaseModules[${ModuleID}](exists)}
		{
			ModuleBaseModules:Set[${ModuleID}, ${ModuleID}]
		}
	}
	
	member:int64 CurrentTarget()
	{
		return ${ModuleBaseModules[${ModuleID}].CurrentTarget}
	}
	
	member:bool IsActive()
	{
		return ${ModuleBaseModules[${ModuleID}].IsActive}
	}
	
	member:bool IsDeactivating()
	{
		return ${ModuleBaseModules[${ModuleID}].IsDeactivating}
	}
	
	member:bool IsActiveOn(int64 checkTarget)
	{
		return ${ModuleBaseModules[${ModuleID}].IsActiveOn[${checkTarget}]}
	}
	
	method Deactivate()
	{
		ModuleBaseModules[${ModuleID}]:Deactivate
	}
	
	method Activate(int64 newTarget=-1, bool DoDeactivate=TRUE, int DeactivatePercent=100)
	{
		ModuleBaseModules[${ModuleID}]:Activate[${newTarget}, ${DoDeactivate}, ${DeactivatePercent}]
	}
	
	member:bool LoadMiningCrystal(string OreType)
	{
		return ${ModuleBaseModules[${ModuleID}].LoadMiningCrystal[${OreType.Escape}]}
	}
	
	member:float Range()
	{
		return ${ModuleBaseModules[${ModuleID}].Range}
	}
	
	member:string GetFallthroughObject()
	{
		return "MyShip.Module[${ModuleID}]"
	}
}