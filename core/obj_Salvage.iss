objectdef obj_Salvage inherits obj_State
{

	method Initialize()
	{
		This[parent]:Initialize
		UI:Update["obj_Salvage", "Initialized", "g"]
	}

	method Start()
	{
		This:QueueState["CheckBookmarks"]
	}
	
	method Stop()
	{
		Move:Bookmark["Station"]
		This:QueueState["Traveling"]
	}

	member:bool CheckBookmarks()
	{
		//Scan for corp salvage bookmarks
		//Only return true once one is found
		variable index:bookmark Bookmarks
		variable iterator BookmarkIterator
		variable string Target
		variable string Time
		variable bool BookmarkFound
		
		BookmarkFound:Set[false]
		
		Eve:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		if ${BookmarkIterator:First(exists)}
		do
		{
			if ${BookmarkIterator.Value.Label.Left[8].Upper.Equal["SALVAGE:"]} && ${BookmarkIterator.Value.TimeCreated.Compare[${Time}]} < 0
			{
				Target:Set[${BookmarkIterator.Value.Label}]
				Time:Set[${BookmarkIterator.Value.TimeCreated}]
				BookmarkFound:Set[True]
			}
		}
		while ${BookmarkIterator:Next(exists)}
		
		if ${BookmarkFound}
		{
			Move:Bookmark[Target]
			This:QueueState["Traveling"]
			This:QueueState["SalvageWrecks"]
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold", 5000]
			return true
		}
		return false
	}

	member:bool Traveling()
	{
		return !${Move.Traveling}
	}

	member:bool SalvageWrecks()
	{
		//Tractor, loot and salvage
		//True when done 
	}
	
	member:bool OpenCargoHold()
	{
		MyShip:OpenCargo[]
		return true
	}
	
	Member:bool CheckCargoHold()
	{
		if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > 0.75
		{
			Move:Bookmark["Station"]
			This:QueueState["Traveling"]
			This:QueueState["Offload"]
		}
		This:QueueState["CheckBookmarks"]
		return true;
	}

	member:bool Offload()
	{
		//Transfer stuff to corp hanger
	}

}