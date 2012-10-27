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
	variable string Container
	variable string Action
	variable string QueryString
	variable int Quantity

	method Initialize(string arg_Bookmark, string arg_Action, string arg_LocationType, string arg_LocationSubtype, string arg_Container, string arg_QueryString, int arg_Quantity)
	{
		Bookmark:Set["${arg_Bookmark.Escape}"]
		LocationType:Set[${arg_LocationType}]
		LocationSubtype:Set[${arg_LocationSubtype}]
		Container:Set[${arg_Container}]
		Action:Set[${arg_Action}]
		QueryString:Set["${arg_QueryString.Escape}"]
		Quantity:Set[${arg_Quantity}]
	}
	
	method Set(string arg_Bookmark, string arg_Action, string arg_LocationType, string arg_LocationSubtype, string arg_Container, string arg_QueryString, int arg_Quantity)
	{
		Bookmark:Set["${arg_Bookmark.Escape}"]
		LocationType:Set[${arg_LocationType}]
		LocationSubtype:Set[${arg_LocationSubtype}]
		Container:Set[${arg_Container}]
		Action:Set[${arg_Action}]
		QueryString:Set["${arg_QueryString.Escape}"]
		Quantity:Set[${arg_Quantity}]
	}
	
	method Clear()
	{
		Bookmark:Set[""]
		LocationType:Set[""]
		LocationSubtype:Set[""]
		Container:Set[""]
		Action:Set[""]
		QueryString:Set[""]
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

	
	method PopulateCargoList(string location, int64 ID=-1, string Folder="")
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
			case Corporation Hangar
				Me.Station:GetCorpHangarItems[CargoList]
				break
			case Personal Hangar
				Me.Station:GetHangarItems[CargoList]
				break
			case Container
				Entity[${ID}]:GetCargo[CargoList]
		}


		switch ${Folder}
		{
			case Corporation Folder 1
				This:Filter["SlotID = 4"]
				break
			case Corporation Folder 2
				This:Filter["SlotID = 116"]
				break
			case Corporation Folder 3
				This:Filter["SlotID = 117"]
				break
			case Corporation Folder 4
				This:Filter["SlotID = 118"]
				break
			case Corporation Folder 5
				This:Filter["SlotID = 119"]
				break
			case Corporation Folder 6
				This:Filter["SlotID = 120"]
				break
			case Corporation Folder 7
				This:Filter["SlotID = 121"]
				break
		}
		
	}
	
	method Filter(string Filter)
	{
		if ${CargoList.Used}
		{
			CargoList:RemoveByQuery[${LavishScript.CreateQuery["${Filter}"]}, FALSE]
			CargoList:Collapse
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
	
	method MoveCargoList(string location, string folder="", int64 ID=-1, int Quantity=0)
	{
		variable string TransferFolder
		variable float Volume
		
		
		if ${CargoList.Used} == 1
		{
			variable item CargoItem=${CargoList[1].ID}
			if ${Quantity} > 0
			{
				Volume:Set[${CargoItem.Volume} * ${Quantity}]
			}
			else
			{
				Volume:Set[${CargoItem.Volume} * ${CargoItem.Quantity}]
				Quantity:Set[${CargoItem.Quantity}]
			}

			if ${folder.Length}
			{
				TransferFolder:Set[\, ${folder.Escape}]
			}
			
			switch ${location} 
			{
				case SHIP
					if ${Volume} < ${MyShip.CargoCapacity} - ${MyShip.UsedCargoCapacity}
					{
						CargoItem:MoveTo[MyShip, CargoHold, ${Quantity}]
					}
					else
					{
						CargoItem:MoveTo[MyShip, CargoHold, ${Math.Calc[(${MyShip.CargoCapacity} - ${MyShip.UsedCargoCapacity}) / ${CargoItem.Volume}].Int}]
					}
					break
				case Container
					if ${ID} == -1
					{
						if ${Volume} < ${EVEWindow[ByName, Inventory].ChildCapacity[ShipCorpHangar]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]}
						{
							CargoItem:MoveTo[MyShip, CorpHangars, ${Quantity}${TransferFolder}]
						}
						else
						{
							CargoItem:MoveTo[MyShip, CorpHangars, ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[ShipCorpHangar]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]}) / ${CargoItem.Volume}].Int}${TransferFolder}]
						}
					}
					else
					{
						if ${Volume} < ${EVEWindow[ByName, Inventory].ChildCapacity[${ID}]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[${ID}]}
						{
							CargoItem:MoveTo[${ID}, CorpHangars, ${Quantity}${TransferFolder}]
						}
						else
						{
							CargoItem:MoveTo[${ID}, CorpHangars, ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[ShipCorpHangar]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]}) / ${CargoItem.Volume}].Int}${TransferFolder}]
						}
					}
					break
				case SHIPOREHOLD
					if ${Volume} < ${EVEWindow[ByName, Inventory].ChildCapacity[ShipOreHold]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipOreHold]}
					{
						CargoItem:MoveTo[MyShip, OreHold, ${Quantity}]
					}
					else
					{
						CargoItem:MoveTo[MyShip, OreHold, ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[ShipOreHold]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipOreHold]}) / ${CargoItem.Volume}].Int}]
					}
					break
				case Personal Hangar
					CargoItem:MoveTo[MyStationHangar, Hangar, ${Quantity}]
					break
				case Corporation Hangar
					CargoItem:MoveTo[MyStationCorporateHangar, StationCorporateHangar, ${Quantity}${TransferFolder}]
					break
			}
		}
		else
		{
			variable iterator Cargo
			Volume:Set[0]
			variable index:int64 TransferIndex
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
							if ${Cargo.Value.Quantity} * ${Cargo.Value.Volume} < ${MyShip.CargoCapacity} - ${MyShip.UsedCargoCapacity} - ${Volume}
							{
								TransferIndex:Insert[${Cargo.Value.ID}]
								Volume:Inc[${Math.Calc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]}]
							}
							elseif ${Math.Calc[(${MyShip.CargoCapacity} - ${MyShip.UsedCargoCapacity} - ${Volume}) / ${Cargo.Value.Volume}].Int}
							{
								Cargo.Value:MoveTo[MyShip, CargoHold, ${Math.Calc[(${MyShip.CargoCapacity} - ${MyShip.UsedCargoCapacity} - ${Volume}) / ${Cargo.Value.Volume}].Int}]
								break
							}
						}
						while ${Cargo:Next(exists)}
					EVE:MoveItemsTo[TransferIndex, MyShip, CargoHold]
					break
				case Container
					TransferIndex:Clear
					if ${ID} == -1
					{
						if ${Cargo:First(exists)}
							do
							{
								if ${Cargo.Value.Quantity} * ${Cargo.Value.Volume} < ${EVEWindow[ByName, Inventory].ChildCapacity[ShipCorpHangar]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]} - ${Volume}
								{
									TransferIndex:Insert[${Cargo.Value.ID}]
									Volume:Inc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]
								}
								elseif ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[ShipCorpHangar]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]} - ${Volume}) / ${Cargo.Value.Volume}].Int}
								{
									Cargo.Value:MoveTo[MyShip, CorpHangars, ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[ShipCorpHangar]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]} - ${Volume}) / ${Cargo.Value.Volume}].Int}${TransferFolder}]
									break
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
								if ${Cargo.Value.Quantity} * ${Cargo.Value.Volume} < ${EVEWindow[ByName, Inventory].ChildCapacity[${ID}]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[${ID}]} - ${Volume}
								{
									TransferIndex:Insert[${Cargo.Value.ID}]
									Volume:Inc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]
								}
								elseif ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[${ID}]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[${ID}]} - ${Volume}) / ${Cargo.Value.Volume}].Int}
								{
									Cargo.Value:MoveTo[MyShip, CorpHangars, ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[${ID}]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[${ID}]} - ${Volume}) / ${Cargo.Value.Volume}].Int}${TransferFolder}]
									break
								}
							}
							while ${Cargo:Next(exists)}
						EVE:MoveItemsTo[TransferIndex, ${ID}, CorpHangars${TransferFolder}]
					}
					break
				case SHIPOREHOLD
					TransferIndex:Clear
					if ${Cargo:First(exists)}
						do
						{
							if ${Cargo.Value.Quantity} * ${Cargo.Value.Volume} < ${EVEWindow[ByName, Inventory].ChildCapacity[ShipOreHold]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipOreHold]} - ${Volume}
							{
								TransferIndex:Insert[${Cargo.Value.ID}]
								Volume:Inc[${Cargo.Value.Quantity} * ${Cargo.Value.Volume}]
							}
							elseif ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[ShipOreHold]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipOreHold]} - ${Volume}) / ${Cargo.Value.Volume}].Int}
							{
								Cargo.Value:MoveTo[MyShip, OreHold, ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[ShipOreHold]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipOreHold]} - ${Volume}) / ${Cargo.Value.Volume}].Int}]
								break
							}
						}
						while ${Cargo:Next(exists)}
					EVE:MoveItemsTo[TransferIndex, MyShip, OreHold]
					break
				case Personal Hangar
					EVE:MoveItemsTo[TransferIndex, MyStationHangar, Hangar]
					break
				case Corporation Hangar
					EVE:MoveItemsTo[TransferIndex, MyStationCorporateHangar, StationCorporateHangar${TransferFolder}]
					break
			}
		}
	}
	
	
	method At(string arg_Bookmark, string arg_LocationType = "Personal Hangar", string arg_LocationSubtype = "", string arg_Container = "")
	{
		This.BuildAction:Clear
		This.BuildAction.Bookmark:Set[${arg_Bookmark}]
		This.BuildAction.LocationType:Set[${arg_LocationType}]
		This.BuildAction.LocationSubtype:Set[${arg_LocationSubtype}]
		This.BuildAction.Container:Set[${arg_Container}]
	}
	
	method Load(string arg_Query = "", int arg_Quantity = 0)
	{
		if 	${This.BuildAction.Bookmark.Length} == 0 || \
			${This.BuildAction.LocationType.Length} == 0
		{
			UI:Update["obj_Cargo", "Attempted to queue an incomplete Load cargo action", "r"]
			return
		}
		
		This.CargoQueue:Queue[${This.BuildAction.Bookmark}, Load, ${This.BuildAction.LocationType}, ${This.BuildAction.LocationSubtype}, ${This.BuildAction.Container}, ${arg_Query}, ${arg_Quantity}]
		This.Processing:Set[TRUE]
		if ${This.IsIdle}
		{
			This:QueueState["Process"]
		}
	}
	method Unload(string arg_Query, int arg_Quantity = 0)
	{
		if 	${This.BuildAction.Bookmark.Length} == 0 || \
			${This.BuildAction.LocationType.Length} == 0
		{
			UI:Update["obj_Cargo", "Attempted to queue an incomplete Unload cargo action", "r"]
			return
		}
		
		This.CargoQueue:Queue[${This.BuildAction.Bookmark}, Unload, ${This.BuildAction.LocationType}, ${This.BuildAction.LocationSubtype}, ${This.BuildAction.Container}, ${arg_Query}, ${arg_Quantity}]
		This.Processing:Set[TRUE]
		if ${This.IsIdle}
		{
			This:QueueState["Process"]
		}
	}
	method Move()
	{
		if 	${This.BuildAction.Bookmark.Length} == 0
		{
			UI:Update["obj_Cargo", "Attempted to queue an incomplete Move cargo action", "r"]
			return
		}
		
		This.CargoQueue:Queue[${This.BuildAction.Bookmark}, Move, "", "", "", "", 0]
		This.Processing:Set[TRUE]
		if ${This.IsIdle}
		{
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
		
		UI:Update["obj_Cargo", "Process ${This.CargoQueue.Peek.Action} @ ${This.CargoQueue.Peek.Bookmark} - ${This.CargoQueue.Peek.LocationType}", "g", TRUE]
		
		Move:Bookmark[${This.CargoQueue.Peek.Bookmark}, TRUE]
		This:QueueState["Traveling"]
		This:QueueState["WarpFleetMember"]
		This:QueueState["Traveling"]
		This:QueueState["${This.CargoQueue.Peek.Action}"]
		This:QueueState["Stack"]
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
	
	member:bool WarpFleetMember()
	{
		if ${Local[${This.CargoQueue.Peek.Container}](exists)}
		{
			Move:Fleetmember[${Local[${This.CargoQueue.Peek.Container}].ID}]
		}
		return TRUE
	}
	
	member:bool Dequeue()
	{
		This.CargoQueue:Dequeue
		return TRUE
	}

	member:bool Stack(bool OpenedCorpHangar=FALSE, bool StackedShip=FALSE)
	{
		variable int64 Container

	
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["obj_Cargo", "Making sure inventory is open", "g"]
			MyShip:Open
			return FALSE
		}

		
		if ${Me.InSpace} && ${This.CargoQueue.Peek.Action.NotEqual[Move]}
		{
			if ${Entity[Name = "${This.CargoQueue.Peek.Container}"](exists)}
			{
				Container:Set[${Entity[Name = "${This.CargoQueue.Peek.Container}"].ID}]
				if ${Entity[${Container}].Distance} > LOOT_RANGE
				{
					Move:Approach[${Container}, LOOT_RANGE]
					return FALSE
				}
				else
				{
					if !${EVEWindow[ByName, Inventory].ChildWindowExists[${Container}]}
					{
						UI:Update["obj_Cargo", "Opening ${This.CargoQueue.Peek.Container}", "g"]
						Entity[${Container}]:Open
						return FALSE
					}
					if !${EVEWindow[ByItemID, ${Container}](exists)} 
					{
						EVEWindow[ByName, Inventory]:MakeChildActive[${Container}]
						return FALSE
					}
					EVE:StackItems[${Container}, CorpHangars]
					return TRUE
				}
			}
			else
			{
				UI:Update["obj_Cargo", "Cargo action Stack failed - Container not found", "r"]
				return TRUE
			}
		
		}

		if ${EVEWindow[ByName, Inventory].ChildWindowExists[Corporation Hangars]} && !${OpenedCorpHangar}
		{
			EVEWindow[ByName, Inventory]:MakeChildActive[Corporation Hangars]
			This:InsertState["Stack", 2000, TRUE]
			return TRUE
		}
			
		if !${StackedShip}
		{
			EVE:StackItems[MyShip, CargoHold]
			This:InsertState["Stack", 2000, "TRUE, TRUE"]
			return TRUE
		}
		
		switch ${This.BuildAction.LocationType}
		{
			case Personal Hangar
				EVE:StackItems[MyStationHangar, Hangar]
				break
			case Corporation Folder
				EVE:StackItems[MyStationCorporateHangar, StationCorporateHangar]
				break
		}
		
		return TRUE
	}
	
	member:bool Unload(bool OpenedCorpHangar=FALSE)
	{
		variable int64 Container

		if ${Me.InSpace}
		{
			if ${Entity[Name = "${This.CargoQueue.Peek.Container}"](exists)}
			{
				Container:Set[${Entity[Name = "${This.CargoQueue.Peek.Container}"].ID}]
				if ${Entity[${Container}].Distance} > LOOT_RANGE
				{
					Move:Approach[${Container}, LOOT_RANGE]
					return FALSE
				}
				else
				{
					if !${EVEWindow[ByName, Inventory].ChildWindowExists[${Container}]}
					{
						UI:Update["obj_Cargo", "Opening ${This.CargoQueue.Peek.Container}", "g"]
						Entity[${Container}]:Open
						return FALSE
					}
					if !${EVEWindow[ByItemID, ${Container}](exists)} 
					{
						EVEWindow[ByName, Inventory]:MakeChildActive[${Container}]
						return FALSE
					}
					Cargo:PopulateCargoList[SHIP]
					Cargo:Filter[${This.CargoQueue.Peek.QueryString}]
					Cargo:MoveCargoList[Container, ${This.CargoQueue.Peek.LocationSubtype}, ${Container}, ${This.CargoQueue.Peek.Quantity}]
					return TRUE
				}
			}
			else
			{
				UI:Update["obj_Cargo", "Cargo action Unload failed - Container not found", "r"]
				return TRUE
			}
		}
		
		if ${EVEWindow[ByName, Inventory].ChildWindowExists[Corporation Hangars]} && !${OpenedCorpHangar}
		{
			EVEWindow[ByName, Inventory]:MakeChildActive[Corporation Hangars]
			This:InsertState["Unload", 2000, TRUE]
			return TRUE
		}
		
		Cargo:PopulateCargoList[SHIP]
		Cargo:Filter[${This.CargoQueue.Peek.QueryString}]
		Cargo:MoveCargoList[${This.CargoQueue.Peek.LocationType}, ${This.CargoQueue.Peek.LocationSubtype}, ${Container}, ${This.CargoQueue.Peek.Quantity}]
		return TRUE
	}
	
	member:bool Load(bool OpenedCorpHangar=FALSE)
	{
		variable int64 Container

		if ${Me.InSpace}
		{
			if ${Entity[Name = "${This.CargoQueue.Peek.Container}"](exists)}
			{
				Container:Set[${Entity[Name = "${This.CargoQueue.Peek.Container}"].ID}]
				if ${Entity[${Container}].Distance} > LOOT_RANGE
				{
					Move:Approach[${Container}, LOOT_RANGE]
					return FALSE
				}
				else
				{
					if !${EVEWindow[ByName, Inventory].ChildWindowExists[${Container}]}
					{
						UI:Update["obj_Cargo", "Opening ${This.CargoQueue.Peek.Container}", "g"]
						Entity[${Container}]:Open
						return FALSE
					}
					if !${EVEWindow[ByItemID, ${Container}](exists)} 
					{
						EVEWindow[ByName, Inventory]:MakeChildActive[${Container}]
						return FALSE
					}
					Cargo:PopulateCargoList[Container, ${Container}, ${This.CargoQueue.Peek.LocationSubtype}]
					Cargo:Filter[${This.CargoQueue.Peek.QueryString}]
					Cargo:MoveCargoList[SHIP, "", -1, ${This.CargoQueue.Peek.Quantity}]
					return TRUE
				}
			}
			else
			{
				UI:Update["obj_Cargo", "Cargo action Load failed - Container not found", "r"]
				return TRUE
			}
		}

		if ${EVEWindow[ByName, Inventory].ChildWindowExists[Corporation Hangars]} && !${OpenedCorpHangar}
		{
			EVEWindow[ByName, Inventory]:MakeChildActive[Corporation Hangars]
			This:InsertState["Load", 2000, TRUE]
			return TRUE
		}
		
		Cargo:PopulateCargoList[${This.CargoQueue.Peek.LocationType}, 0, ${This.CargoQueue.Peek.LocationSubtype}]
		Cargo:Filter[${This.CargoQueue.Peek.QueryString}]
		Cargo:MoveCargoList[SHIP, "", -1, ${This.CargoQueue.Peek.Quantity}]
		return TRUE
	}
	member:bool Move()
	{
		return TRUE
	}
	
}