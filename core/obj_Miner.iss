
objectdef obj_Miner inherits obj_State
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
			Asteroids:QueueState["UpdateList"]
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold"]
			This:QueueState["Mine", 50]
		}
	}
	
	member:bool OpenCargoHold()
	{
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["obj_Miner", "Opening inventory", "g"]
			MyShip:OpenCargo[]
			return FALSE
		}
		if !${EVEWindow[byCaption, "active ship"](exists)}
		{
			EVEWindow[byName,"Inventory"]:MakeChildActive[ShipCargo]
		}
		return TRUE
	}
	
	member:bool CheckCargoHold()
	{
		if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > 0.75
		{
			UI:Update["obj_Miner", "Unload trip required", "g"]
			This:Clear
			Move:Bookmark[${Config.Miner.Miner_Dropoff}]
			This:QueueState["Traveling"]
			This:QueueState["Offload"]
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
		if !${EVE.Bookmark[${Config.Miner.MiningSystem}](exists)}
		{
			UI:Update["obj_Miner", "No mining system defined!  Check your settings", "r"]
		}
		Move:System[${EVE.Bookmark[${Config.Miner.MiningSystem}].SolarSystemID}]
		This:QueueState["Traveling"]
		This:QueueState["MoveToBelt"]
		This:QueueState["Traveling"]
		This:QueueState["Mine"]
		return TRUE
	}

	member:bool MoveToBelt()
	{
		if ${Bookmarks.StoredLocationExists}
		{
			UI:Update["obj_Miner","Returning to last location (${Bookmarks.StoredLocation})", "g"]
			Move:Bookmark["${Bookmarks.StoredLocation}"]
			Bookmarks:RemoveStoredLocation
			return TRUE
		}
	
		if ${Config.Miner.UseFieldBookmarks}
		{
			variable index:bookmark Bookmarks
			variable int RandomBelt
			EVE:GetBookmarks[Bookmarks]

			while ${Bookmarks.Used} > 0
			{
				RandomBelt:Set[${Math.Rand[${Bookmarks.Used}]:Inc[1]}]

				if ${Config.Miner.IceMining}
				{
					prefix:Set[${Config.Miner.IceBeltPrefix}]
				}
				else
				{
					prefix:Set[${Config.Miner.BeltPrefix}]
				}

				Label:Set[${Bookmarks[${RandomBelt}].Label}]

				if (${Bookmarks[${RandomBelt}].SolarSystemID} != ${Me.SolarSystemID} || \
					${Label.Left[${prefix.Length}].NotEqual[${prefix}]})
				{
					Bookmarks:Remove[${RandomBelt}]
					Bookmarks:Collapse
					continue
				}

				Move:Bookmark[${BeltBookMarkList[${Bookmarks}].Label}]

				return TRUE
			}	
		}
		else
		{
			variable int curBelt
			variable index:entity Belts
			variable string beltsubstring
			variable int TryCount
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

			do
			{
				curBelt:Set[${Math.Rand[${Belts.Used}]:Inc[1]}]
				TryCount:Inc
				if ${TryCount} > ${Math.Calc[${Belts.Used} * 10]}
				{
					UI:Update["obj_Miner", "All belts empty!", "r"]

					return TRUE
				}
			}
			while ( !${Belts[${curBelt}].Name.Find[${beltsubstring}](exists)} || \
					${This.IsBeltEmpty[${Belts[${curBelt}].Name}]} )

			UI:Update["obj_Miner", "Warping to ${Entity[${Belts[${curBelt}].ID}]}", "g"]
			Move:Object[${Entity[${Belts[${curBelt}].ID}]}]
			return TRUE
		}
	}
	
	member:bool Mine()
	{
		if ${Asteroids.AsteroidList.Used} == 0
		{
			UI:Update["obj_Miner", "${Asteroids.AsteroidList.Used} asteroids found, moving to another belt", "g"]
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold"]
			This:QueueState["GoToMiningSystem"]
			return TRUE
		}
		if ${Ship.ModuleList_MiningLaser.InactiveCount} > 0
		{
			This:QueueState["ActivateLaser"]
			This:QueueState["Mine"]
			return TRUE
		}
		
		
	}
	
	member:bool ActivateLaser()
	{
		variable int MaxTarget = ${MyShip.MaxLockedTargets}
		variable iterator Roid

		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			MaxTarget:Set[${Me.MaxLockedTargets}]
		}

		Asteroids.AsteroidList:GetIterator[Roid]
		if ${Roid:First(exists)}
		do
		{
			;if ${Ship.ModuleList_MiningLaser.Range}
			if  !${Roid.Value.BeingTargeted} && \
				!${Roid.Value.IsLockedTarget} && \
				${Targets.LockedAndLockingTargets} < ${MaxTarget} && \
				${Roid.Value.Distance} < ${MyShip.MaxTargetRange} && \
				${Targets.LockedAndLockingTargets} < ${Ship.ModuleList_MiningLaser.Used}
			{
				UI:Update["obj_Miner", "Locking - ${Roid.Value.Name}", "g"]
				Roid.Value:LockTarget
				return FALSE
			}

			if  !${Ship.ModuleList_MiningLaser.IsActiveOn[${Roid.Value.ID}]} &&\
				${Roid.Value.Distance} < ${Ship.ModuleList_MiningLaser.Range} &&\
				${Ship.ModuleList_MiningLaser.InactiveCount} > 0 &&\
				${Roid.Value.IsLockedTarget}
			{
				UI:Update["obj_Miner", "Activating mining laser - ${Roid.Value.Name}", "g"]
				Ship.ModuleList_MiningLaser:Activate[${Roid.Value.ID}]
				return FALSE
			}
			
		}
		while ${Roid:Next(exists)}
	}
	
}	