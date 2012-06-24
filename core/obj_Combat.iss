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

objectdef obj_Combat inherits obj_State
{
	variable obj_TargetList KillTargets
	variable int64 CurrentTarget
	variable int Recheck = 10
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[500]
		This:AssignStateQueueDisplay[obj_CombatStateList@Combat@ComBotTab@ComBot]
	}
	
	method Start()
	{
		if ${This.IsIdle}
		{
			UI:Update["obj_Combat", "Started", "g"]
			This:QueueState["WaitForAgro", 1000]
			This:QueueState["ClearTargets"]
			This:QueueState["AddTargetingMe"]
			This:QueueState["KillCurrentTargets"]
			This:QueueState["AddAllNPCs"]
			This:QueueState["KillCurrentTargets"]
			KillTargets.AutoLock:Set[TRUE]
			KillTargets.MinLockCount:Set[5]
;			Drones:RemainDocked
;			Drones:Aggressive
;			Drones:Deploy
		}
	}
	
	member:bool WaitForAgro(int cooldown=5)
	{
		UI:Update["obj_Combat", "Cooldown ${cooldown}", "r"]
		if ${cooldown} == 0
		{
			return TRUE
		}
		cooldown:Dec
		This:SetStateArgs[${cooldown}]
		if ${Me.TargetedByCount} == 0
		{
			return FALSE
		}
		return TRUE
	}
	
	member:bool ClearTargets()
	{
		KillTargets:ClearQueryString
		return TRUE
	}
	
	member:bool AddAllNPCs()
	{
		KillTargets:AddAllNPCs
		echo cats = ${KillTargets.QueryStringList.Used}
		return TRUE
	}
	
	member:bool AddTargetingMe()
	{
		KillTargets:AddTargetingMe
		echo cats = ${KillTargets.QueryStringList.Used}
		return TRUE
	}
	
	member:bool AddTargetByName(string Name, int priority = 0)
	{
		KillTargets:AddQueryString["Name =- \"${Name.Escape}\""]
		return TRUE
	}

	member:bool AddTargetByExactName(string Name, int priority = 0)
	{
		KillTargets:AddQueryString["Name = \"${Name.Escape}\""]
		return TRUE
	}
	
	member:bool KillCurrentTargets()
	{
		variable iterator TargetIterator
		if !${Entity[${CurrentTarget}](exists)}
		{
			CurrentTarget:Set[0]
		}
		
		KillTargets.LockedTargetList:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			do
			{
				if ${CurrentTarget.Equal[0]} && ${TargetIterator.Value.Distance} < ${Ship.ModuleList_Weapon.Range}
				{
					CurrentTarget:Set[${TargetIterator.Value.ID}]
				}
				if ${CurrentTarget.Equal[${TargetIterator.Value.ID}]} && ${Ship.ModuleList_Weapon.InactiveCount} > 0
				{
					Ship.ModuleList_Weapon:Activate[${TargetIterator.Value.ID}]
					return FALSE
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		
		if ${CurrentTarget.Equal[0]} && ${KillTargets.TargetList.Used} > 0
		{
			Move:Approach[${KillTargets.TargetList.Get[1].ID}, ${Math.Calc[${Ship.ModuleList_Weapon.Range}-1000]}]
		}
		
		if ${KillTargets.TargetList.Used} == 0
		{
			Recheck:Dec
			if ${Recheck} <= 0
			{
				Recheck:Set[10]
				return TRUE
			}
			return FALSE
		}
		Recheck:Set[10]
		return FALSE
	}
}
