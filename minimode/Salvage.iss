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

objectdef obj_Configuration_Salvage inherits obj_Base_Configuration
{
	method Initialize()
	{
		This[parent]:Initialize["Salvage"]
	}
	
	method Set_Default_Values()
	{
		This.CommonRef:AddSetting[LockCount, 2]
		This.CommonRef:AddSetting[Size,"Small"]

		
		
	}

	Setting(int, LockCount, SetLockCount)
	Setting(string, Size, SetSize)
	Setting(bool, SalvageYellow, SetSalvageYellow)

}



objectdef obj_Salvage inherits obj_State
{
	variable obj_Configuration_Salvage Config
	variable obj_LootCans LootCans

	variable obj_TargetList Wrecks
	variable bool IsBusy
	
	
	method Initialize()
	{
		This[parent]:Initialize
		DynamicAddMiniMode("Salvage", "Salvage")
		PulseFrequency:Set[500]
	}
	
	
	method Start()
	{
		variable string Size
		if ${Config.Size.Equal[Small]}
		{
			Size:Set[&& (Type =- \"Small\" || Type =- \"Medium\" || Type =- \"Large\" || Type =- \"Cargo Container\")]
		}
		elseif ${Config.Size.Equal[Medium]}
		{
			Size:Set[&& (Type =- \"Medium\" || Type =- \"Large\" || Type =- \"Cargo Container\")]
		}
		else
		{
			Size:Set[&& (Type =- \"Large\" || Type =- \"Cargo Container\")]
		}
		
		Wrecks:ClearTargetExceptions
		Wrecks:ClearQueryString
		
		if ${Config.SalvageYellow}
		{
			echo SalvageYellow
			Wrecks:AddQueryString["(GroupID==GROUP_WRECK || GroupID==GROUP_CARGOCONTAINER) && !IsMoribund ${Size}"]
		}
		else
		{
			Wrecks:AddQueryString["(GroupID==GROUP_WRECK || GroupID==GROUP_CARGOCONTAINER) && HaveLootRights && !IsMoribund ${Size}"]
		}

		Wrecks:RequestUpdate
		This:QueueState["Updated"]
		This:QueueState["Salvage"]
	}
	
	method Stop()
	{
		This.IsBusy:Set[FALSE]
		Busy:UnsetBusy["Salvage"]
		Wrecks.AutoLock:Set[FALSE]
		This:Clear
	}
	
	member:bool Updated()
	{
		return ${Wrecks.Updated}
	}
	
	member:bool Salvage()
	{
		if !${Client.InSpace}
		{
			return FALSE
		}
	
		variable iterator TargetIterator
		variable queue:int LootRangeAndTractored
		variable int MaxTarget = ${MyShip.MaxLockedTargets}
		variable int ClosestTractorKey
		variable bool ReactivateTractor = FALSE
		variable int64 SalvageMultiTarget = -1


		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			MaxTarget:Set[${Me.MaxLockedTargets}]
		}
		if ${Config.LockCount} < ${MaxTarget}
		{
			MaxTarget:Set[${Config.LockCount}]
		}
		variable float MaxRange = ${Ship.ModuleList_TractorBeams.Range}
		if ${MaxRange} > ${MyShip.MaxTargetRange}
		{
			MaxRange:Set[${MyShip.MaxTargetRange}]
		}
		Wrecks.MaxRange:Set[${MaxRange}]
		Wrecks.MinLockCount:Set[${MaxTarget}]
		Wrecks.LockOutOfRange:Set[FALSE]
		Wrecks.AutoLock:Set[TRUE]
		Wrecks:RequestUpdate
		
		Wrecks.LockedTargetList:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			This.IsBusy:Set[TRUE]
			Busy:SetBusy["Salvage"]
			LootCans:Enable
			do
			{
				if ${TargetIterator.Value.ID(exists)}
				{
					if 	${TargetIterator.Value.IsLockedTarget} &&\
						${TargetIterator.Value.Distance} > ${Ship.ModuleList_TractorBeams.Range}
					{
						TargetIterator.Value:UnlockTarget
						return FALSE
					}
				
					if  !${Ship.ModuleList_TractorBeams.IsActiveOn[${TargetIterator.Value.ID}]} &&\
						${TargetIterator.Value.Distance} < ${Ship.ModuleList_TractorBeams.Range} &&\
						${TargetIterator.Value.Distance} > LOOT_RANGE &&\
						${Ship.ModuleList_TractorBeams.InactiveCount} > 0 &&\
						${TargetIterator.Value.IsLockedTarget} &&\
						${TargetIterator.Value.HaveLootRights}
					{
						UI:Update["Salvage", "Activating tractor beam - ${TargetIterator.Value.Name}", "g"]
						Ship.ModuleList_TractorBeams:Activate[${TargetIterator.Value.ID}]
						return FALSE
					}
					if  !${Ship.ModuleList_TractorBeams.IsActiveOn[${TargetIterator.Value.ID}]} &&\
						${TargetIterator.Value.Distance} < ${Ship.ModuleList_TractorBeams.Range} &&\
						${TargetIterator.Value.Distance} > LOOT_RANGE &&\
						${TargetIterator.Value.IsLockedTarget} &&\
						${ReactivateTractor} &&\
						${TargetIterator.Value.HaveLootRights}
					{
						UI:Update["Salvage", "Reactivating tractor beam - ${TargetIterator.Value.Name}", "g"]
						Ship.ModuleList_TractorBeams:Reactivate[${ClosestTractorKey}, ${TargetIterator.Value.ID}]
						return FALSE
					}
					if  ${Ship.ModuleList_TractorBeams.IsActiveOn[${TargetIterator.Value.ID}]} &&\
						${TargetIterator.Value.Distance} < LOOT_RANGE &&\
						!${ReactivateTractor}
					{
						ClosestTractorKey:Set[${Ship.ModuleList_TractorBeams.GetActiveOn[${TargetIterator.Value.ID}]}]
						ReactivateTractor:Set[TRUE]
					}
					if  !${Ship.ModuleList_Salvagers.IsActiveOn[${TargetIterator.Value.ID}]} &&\
						${TargetIterator.Value.Distance} < ${Ship.ModuleList_Salvagers.Range} &&\
						${Ship.ModuleList_Salvagers.InactiveCount} > 0 &&\
						${TargetIterator.Value.IsLockedTarget} && ${Ship.ModuleList_Salvagers.Count} > 0 &&\
						${TargetIterator.Value.GroupID} != GROUP_CARGOCONTAINER
					{
						UI:Update["obj_Salvage", "Activating salvager - ${TargetIterator.Value.Name}", "g"]
						Ship.ModuleList_Salvagers:Activate[${TargetIterator.Value.ID}]
						return FALSE
					}
					if  !${Ship.ModuleList_Salvagers.IsActiveOn[${TargetIterator.Value.ID}]} &&\
						${TargetIterator.Value.IsWreckEmpty} &&\
						${TargetIterator.Value.IsLockedTarget} && ${Ship.ModuleList_Salvagers.Count} == 0
					{
						TargetIterator.Value:Abandon
						TargetIterator.Value:UnlockTarget
					}
					if  ${TargetIterator.Value.Distance} < ${Ship.ModuleList_Salvagers.Range} &&\
						${Ship.ModuleList_Salvagers.InactiveCount} > 0 &&\
						${TargetIterator.Value.IsLockedTarget} &&\
						${TargetIterator.Value.GroupID} != GROUP_CARGOCONTAINER
					{
						SalvageMultiTarget:Set[${TargetIterator.Value.ID}]
					}
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		else
		{
			if ${Wrecks.TargetList.Used} > 0
			{
				This.IsBusy:Set[FALSE]
				Busy:UnsetBusy["Salvage"]
			}
			else
			{
				LootCans:Disable
				This.IsBusy:Set[FALSE]
				Busy:UnsetBusy["Salvage"]
				Wrecks.AutoLock:Set[FALSE]
				return FALSE
			}
		}
		if !${SalvageMultiTarget.Equal[-1]} && ${Ship.ModuleList_Salvagers.InactiveCount} > 0
		{
			Ship.ModuleList_Salvagers:Activate[${SalvageMultiTarget}]
		}
		return FALSE
	}

}


objectdef obj_LootCans inherits obj_State
{
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
	}
	
	method Enable()
	{
		This:QueueState["Loot", 3000]
	}
	
	method Disable()
	{
		This:Clear
	}
	
	member:bool Loot()
	{
		variable iterator TargetIterator
		variable index:item TargetCargo
		variable iterator CargoIterator
		
	
		if !${Client.InSpace}
		{
			return FALSE
		}
		
		if ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}

		Salvage.Wrecks.TargetList:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)} && ${EVEWindow[Inventory](exists)}
		{
			do
			{
				if 	${TargetIterator.Value.Distance} > LOOT_RANGE ||\
					${TargetIterator.Value.IsWreckEmpty} ||\
					!${Entity[${TargetIterator.Value.ID}](exists)}
				{
					continue
				}
				if ${EVEWindow[Inventory].ChildWindow[${TargetIterator.Value}](exists)}
				{
					if !${EVEWindow[ByItemID, ${TargetIterator.Value}](exists)}
					{
						EVEWindow[Inventory].ChildWindow[${TargetIterator.Value}]:MakeActive
						return FALSE
					}
					
					Entity[${TargetIterator.Value}]:GetCargo[TargetCargo]
					TargetCargo:GetIterator[CargoIterator]
					if ${CargoIterator:First(exists)}
					{
						do
						{
							if ${CargoIterator.Value.IsContraband}
							{
								Salvage.Wrecks:AddTargetException[${TargetIterator.Value.ID}]
								return FALSE
							}
						}
						while ${CargoIterator:Next(exists)}
					}
					
					UI:Update["Salvage", "Looting - ${TargetIterator.Value.Name}", "g"]
					Cargo:PopulateCargoList[Container, ${TargetIterator.Value.ID}]
					Cargo:MoveCargoList[SHIP]
					This:InsertState["Loot"]
					This:InsertState["Stack"]
					return TRUE
				}
				if !${EVEWindow[Inventory].ChildWindow[${TargetIterator.Value}](exists)}
				{
					UI:Update["Salvage", "Opening - ${TargetIterator.Value.Name}", "g"]
					TargetIterator.Value:Open
					return FALSE
				}		
			}
			while ${TargetIterator:Next(exists)}
		}
		return FALSE
	}
	
	member:bool Stack()
	{
		EVE:StackItems[MyShip, CargoHold]
		return TRUE
	}
}