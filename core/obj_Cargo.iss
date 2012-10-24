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

objectdef obj_CargoAction
{
	variable string Bookmark
	variable string LocationType
	variable string LocationSubtype
	variable string Action
	variable string Query
	variable int Quantity

	method Initialize(string arg_Bookmark, string arg_Action, string arg_LocationType, string arg_LocationSubtype, string arg_Query, int arg_Quantity)
	{
		Bookmark:Set["${arg_Bookmark.Escape}"]
		LocationType:Set[${arg_LocationType}]
		LocationSubtype:Set[${arg_LocationSubtype}]
		Action:Set[${arg_Action}]
		Query:Set["${arg_Query.Escape}"]
		Quantity:Set[${arg_Quantity}]
	}
	
	method Set(string arg_Bookmark, string arg_Action, string arg_LocationType, string arg_LocationSubtype, string arg_Query, int arg_Quantity)
	{
		Bookmark:Set["${arg_Bookmark.Escape}"]
		LocationType:Set[${arg_LocationType}]
		LocationSubtype:Set[${arg_LocationSubtype}]
		Action:Set[${arg_Action}]
		Query:Set["${arg_Query.Escape}"]
		Quantity:Set[${arg_Quantity}]
	}
	
	method Clear()
	{
		Bookmark:Set[""]
		LocationType:Set[""]
		LocationSubtype:Set[""]
		Action:Set[""]
		Query:Set[""]
		Quantity:Set[0]
	}
}

