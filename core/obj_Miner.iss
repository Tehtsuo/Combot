
objectdef obj_Miner
{

	method Initialize()
	{
		This[parent]:Initialize
		;This:AssignStateQueueDisplay[obj_SalvageStateList@Salvager@ComBotTab@ComBot]
		UI:Update["obj_Miner", "Initialized", "g"]
	}

	method Start()
	{
		UI:Update["obj_Miner", "Started", "g"]
		if ${This.IsIdle}
		{
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold", 5000]
		}
	}
	
	member:bool OpenCargoHold()
	{
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["obj_Miner", "Opening inventory", "g"]
			MyShip:OpenCargo[]
		}
		return TRUE
	}
	
	member:bool CheckCargoHold()
	{
		if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > 0.75
		{
			UI:Update["obj_Miner", "Unload trip required", "g"]
			Move:Bookmark[${Config.Salvager.Salvager_Dropoff}]
			This:QueueState["Traveling"]
			This:QueueState["Offload"]
		}
		if ${EVE.Bookmark[${Config.Miner.MiningSystemBookmark}].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:QueueState["GoToMiningSystem"]
		}
		
		return TRUE;
	}

	member:bool Traveling()
	{
		if ${Move.Traveling} || ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		return TRUE
	}

	member:bool Offload()
	{
		UI:Update["obj_Miner", "Unloading cargo", "g"]
		Cargo:PopulateCargoList[SHIP]
		switch ${Config.Miner.Dropoff_Type}
		{
			case Personal Hangar
				Cargo:MoveCargoList[HANGAR]
				break

			Cargo:MoveCargoList[CORPORATEHANGAR, ${Config.Miner.Dropoff_Type}]
			break
		}
		This:QueueState["GoToMiningSystem"]
		return TRUE
	}
	
	member:bool GoToMiningSystem()
	{
		if !${EVE.Bookmark[${Config.Miner.MiningSystemBookmark}](exists)}
		{
			UI:Update["obj_Miner", "No mining system defined!  Check your settings", "g"]
		}
		Move:Bookmark[${Config.Miner.MiningSystemBookmark}]
		This:QueueState["Traveling"]
		return TRUE
	}
	
	
}	