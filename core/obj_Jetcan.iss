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
	
		if !${Client.InSpace}
		{
			return FALSE
		}

		if !${Client.Inventory}
		{
			return FALSE
		}
		
		
		if  ${MyShip.HasOreHold}
		{
			if 	${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold].UsedCapacity} / ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold].Capacity} < ${Miner.Config.Threshold} * .01 || \
				${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold].UsedCapacity} == 0
			{
				return FALSE
			}
		}
		else
		{
			if 	${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].UsedCapacity} / ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].Capacity} < ${Miner.Config.Threshold} * .01 || \
				${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].UsedCapacity}
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
							if !${EVEWindow[Inventory].ChildWindow[${TargetIterator.Value}](exists)}
							{
								UI:Update["obj_Jetcan", "Opening - ${TargetIterator.Value.Name}", "g"]
								TargetIterator.Value:Open
								return FALSE
							}
							if 	${EVEWindow[Inventory].ChildWindow[${TargetIterator.Value}].UsedCapacity} == -1 || \
								${EVEWindow[Inventory].ChildWindow[${TargetIterator.Value}].Capacity} <= 0
							{
								EVEWindow[Inventory].ChildWindow[${TargetIterator.Value}]:MakeActive
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
		
		
		EVE:QueryEntities[Targets, "GroupID==GROUP_CARGOCONTAINER && HaveLootRights && Distance<LOOT_RANGE && !IsAbandoned"]
		Targets:GetIterator[TargetIterator]
		
		if ${TargetIterator:First(exists)}
			do
			{
				if !${EVEWindow[Inventory].ChildWindow[${TargetIterator.Value}](exists)}
				{
					UI:Update["obj_Jetcan", "Opening - ${TargetIterator.Value.Name}", "g"]
					TargetIterator.Value:Open
					return FALSE
				}
				if 	${EVEWindow[Inventory].ChildWindow[${TargetIterator.Value}].UsedCapacity} == -1 || \
					${EVEWindow[Inventory].ChildWindow[${TargetIterator.Value}].Capacity} <= 0
				{
					EVEWindow[Inventory].ChildWindow[${TargetIterator.Value}]:MakeActive
					return FALSE
				}
				
				if ${EVEWindow[Inventory].ChildWindow[${TargetIterator.Value}].Capacity} - ${EVEWindow[Inventory].ChildWindow[${TargetIterator.Value}].UsedCapacity} > 1000
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
					Cargo:MoveCargoList[Jetcan, "", ${TargetIterator.Value}]
					This:QueueState["Stack", 1000, ${TargetIterator.Value}]
					This:QueueState["Fill", 2000]
					return TRUE
				}
			}
			while ${TargetIterator:Next(exists)}
		
		
		if  ${MyShip.HasOreHold}
		{
			if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold].UsedCapacity} / ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold].Capacity} >= ${Config.Miner.Threshold} * .01
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
		else
		{
			if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].UsedCapacity} / ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].Capacity} >= ${Config.Miner.Threshold} * .01
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
		if !${Client.Inventory}
		{
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
		if !${Client.Inventory}
		{
			return FALSE
		}
		if !${EVEWindow[Inventory].ChildWindow[${ID}](exists)}
		{
			UI:Update["obj_Jetcan", "Opening - ${Entity[${ID}].Name}", "g"]
			TargetIterator.Value:Open
			return FALSE
		}
		if 	${EVEWindow[Inventory].ChildWindow[${ID}].UsedCapacity} == -1 || \
			${EVEWindow[Inventory].ChildWindow[${ID}].Capacity} <= 0
		{
			EVEWindow[Inventory].ChildWindow[${ID}]:MakeActive
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
		if !${Client.Inventory}
		{
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

		if !${Client.Inventory}
		{
			return FALSE
		}
		if !${EVEWindow[Inventory].ChildWindow[${ID}](exists)}
		{
			UI:Update["obj_Jetcan", "Opening - ${Entity[${ID}].Name}", "g"]
			TargetIterator.Value:Open
			return FALSE
		}
		if 	${EVEWindow[Inventory].ChildWindow[${ID}].UsedCapacity} == -1 || \
			${EVEWindow[Inventory].ChildWindow[${ID}].Capacity} <= 0
		{
			EVEWindow[Inventory].ChildWindow[${ID}]:MakeActive
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
		if !${Client.Inventory}
		{
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
		
		if !${EVEWindow[Inventory].ChildWindow[${Can}](exists)}
		{
			UI:Update["obj_Jetcan", "Opening - ${Entity[${Can}].Name}", "g"]
			Entity[${Can}]:Open
			return FALSE
		}
		if 	${EVEWindow[Inventory].ChildWindow[${Can}].UsedCapacity} == -1 || \
			${EVEWindow[Inventory].ChildWindow[${Can}].Capacity} <= 0
		{
			EVEWindow[Inventory].ChildWindow[${Can}]:MakeActive
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
