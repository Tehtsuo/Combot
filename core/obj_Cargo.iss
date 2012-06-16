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

objectdef obj_Cargo inherits obj_State
{
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
							Cargo.Value:MoveTo[MyShip, CargoHold, ${Math.Calc[(${MyShip.CargoCapacity} - ${MyShip.UsedCargoCapacity} - ${Volume}) / ${Cargo.Value.Volume}]}]
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
								Cargo.Value:MoveTo[MyShip, CorpHangars, ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[ShipCorpHangar]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]} - ${Volume}) / ${CargoIterator.Value.Volume}]}${TransferFolder}]
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
								Cargo.Value:MoveTo[${ID}, CorpHangars, ${Math.Calc[(${EVEWindow[ByName, Inventory].ChildCapacity[ShipCorpHangar]} - ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]} - ${Volume}) / ${CargoIterator.Value.Volume}]}${TransferFolder}]
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
			case SHIPOREHOLD
				EVE:MoveItemsTo[TransferIndex, MyShip, OreHold]
				break
			case HANGAR
				EVE:MoveItemsTo[TransferIndex, MyStationHangar, Hangar]
				break
			case CORPORATEHANGAR
				EVE:MoveItemsTo[TransferIndex, MyStationCorporateHangar, StationCorporateHangar${TransferFolder}]
				break
		}
	}
	
}