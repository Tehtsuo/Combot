
objectdef obj_Cargo
{
	variable index:int64 CargoList


	method PopulateCargoList(string location)
	{
		switch ${location} 
		{
			case SHIP
				Me.Ship:GetCargo[This.MyCargo]
				break
			case SHIPCORPORATEHANGAR
				Me.Ship:GetCorpHangarsCargo[This.MyCargo]
				break
			case SHIPOREHOLD
				Me.Ship:GetOreHoldCargo[This.MyCargo]
				break
		}

		variable iterator CargoIterator

		This.CargoToTransfer:Clear		
		This.MyCargo:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		do
		{
			This.CargoToTransfer:Insert[${CargoIterator.Value.ID}]
		}
		while ${CargoIterator:Next(exists)}
	}

	method MoveCargoList(string location, string foldername="")
	{
		switch ${location} 
		{
			case SHIP
				EVE:MoveItemsTo[CargoList, MyShip, CargoHold]
				break
			case SHIPCORPORATEHANGAR
				EVE:MoveItemsTo[CargoList, MyShip, CorpHangars, ${foldername}]
				break
			case SHIPOREHOLD
				EVE:MoveItemsTo[CargoList, MyShip, OreHold]
				break
			case HANGAR
				EVE:MoveItemsTo[CargoList, MyStationHangar, Hangar]
				break
			case CORPORATEHANGAR
				EVE:MoveItemsTo[CargoList, MyStationCorporateHangar, StationCorporateHangar, ${foldername}]
				break
		}
	}
}