
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
	
	method MoveMax(string From, string To)
	{
		
	}
}