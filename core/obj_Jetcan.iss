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
	method Initialize()
	{
		This[parent]:Initialize
	}
	
	method Enable()
	{
		This:QueueState["Fill", 1500]
	}
	
	method Disable()
	{
		This:Clear
	}
	
	member:bool Fill()
	{
		variable index:item CargoList
		variable index:entity Targets
		variable iterator TargetIterator
	
		if !${Client.InSpace}
		{
			return FALSE
		}
		if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) < 0.10
		{
			return FALSE
		}
		
		EVE:QueryEntities[Targets, "GroupID==GROUP_CARGOCONTAINER && HaveLootRights && Distance<LOOT_RANGE && !IsAbandoned"]
		Targets:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)} && ${EVEWindow[ByName, Inventory](exists)}
		{
			do
			{
				if !${EVEWindow[ByName, Inventory].ChildWindowExists[${TargetIterator.Value}]}
				{
					UI:Update["obj_Jetcan", "Opening - ${TargetIterator.Value.Name}", "g"]
					TargetIterator.Value:OpenCargo
					return FALSE
				}
				if ${Math.Calc[${EVEWindow[ByName, Inventory].ChildCapacity[${TargetIterator.Value}]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[${TargetIterator.Value}]}]} > 1000
				{
					if !${EVEWindow[ByItemID, ${TargetIterator.Value}](exists)}
					{
						EVEWindow[ByName, Inventory]:MakeChildActive[${TargetIterator.Value}]
						return FALSE
					}
					Cargo:PopulateCargoList[SHIP]
					Cargo:MoveCargoList[CONTAINER, "", ${TargetIterator.Value}]
					This:QueueState["Stack", 1000, ${TargetIterator.Value}]
					This:QueueState["Fill", 1500]
					return TRUE
				}
			}
			while ${TargetIterator:Next(exists)}
		}

		if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > 0.10
		{
			Me.Ship:GetCargo[CargoList]
			CargoList.Get[1]:Jettison
			This:QueueState["Idle", 5000]
			This:QueueState["Rename", 2000]
			This:QueueState["Fill", 1500]
			return TRUE
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
			UI:Update["obj_Jetcan", "Renaming ${TargetIterator.Value.Name}", "g"]
			TargetIterator.Value:SetName[${Me.Corp.Ticker} ${EVE.Time[short]}]
			return TRUE
		}
		else
		{
			echo Jetcan not found
		}
		return TRUE
	}
	
	member:bool Stack(int64 ID)
	{
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			MyShip:Open
			return FALSE
		}
		EVE:StackItems[${ID}, CargoHold]
		return TRUE
	}
}