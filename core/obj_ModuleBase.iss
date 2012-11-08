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

objectdef obj_ModuleBase inherits obj_State
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
		echo ModuleBase:Activate
		echo This.IsActive ${This.IsActive}
		if ${DoDeactivate} && ${This.IsActive}
		{
			echo Triggering Deactivate
			This:Deactivate
		}
		if ${newTarget} == -1
		{
			newTarget:Set[${Me.ActiveTarget.ID}]
		}
		if ${Entity[${newTarget}].CategoryID} == CATEGORYID_ORE && ${MyShip.Module[${ModuleID}].ToItem.GroupID} == GROUP_FREQUENCY_MINING_LASER
		{
			This:QueueState["LoadMiningCrystal", 50, ${Entity[${newTarget}].Type}]
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
	
	member:bool LoadMiningCrystal(string OreType)
	{
		variable index:item Crystals
		variable iterator Crystal
		if ${OreType.Find[${MyShip.Module[${ModuleID}].Charge.Name.Token[1," "]}]}
		{
			return TRUE
		}
		else
		{
			MyShip.Module[${ModuleID}]:GetAvailableAmmo[Crystals]
			
			if ${Crystals.Used} == 0
			{
				UI:Update["obj_Module", "No crystals available - mining ouput decreased", "o"]
			}
			
			Crystals:GetIterator[Crystal]
			
			if ${Crystal:First(exists)}
			do
			{
				if ${OreType.Find[${Crystal.Value.Name.Token[1, " "]}](exists)}
				{
					UI:Update["obj_Module", "Switching Crystal to ${Crystal.Value.Name}"]
					Me.Ship.Module[${ModuleID}]:ChangeAmmo[${Crystal.Value.ID},1]
					return TRUE
				}
			}
			while ${Crystal:Next(exists)}
		}
		
		return TRUE
	}
	
	member:bool ActivateOn(int64 newTarget)
	{
		echo ModuleBase.ActivateOn
		if ${newTarget} == -1 || ${newTarget} == 0
		{
			MyShip.Module[${ModuleID}]:Activate
		}
		else
		{
			if ${Entity[${newTarget}](exists)} && ${Entity[${newTarget}].IsLockedTarget}
			{
				MyShip.Module[${ModuleID}]:Activate[${newTarget}]
			}
			else
			{
				Activated:Set[FALSE]
				CurrentTarget:Set[-1]
				This:Clear
				return TRUE
			}
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
	
	member:float Range()
	{
		if ${MyShip.Module[${ModuleID}].TransferRange(exists)}
		{
			return ${MyShip.Module[${ModuleID}].TransferRange}
		}
		if ${MyShip.Module[${ModuleID}].ShieldTransferRange(exists)}
		{
			return ${MyShip.Module[${ModuleID}].ShieldTransferRange}
		}
		if ${MyShip.Module[${ModuleID}].OptimalRange(exists)}
		{
			return ${MyShip.Module[${ModuleID}].OptimalRange}
		}
		else
		{
			return ${Math.Calc[${MyShip.Module[${ModuleID}].Charge.MaxFlightTime} * ${MyShip.Module[${ModuleID}].Charge.MaxVelocity}]}
		}
	}
	
	member:string GetFallthroughObject()
	{
		return "MyShip.Module[${ModuleID}]"
	}

}