objectdef obj_Salvage inherits obj_State
{
	variable obj_LootCans LootCans

	method Initialize()
	{
		This[parent]:Initialize
		UI:Update["obj_Salvage", "Initialized", "g"]
	}

	method Start()
	{
		UI:Update["obj_Salvage", "Started", "g"]
		This:QueueState["CyclePeopleAndPlaces", 500]
		This:QueueState["CyclePeopleAndPlaces", 500]
		This:QueueState["CheckBookmarks"]
	}
	
	method Stop()
	{
		UI:Update["obj_Salvage", "Salvage stopped, setting destination to station", "g"]
		This:Clear()
		Move:Bookmark["Salvager Home Base"]
		This:QueueState["Traveling"]
	}

	member:bool CheckBookmarks()
	{
	
		variable index:bookmark Bookmarks
		variable iterator BookmarkIterator
		variable string Target
		variable string BookmarkTime="24:00"
		variable bool BookmarkFound
		

		
		
		BookmarkFound:Set[FALSE]
		
		EVE:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		if ${BookmarkIterator:First(exists)}
		do
		{
			
			if ${BookmarkIterator.Value.Label.Left[8].Upper.Equal["SALVAGE:"]} && ${BookmarkIterator.Value.TimeCreated.Compare[${BookmarkTime}]} < 0
			{
				Target:Set[${BookmarkIterator.Value.Label}]
				BookmarkTime:Set[${BookmarkIterator.Value.TimeCreated}]
				BookmarkFound:Set[TRUE]
			}
		}
		while ${BookmarkIterator:Next(exists)}
		
		if ${BookmarkFound}
		{
			UI:Update["obj_Salvage", "Setting course for ${Target}", "g"]
			Move:Bookmark[${Target}]
			This:QueueState["Traveling"]
			This:QueueState["Log", 1000, "Salvaging at ${Target}"]
			This:QueueState["SalvageWrecks", 500]
			This:QueueState["DeleteBookmark", 1000, ${Target}]
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold", 5000]
			return TRUE
		}

		
		UI:Update["obj_Salvage", "No salvage bookmark found - returning to station", "g"]
		Move:Bookmark["Salvager Home Base"]
		This:QueueState["Traveling"]
		This:QueueState["Offload"]
		This:QueueState["CheckBookmarks"]
		return TRUE
	}

	member:bool Traveling()
	{
		if ${Move.Traveling} || ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		return TRUE
	}
	
	member:bool Log(string text)
	{
		UI:Update["obj_Salvage", "${text}", "g"]
		return TRUE
	}

	member:bool SalvageWrecks()
	{
		variable index:entity TargetIndex
		variable iterator TargetIterator
		variable queue:int LootRangeAndTractored
		variable int MaxTarget = ${MyShip.MaxLockedTargets}
		
		if ${Targets.NPC}
		{
			UI:Update["obj_Salvage", "Pocket has NPCs - returning to station", "g"]
			This:Clear
			Move:Bookmark["Salvager Home Base"]
			This:QueueState["Traveling"]
			This:QueueState["Offload"]
			This:QueueState["CheckBookmarks"]
			return TRUE
		}
		
		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			MaxTarget:Set[${Me.MaxLockedTargets}]
		}
		
		EVE:QueryEntities[TargetIndex, "(GroupID==GROUP_WRECK || GroupID==GROUP_CARGOCONTAINER) && HaveLootRights"]
		TargetIndex:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			LootCans:Enable
			do
			{
				if  !${TargetIterator.Value.BeingTargeted} && \
					!${TargetIterator.Value.IsLockedTarget} && \
					${Targets.LockedAndLockingTargets} < ${MaxTarget} && \
					${TargetIterator.Value.Distance} < ${MyShip.MaxTargetRange}
				{
					UI:Update["obj_Salvage", "Locking - ${TargetIterator.Value.Name}", "g"]
					TargetIterator.Value:LockTarget
					return FALSE
				}
				if ${TargetIterator.Value.Distance} > ${Ship.Module_TractorBeams_Range}
				{
					Move:Approach[${TargetIterator.Value}]
					return FALSE
				}
				echo ${TargetIterator.Value.Name} - ${Ship.ModuleList_TractorBeams.IsActiveOn[${TargetIterator.Value.ID}]}
				if  !${Ship.ModuleList_TractorBeams.IsActiveOn[${TargetIterator.Value.ID}]} &&\
					${TargetIterator.Value.Distance} < ${Ship.ModuleList_TractorBeams.Range} &&\
					${TargetIterator.Value.Distance} > LOOT_RANGE &&\
					${Ship.ModuleList_TractorBeams.InactiveCount} > 0 &&\
					${TargetIterator.Value.IsLockedTarget}
				{
					UI:Update["obj_Salvage", "Activating tractor beam - ${TargetIterator.Value.Name}", "g"]
					Ship.ModuleList_TractorBeams:Activate[${TargetIterator.Value.ID}]
					return FALSE
				}
				; if  ${Ship.ModuleList_TractorBeams.IsActiveOn[${TargetIterator.Value.ID}]} &&\
					; ${TargetIterator.Value.Distance} < LOOT_RANGE
				; {
					; UI:Update["obj_Salvage", "Deactivating tractor beam - ${TargetIterator.Value.Name}", "g"]
					; Ship.ModuleList_TractorBeams:Deactivate[${TargetIterator.Value.ID}]
				; }
				if  !${Ship.ModuleList_Salvagers.IsActiveOn[${TargetIterator.Value.ID}]} &&\
					${TargetIterator.Value.Distance} < ${Ship.ModuleList_Salvagers.Range} &&\
					${Ship.ModuleList_Salvagers.InactiveCount} > 0 &&\
					${TargetIterator.Value.IsLockedTarget}
				{
					UI:Update["obj_Salvage", "Activating salvager - ${TargetIterator.Value.Name}", "g"]
					Ship.ModuleList_Salvagers:Activate[${TargetIterator.Value.ID}]
					return FALSE
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		else
		{
			LootCans:Disable
			if ${Entity[GroupID == GROUP_WARPGATE](exists)}
			{
				UI:Update["obj_Salvage", "Gate found, activating", "g"]
				This:Clear
				Move:Gate[${Entity[GroupID == GROUP_WARPGATE].ID}]
				This:QueueState["Idle", 5000]
				This:QueueState["Traveling"]
				This:QueueState["SalvageWrecks", 500]
				This:QueueState["OpenCargoHold"]
				This:QueueState["CheckCargoHold", 5000]
			}			
			return TRUE
		}
		return FALSE
	}
	
	member:bool DeleteBookmark(string bookmarkname)
	{
		if !${Entity[GroupID == GROUP_WARPGATE](exists)}
		{
			UI:Update["obj_Salvage", "Removing bookmark - ${bookmarkname}", "g"]
			EVE.Bookmark[${bookmarkname}]:Remove
		}
		else
		{
			UI:Update["obj_Salvage", "Gate present: Not removing bookmark - ${bookmarkname}", "g"]
		}
		return TRUE
	}
	
	member:bool OpenCargoHold()
	{
		MyShip:OpenCargo[]
		return TRUE
	}
	
	member:bool CheckCargoHold()
	{
		if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > 0.75
		{
			Move:Bookmark["Salvager Home Base"]
			This:QueueState["Traveling"]
			This:QueueState["Offload"]
		}
		This:QueueState["CyclePeopleAndPlaces", 500]
		This:QueueState["CyclePeopleAndPlaces", 500]
		This:QueueState["CheckBookmarks"]
		return TRUE;
	}

	member:bool CyclePeopleAndPlaces()
	{
		EVE:Execute[OpenPeopleAndPlaces]
		return TRUE
	}
	
	member:bool Offload()
	{
		;Transfer stuff to corp hanger
		return FALSE
	}
	
}






objectdef obj_LootCans inherits obj_State
{
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		UI:Update["obj_LootCans", "Initialized", "g"]
	}
	
	method Enable()
	{
		This:QueueState["Loot", 1500]
	}
	
	method Disable()
	{
		This:Clear
	}
	
	member:bool Loot()
	{
		variable index:entity Targets
		variable iterator TargetIterator
	
		if !${Client.InSpace}
		{
			return FALSE
		}

		EVE:QueryEntities[Targets, "(GroupID==GROUP_WRECK || GroupID==GROUP_CARGOCONTAINER) && HaveLootRights && !IsWreckEmpty && Distance<LOOT_RANGE"]
		Targets:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			do
			{
				if ${EVEWindow[ByItemID, ${TargetIterator.Value}](exists)}
				{
					UI:Update["obj_Salvage", "Looting - ${TargetIterator.Value.Name}", "g"]
					EVEWindow[ByItemID, ${TargetIterator.Value}]:LootAll
					return FALSE
				}
				if !${EVEWindow[ByItemID, ${TargetIterator.Value}](exists)}
				{
					UI:Update["obj_Salvage", "Opening - ${TargetIterator.Value.Name}", "g"]
					TargetIterator.Value:OpenCargo
					return FALSE
				}		
			}
			while ${TargetIterator:Next(exists)}
		}
		return FALSE
	}
}