objectdef obj_Cargo inherits obj_State
{
	variable bool Processing=FALSE
	variable queue:obj_CargoAction CargoQueue
	variable obj_CargoAction BuildAction
	variable index:item CargoList
	
	variable bool Active=FALSE

	method Initialize()
	{
		This[parent]:Initialize
	}

	
	method PopulateCargoList(string location, int64 ID=-1)
	{
		switch ${location} 
		{
			case SHIP
				Me.Ship:GetCargo[CargoList]
				break
			case SHIPCORPORATEHANGAR
				Me.Ship:GetCorpHangarsCargo[CargoList]
				break
			case SHIPOREHOLD
				Me.Ship:GetOreHoldCargo[CargoList]
				break
			case CONTAINERCORPORATEHANGAR
				Entity[${ID}]:GetCorpHangarsCargo[CargoList]
				break
			case STATIONCORPORATEHANGAR
				Me.Station:GetCorpHangarItems[CargoList]
				break
			case STATIONHANGAR
				Me.Station:GetHangarItems[CargoList]
				break
			case CONTAINER
				Entity[${ID}]:GetCargo[CargoList]
		}
	}
	
	method Filter(string Filter, bool Mode=TRUE)
	{
		if ${CargoList.Used}
		{
			CargoList:RemoveByQuery[${LavishScript.CreateQuery["${Filter}"]}, ${Mode}]
		}
	}
	
	method DontPopCan()
	{
		variable iterator Cargo
		variable index:int64 TransferIndex
		variable float Volume = 0
		variable bool EarlyBreak=FALSE
		variable int64 LastItem = -1

		CargoList:GetIterator[Cargo]
		if ${Cargo:First(exists)}
		{
			do
			{
				if !${LastItem.Equal[-1]}
				{
					TransferIndex:Insert[${LastItem}]
				}
				if (${Cargo.Value.Quantity} * ${Cargo.Value.Volume}) < ${Math.Calc[${MyShip.CargoCapacity} - ${MyShip.UsedCargoCapacity} - ${Volume}]}
				{
					LastItem:Set[${Cargo.Value.ID}]
					Volume:Inc[${Math.Calc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]}]
				}
				else
				{
					EarlyBreak:Set[TRUE]
					Cargo.Value:MoveTo[MyShip, CargoHold, ${Math.Calc[(${MyShip.CargoCapacity} - ${MyShip.UsedCargoCapacity} - ${Volume}) / ${Cargo.Value.Volume} - 1]}]
					break
				}
			}
			while ${Cargo:Next(exists)}
			Cargo:Last
			if !${EarlyBreak}
			{
				if ${Cargo.Value.Quantity} > 1 
				{
					Cargo.Value:MoveTo[MyShip, CargoHold, ${Math.Calc[${Cargo.Value.Quantity} - 1]}]
				}
			}
			if ${TransferIndex.Used} > 0
			{
				EVE:MoveItemsTo[TransferIndex, MyShip, CargoHold]
			}
		}
	}
	
	method MoveCargoList(string location, string folder="", int64 ID=-1)
	{
		variable iterator Cargo
		variable float Volume = 0
		variable index:int64 TransferIndex
		variable string TransferFolder
		CargoList:GetIterator[Cargo]

		if ${Cargo:First(exists)}
			do
			{
				TransferIndex:Insert[${Cargo.Value.ID}]
			}
			while ${Cargo:Next(exists)}

		if ${folder.Length}
		{
			TransferFolder:Set[\, ${folder.Escape}]
		}
		
		switch ${location} 
		{
			case SHIP
				TransferIndex:Clear
				if ${Cargo:First(exists)}
					do
					{
						if (${Cargo.Value.Quantity} * ${Cargo.Value.Volume}) < ${Math.Calc[${MyShip.CargoCapacity} - ${MyShip.UsedCargoCapacity} - ${Volume}]}
						{
							TransferIndex:Insert[${Cargo.Value.ID}]
							Volume:Inc[${Math.Calc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]}]
						}
						else
						{
							if ${Math.Calc[(${MyShip.CargoCapacity} - ${MyShip.UsedCargoCapacity} - ${Volume}) / ${Cargo.Value.Volume}].Int}
							{
								Cargo.Value:MoveTo[MyShip, CargoHold, ${Math.Calc[(${MyShip.CargoCapacity} - ${MyShip.UsedCargoCapacity} - ${Volume}) / ${Cargo.Value.Volume}].Int}]
							}
							break
						}
					}
					while ${Cargo:Next(exists)}
				EVE:MoveItemsTo[TransferIndex, MyShip, CargoHold]
				break
			case SHIPCORPORATEHANGAR
				TransferIndex:Clear
				if ${ID} == -1
				{
					if ${Cargo:First(exists)}
						do
						{
							if ${Math.Calc[${Volume} + ${Cargo.Value.Volume} * ${Cargo.Value.Quantity}]} > ${Math.Calc[${EVEWindow[ByName, Inventory].ChildCapacity[ShipCorpHangar]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]}]}
							{
								Cargo.Value:MoveTo[MyShip, CorpHangars, ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[ShipCorpHangar]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]} - ${Volume}) / ${Cargo.Value.Volume}]}${TransferFolder}]
								break
							}
							else
							{
								Volume:Inc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]
								TransferIndex:Insert[${Cargo.Value.ID}]
							}
						}
						while ${Cargo:Next(exists)}
					EVE:MoveItemsTo[TransferIndex, MyShip, CorpHangars${TransferFolder}]
				}
				else
				{
					if ${Cargo:First(exists)}
						do
						{
							if ${Math.Calc[${Volume} + ${Cargo.Value.Volume} * ${Cargo.Value.Quantity}]} > ${Math.Calc[${EVEWindow[ByName, Inventory].ChildCapacity[ShipCorpHangar]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]}]}
							{
								Cargo.Value:MoveTo[${ID}, CorpHangars, ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[ShipCorpHangar]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]} - ${Volume}) / ${Cargo.Value.Volume}]}${TransferFolder}]
								break
							}
							else
							{
								Volume:Inc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]
								TransferIndex:Insert[${Cargo.Value.ID}]
							}
						}
						while ${Cargo:Next(exists)}
					EVE:MoveItemsTo[TransferIndex, ${ID}, CorpHangars${TransferFolder}]
				}
				break
			case CONTAINER
				TransferIndex:Clear
				if ${Cargo:First(exists)}
					do
					{
						if ${Math.Calc[${Volume} + (${Cargo.Value.Volume} * ${Cargo.Value.Quantity})]} > ${Math.Calc[${EVEWindow[ByName, Inventory].ChildCapacity[${ID}]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[${ID}]}]}
						{
							Cargo.Value:MoveTo[${ID}, CargoHold, ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[${ID}]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[${ID}]} - ${Volume}) / ${Cargo.Value.Volume}]}]
							break
						}
						else
						{
							Volume:Inc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]
							TransferIndex:Insert[${Cargo.Value.ID}]
						}
					}
					while ${Cargo:Next(exists)}
				EVE:MoveItemsTo[TransferIndex, ${ID}, CargoHold]
				break
			case SHIPOREHOLD
				TransferIndex:Clear
				if ${Cargo:First(exists)}
					do
					{
						if ${Math.Calc[${Volume} + ${Cargo.Value.Volume} * ${Cargo.Value.Quantity}]} > ${Math.Calc[${EVEWindow[ByName, Inventory].ChildCapacity[ShipOreHold]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipOreHold]}]}
						{
							if ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[ShipOreHold]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipOreHold]} - ${Volume}) / ${Cargo.Value.Volume}].Round}
							{
								Cargo.Value:MoveTo[MyShip, OreHold, ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[ShipOreHold]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipOreHold]} - ${Volume}) / ${Cargo.Value.Volume}].Round}]
							}
							break
						}
						else
						{
							Volume:Inc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]
							TransferIndex:Insert[${Cargo.Value.ID}]
						}
					}
					while ${Cargo:Next(exists)}
				EVE:MoveItemsTo[TransferIndex, MyShip, OreHold]
				break
			case HANGAR
				EVE:MoveItemsTo[TransferIndex, MyStationHangar, Hangar]
				break
			case CORPORATEHANGAR
				echo EVE:MoveItemsTo[TransferIndex, MyStationCorporateHangar, StationCorporateHangar${TransferFolder}]
				EVE:MoveItemsTo[TransferIndex, MyStationCorporateHangar, StationCorporateHangar${TransferFolder}]
				break
		}
	}
	
	
	; Starting cargo rewrite  /\ Needs tweaking  \/ New stuff
	
	method At(string arg_Bookmark, string arg_LocationType = "STATIONHANGAR", string arg_LocationSubtype = "")
	{
		if 	${This.BuildAction.Query.Length} == 0 || \
			${This.BuildAction.Action.Length} == 0 || \
			${arg_Bookmark.Length} == 0
		{
			UI:Update["obj_Cargo", "Attempted to queue a cargo operation without a complete Build Action", "r"]
		}
	}
	
	method Load(string arg_Query, int arg_Quantity = 0)
	{
		This.BuildAction.Query:Set[${arg_Query}]
		This.BuildAction.Quantity:Set[${arg_Quantity}]
		This.BuildAction.Action:Set[Load]
	}
	method Unload(string arg_Query, int arg_Quantity = 0)
	{
		This.BuildAction.Query:Set[${arg_Query}]
		This.BuildAction.Quantity:Set[${arg_Quantity}]
		This.BuildAction.Action:Set[Unload]
	}

	
		This.CargoQueue:Queue[arg_Bookmark, arg_Action, string arg_LocationType, string arg_LocationSubtype, arg_Query, arg_Quantity]
		This.Processing:Set[TRUE]
		if ${This.IsIdle}
		{
			This:Clear
			This:QueueState["Process"]
		}
	}
	
	
	
	member:bool Process()
	{
		if ${This.CargoQueue.Used} == 0
		{
			This.Processing:Set[FALSE]
			return TRUE
		}
		
		Move:Bookmark[${This.CargoQueue.Peek.Bookmark}]
		This:QueueState["Traveling"]
		This:QueueState["${This.CargoQueue.Peek.Action}"]
		This:QueueState["Dequeue"]
		This:QueueState["Process"]
		return TRUE
	}
	
	member:bool Traveling()
	{
		if ${Move.Traveling} || ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		return TRUE
	}
	
	member:bool Unload()
	{
		variable int64 Container

		if ${Me.InSpace}
		{
			if ${Entity[Name = "${This.CargoQueue.Peek.LocationSubtype}"](exists)}
			{
				Container:Set[${Entity[Name = "${This.CargoQueue.Peek.LocationSubtype}"].ID}]
			}
		}
	}
}