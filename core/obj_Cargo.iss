
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

		TripHauled:Set[0]
		This.CargoToTransfer:Clear		
		This.MyCargo:GetIterator[CargoIterator]
		if ${CargoIterator:First(exists)}
		do
		{
			This.CargoToTransfer:Insert[${CargoIterator.Value.ID}]
		}
		while ${CargoIterator:Next(exists)}

	}


}