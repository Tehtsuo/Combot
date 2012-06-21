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

objectdef obj_Module inherits obj_State
{
	variable bool Activated = FALSE
	variable bool Deactivated = FALSE
	variable int64 CurrentTarget = -1
	variable int64 ModuleID
	
	method Initialize(int64 ID)
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		ModuleID:Set[${ID}]
		NonGameTiedPulse:Set[TRUE]
		PulseFrequency:Set[50]
	}
	
	member:bool IsActive()
	{
		return ${Activated}
	}
	
	member:bool IsDeactivating()
	{
		return ${Deactivated}
	}
	
	member:bool IsActiveOn(int64 checkTarget)
	{
		if (${This.CurrentTarget.Equal[${checkTarget}]})
		{
			if ${This.IsActive}
			{
				return TRUE
			}
		}
		return FALSE
	}
	
	method Deactivate()
	{
		if !${Deactivated}
		{
			MyShip.Module[${ModuleID}]:Deactivate
			Deactivated:Set[TRUE]
			This:Clear
			This:QueueState["WaitTillInactive"]
		}
	}
	
	method Activate(int64 newTarget=-1, bool DoDeactivate=TRUE)
	{
		if ${DoDeactivate} && ${This.IsActive}
		{
			This:Deactivate
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
		Deactivated:Set[FALSE]
		CurrentTarget:Set[-1]
		return TRUE
	}
	
	member:string GetFallthroughObject()
	{
		return "MyShip.Module[${ModuleID}]"
	}
}