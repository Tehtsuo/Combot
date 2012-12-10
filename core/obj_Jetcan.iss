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

objectdef obj_Jetcan inherits obj_State
{
	variable collection:int CanAges
	variable IPCQueue:obj_HaulLocation OnDemandHaulQueue = "HaulerOnDemandQueue"
	
	method Initialize()
	{
		This[parent]:Initialize
	}
	
	method Enable()
	{
		if ${This.IsIdle}
		{
			This:QueueState["Fill", 2000]
		}
	}
	
	method Disable()
	{
		This:Clear
	}
	
	member:bool Fill()
	{
		variable index:entity Targets
		variable iterator TargetIterator
		variable int64 Can
	
		if !${Client.InSpace}
		{
			return FALSE
		}

		if !${EVEWindow[Inventory](exists)}
		{
			EVE:Execute[OpenInventory]
			return FALSE
		}
		
		if  ${MyShip.HasOreHold}
		{
			if ${EVEWindow[Inventory].ChildCapacity[ShipOreHold]} != 0
			{
				if ${EVEWindow[Inventory].ChildUsedCapacity[ShipOreHold]} / ${EVEWindow[Inventory].ChildCapacity[ShipOreHold]} < ${Miner.Config.Threshold} * .01
				{
					return FALSE
				}
			}
			else
			{
				return FALSE
			}
		}
		else
		{
			if ${MyShip.CargoCapacity} != 0
			{
				if ${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity} < ${Miner.Config.Threshold} * .01
				{
					return FALSE
				}
			}
			else
			{
				return FALSE
			}
		}
		
		CanAges:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			do
			{
				if !${Entity[${TargetIterator.Key}](exists)}
				{
					CanAges:Erase[${TargetIterator.Key}]
				}
				else
				{
					if ${Math.Calc[${TargetIterator.Value} + 3600000]} < ${LavishScript.RunningTime}
					{
						if ${Entity[${TargetIterator.Key}].Distance < LOOT_RANGE}
						{
							if !${EVEWindow[Inventory].ChildWindowExists[${TargetIterator.Value}]}
							{
								UI:Update["obj_Jetcan", "Opening - ${TargetIterator.Value.Name}", "g"]
								TargetIterator.Value:Open
								return FALSE
							}
							This:QueueState["LootCan", 1000, ${TargetIterator.Key}]
							This:QueueState["NewCan", 2000]
							This:QueueState["TransferCan", 10000, "${TargetIterator.Key}"]
							if ${Miner.Config.RenameCans}
							{
								This:QueueState["Rename", 1000]
							}
							This:QueueState["Fill", 2000]
							UI:Update["obj_Jetcan", "Popping old can - ${TargetIterator.Value.Name}", "g"]
							return TRUE
						}
					}
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		
		echo Jetcan exists?  ${Entity[GroupID==GROUP_CARGOCONTAINER && HaveLootRights && Distance<LOOT_RANGE && !IsAbandoned](exists)}
		if ${Entity[GroupID==GROUP_CARGOCONTAINER && HaveLootRights && Distance<LOOT_RANGE && !IsAbandoned](exists)}
		{
			Can:Set[${Entity[GroupID==GROUP_CARGOCONTAINER && HaveLootRights && Distance<LOOT_RANGE && !IsAbandoned]}]

			if !${EVEWindow[Inventory].ChildWindowExists[${Can}]}
			{
				UI:Update["obj_Jetcan", "Opening - ${Entity[${Can}].Name}", "g"]
				Entity[${Can}]:Open
				return FALSE
			}
			
			if !${EVEWindow[Inventory].ActiveChildID.Equal[${Can}]}
			{
				EVEWindow[Inventory]:MakeChildActive[${Can}]
				return FALSE
			}
			
			if ${EVEWindow[Inventory].ChildCapacity[${Can}]} - ${EVEWindow[Inventory].ChildUsedCapacity[${Can}]} > 1000
			{
				if ${MyShip.HasOreHold}
				{
					Cargo:PopulateCargoList[OreHold]
				}
				else
				{
					Cargo:PopulateCargoList[Ship]
					Cargo:Filter["CategoryID == CATEGORYID_ORE || GroupID == GROUP_HARVESTABLECLOUD", FALSE]
				}
				Cargo:MoveCargoList[Jetcan, "", ${Can}]
				This:QueueState["Stack", 1000, ${Can}]
				This:QueueState["Fill", 2000]
				return TRUE
			}
		}

		if  ${MyShip.HasOreHold}
		{
			if ${EVEWindow[Inventory].ChildCapacity[ShipOreHold]} != 0
			{
				if ${EVEWindow[Inventory].ChildUsedCapacity[ShipOreHold]} / ${EVEWindow[Inventory].ChildCapacity[ShipOreHold]} >= ${Config.Miner.Threshold} * .01
				{
					Cargo:PopulateCargoList[OreHold]
					if ${Cargo.CargoList.Used}
					{
						Cargo.CargoList.Get[1]:Jettison
					}
					This:QueueState["Idle", 5000]
					if ${Miner.Config.RenameCans}
					{
						This:QueueState["Rename", 2000]
					}
					This:QueueState["FillCan", 1500]
					This:QueueState["Fill", 2000]
					return TRUE
				}
			}
		}
		else
		{
			if ${MyShip.CargoCapacity} != 0
			{
				if ${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity} >= ${Config.Miner.Threshold} * .01
				{
					Cargo:PopulateCargoList[Ship]
					Cargo:Filter["CategoryID == CATEGORYID_ORE || GroupID == GROUP_HARVESTABLECLOUD", FALSE]
					if ${Cargo.CargoList.Used}
					{
						Cargo.CargoList.Get[1]:Jettison
					}
					This:QueueState["Idle", 5000]
					if ${Miner.Config.RenameCans}
					{
						This:QueueState["Rename", 2000]
					}
					This:QueueState["FillCan", 1500]
					This:QueueState["Fill", 2000]
					return TRUE
				}
			}
		}

		return FALSE
	}
	
	member:bool Rename()
	{
		variable index:entity Targets
		variable iterator TargetIterator
		EVE:QueryEntities[Targets, "GroupID==GROUP_CARGOCONTAINER && HaveLootRights && Name =- \"Cargo Container\""]
		Targets:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			do
			{
				if !${CanAges.Element[${TargetIterator.Value.ID}](exists)}
				{
					UI:Update["obj_Jetcan", "Renaming ${TargetIterator.Value.Name}", "g"]
					TargetIterator.Value:SetName[${Me.Corp.Ticker} ${EVE.Time[short]}]
					CanAges:Set[${TargetIterator.Value.ID}, ${LavishScript.RunningTime}]
					if ${Config.Miner.Dropoff_SubType.Equal["Corporate Bookmark Jetcan"]}
					{
						TargetIterator.Value:CreateBookmark["Haul: ${Me.Name} ${EVETime.Time}", "Miner Haul", "Corporation Locations"]
					}
					if ${Config.Miner.Dropoff_SubType.Equal["On-Demand Jetcan"]} && ${Entity[GroupID == GROUP_ASTEROIDBELT && Distance < 500000](exists)}
					{
						OnDemandHaulQueue:Insert[${Entity[GroupID == GROUP_ASTEROIDBELT && Distance < 500000].ID}, ${Me.ID}]
					}
					return TRUE
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		else
		{
			echo Jetcan not found
		}
		return TRUE
	}
	
	member:bool Stack(int64 ID)
	{
		if !${Entity[${ID}](exists)}
		{
			return TRUE
		}
		if !${EVEWindow[Inventory](exists)}
		{
			EVE:Execute[OpenInventory]
			return FALSE
		}
		EVEWindow[ByItemID, ${ID}]:StackAll
		return TRUE
	}
	
	member:bool LootCan(int64 ID)
	{
		variable index:item CargoList
		if !${Entity[${ID}](exists)}
		{
			return TRUE
		}
		if !${EVEWindow[Inventory](exists)}
		{
			EVE:Execute[OpenInventory]
			return FALSE
		}
		Entity[${ID}]:GetCargo[CargoList]
		if ${MyShip.HasOreHold}
		{
			CargoList.Get[1]:MoveTo[MyShip, OreHold, 1]
		}
		else
		{
			CargoList.Get[1]:MoveTo[MyShip, CargoHold, 1]
		}
		return TRUE
	}
	
	member:bool NewCan()
	{
		if !${EVEWindow[Inventory](exists)}
		{
			EVE:Execute[OpenInventory]
			return FALSE
		}
		if ${MyShip.HasOreHold}
		{
			Cargo:PopulateCargoList[OreHold]
		}
		else
		{
			Cargo:PopulateCargoList[Ship]
			Cargo:Filter["CategoryID == CATEGORYID_ORE || GroupID == GROUP_HARVESTABLECLOUD", FALSE]
		}
		Cargo.CargoList.Get[1]:Jettison
		return TRUE
	}
	
	member:bool TransferCan(int64 ID)
	{
		variable int64 Can

		if !${Entity[${ID}](exists)}
		{
			return TRUE
		}

		if !${EVEWindow[Inventory](exists)}
		{
			EVE:Execute[OpenInventory]
			return FALSE
		}
		
		Cargo:PopulateList[Container, "", ${ID}]
		
		if ${Entity[GroupID==GROUP_CARGOCONTAINER && HaveLootRights && Distance<LOOT_RANGE && !IsAbandoned]}
		{
			Can:Set[${Entity[GroupID==GROUP_CARGOCONTAINER && HaveLootRights && Distance<LOOT_RANGE && !IsAbandoned]}]
		}
		else
		{
			return TRUE
		}
		
		if !${CanAges.Element[${Can}](exists)}
		{
			Cargo:MoveCargoList[Jetcan, "", ${Can}]
			return TRUE
		}

		return TRUE
	}
	
	
	member:bool FillCan()
	{
		variable int64 Can
		if !${EVEWindow[Inventory](exists)}
		{
			EVE:Execute[OpenInventory]
			return FALSE
		}
		
		if ${Entity[GroupID==GROUP_CARGOCONTAINER && HaveLootRights && Distance<LOOT_RANGE && !IsAbandoned]}
		{
			Can:Set[${Entity[GroupID==GROUP_CARGOCONTAINER && HaveLootRights && Distance<LOOT_RANGE && !IsAbandoned]}]
		}
		else
		{
			return TRUE
		}
		
		if !${EVEWindow[Inventory].ChildWindowExists[${Can}]}
		{
			UI:Update["obj_Jetcan", "Opening - ${Entity[${Can}].Name}", "g"]
			Entity[${Can}]:Open
			return FALSE
		}
		
		if ${MyShip.HasOreHold}
		{
			Cargo:PopulateCargoList[OreHold]
		}
		else
		{
			Cargo:PopulateCargoList[Ship]
			Cargo:Filter["CategoryID == CATEGORYID_ORE || GroupID == GROUP_HARVESTABLECLOUD", FALSE]
		}
		Cargo:MoveCargoList[Jetcan, "", ${Can}]
		This:QueueState["Stack", 1000, ${Can}]
		return TRUE
	}

}
