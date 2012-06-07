
objectdef obj_Miner
{

	method Initialize()
	{
		This[parent]:Initialize
		This:AssignStateQueueDisplay[obj_MinerStateList@Miner@ComBotTab@ComBot]
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

		This:QueueState["GoToMiningSystem"]
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
			UI:Update["obj_Miner", "No mining system defined!  Check your settings", "r"]
		}
		Move:System[${EVE.Bookmark[${Config.Miner.MiningSystemBookmark}].SolarSystemID}]
		This:QueueState["Traveling"]
		return TRUE
	}
	
	method MoveToField()
	{
		variable int curBelt
		variable index:entity Belts
		variable iterator BeltIterator
		variable int TryCount

		variable string beltsubstring
		if ${Config.Miner.IceMining}
		{
			beltsubstring:Set["ICE FIELD"]
		}
		else
		{
			beltsubstring:Set["ASTEROID BELT"]
		}

		EVE:QueryEntities[Belts, "GroupID = GROUP_ASTEROIDBELT"]
		Belts:GetIterator[BeltIterator]
		if ${BeltIterator:First(exists)}
		{
			; if (${Config.Miner.BookMarkLastPosition} && \
				; ${Bookmarks.StoredLocationExists})
			; {
				; /* We have a stored location, we should return to it. */
				; UI:UpdateConsole["Returning to last location (${Bookmarks.StoredLocation})"]
				; Ship:New_WarpToBookmark["${Bookmarks.StoredLocation}", ${FleetWarp}]
				; This.BeltArrivalTime:Set[${Time.Timestamp}]
				; Bookmarks:RemoveStoredLocation
				; return
			; }

			if ${Config.Miner.UseFieldBookmarks}
			{
				This:MoveToRandomBeltBookMark[${FleetWarp}]
				return
			}

			; We're not at a field already, so find one
			do
			{
				curBelt:Set[${Math.Rand[${Belts.Used}]:Inc[1]}]
				TryCount:Inc
				if ${TryCount} > ${Math.Calc[${Belts.Used} * 10]}
				{
					UI:UpdateConsole["All belts empty!"]
					call ChatIRC.Say "All belts empty!"
					EVEBot.ReturnToStation:Set[TRUE]
					return
				}
			}
			while ( !${Belts[${curBelt}].Name.Find[${beltsubstring}](exists)} || \
					${This.IsBeltEmpty[${Belts[${curBelt}].Name}]} )

			UI:UpdateConsole["EVEBot thinks we're not at a belt.  Warping to Asteroid Belt: ${Belts[${curBelt}].Name}"]
			Ship:WarpToID[${Belts[${curBelt}].ID}, 0, ${FleetWarp}]
			This.BeltArrivalTime:Set[${Time.Timestamp}]
			This.UsingBookMarks:Set[TRUE]
			This.LastBeltIndex:Set[${curBelt}]
		}
	}	
	
	
	
}	