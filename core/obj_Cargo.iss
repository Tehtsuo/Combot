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
	variable index:int64 CargoList
	
	variable bool Active=FALSE

	method Initialize()
	{
		This[parent]:Initialize
		UI:Update["obj_Cargo", "Initialized", "g"]
	}

	
	method PopulateCargoList(string location)
	{
		variable index:item MyCargo
		switch ${location} 
		{
			case SHIP
				Me.Ship:GetCargo[MyCargo]
				break
			case SHIPCORPORATEHANGAR
				Me.Ship:GetCorpHangarsCargo[MyCargo]
				break
			case SHIPOREHOLD
				Me.Ship:GetOreHoldCargo[MyCargo]
				break
		}

		variable iterator CargoIterator

		This.CargoList:Clear		
		MyCargo:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		do
		{
			This.CargoList:Insert[${CargoIterator.Value.ID}]
		}
		while ${CargoIterator:Next(exists)}
	}

	method MoveCargoList(string location, string folder="", int64 ID=-1)
	{
		switch ${location} 
		{
			case SHIP
				EVE:MoveItemsTo[This.CargoList, MyShip, CargoHold]
				break
			case SHIPCORPORATEHANGAR
				if ${ID} = -1
				{
					EVE:MoveItemsTo[This.CargoList, MyShip, CorpHangars, ${folder.Escape}]
				}
				else
				{
					EVE:MoveItemsTo[This.CargoList, ${ID}, CorpHangars, ${folder.Escape}]
				}
				break
			case SHIPOREHOLD
				EVE:MoveItemsTo[This.CargoList, MyShip, OreHold]
				break
			case HANGAR
				EVE:MoveItemsTo[This.CargoList, MyStationHangar, Hangar]
				break
			case CORPORATEHANGAR
				echo EVE:MoveItemsTo[This.CargoList, MyStationCorporateHangar, StationCorporateHangar, "${folder.Escape}"]
				EVE:MoveItemsTo[This.CargoList, MyStationCorporateHangar, StationCorporateHangar, ${folder.Escape}]
				break
		}
	}
	
}