
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

	method MoveCargoList(string location, string foldername="")
	{
		switch ${location} 
		{
			case SHIP
				EVE:MoveItemsTo[This.CargoList, MyShip, CargoHold]
				break
			case SHIPCORPORATEHANGAR
				EVE:MoveItemsTo[This.CargoList, MyShip, CorpHangars, ${foldername.Escape}]
				break
			case SHIPOREHOLD
				EVE:MoveItemsTo[This.CargoList, MyShip, OreHold]
				break
			case HANGAR
				EVE:MoveItemsTo[This.CargoList, MyStationHangar, Hangar]
				break
			case CORPORATEHANGAR
				echo EVE:MoveItemsTo[This.CargoList, MyStationCorporateHangar, StationCorporateHangar, ${foldername.Escape}]
				EVE:MoveItemsTo[This.CargoList, MyStationCorporateHangar, StationCorporateHangar, ${foldername.Escape}]
				break
		}
	}
	
	method MoveMax(string From, string To)
	{
		
	}
}