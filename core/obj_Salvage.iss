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
		
		; if ${Entity[GroupID == GROUP_WARPGATE](exists)}
		; {
			; UI:Update["obj_Salvage", "Gate found, activating", "g"]
			; Move:Gate[${Entity[GroupID == GROUP_WARPGATE].ID}]
			; This:QueueState["Traveling"]
			; This:QueueState["SalvageWrecks"]
			; This:QueueState["OpenCargoHold"]
			; This:QueueState["CheckCargoHold", 5000]
			; return true;
		; }
		
		
		BookmarkFound:Set[FALSE]
		
		EVE:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		echo ${Bookmarks.Used} bookmarks found
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
		variable index:entity Targets
		variable iterator TargetIterator
		variable queue:int LootRangeAndTractored
		variable int Targeted = 0
		variable int Tractored = 0
		variable int MaxTarget = ${MyShip.MaxLockedTargets}
		variable int ModuleIndex = -1
		
		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			MaxTarget:Set[${Me.MaxLockedTargets}]
		}
		
		EVE:QueryEntities[Targets, "(GroupID==GROUP_WRECK || GroupID==GROUP_CARGOCONTAINER) && HaveLootRights"]
		Targets:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			LootCans:Enable
			do
			{
				if !${TargetIterator.Value.BeingTargeted} && !${TargetIterator.Value.IsLockedTarget} && ${Client.LockedAndLockingTargets} < ${MaxTarget}
				{
					UI:Update["obj_Salvage", "Locking - ${TargetIterator.Value.Name}", "g"]
					TargetIterator.Value:LockTarget
					return FALSE
				}
				Targeted:Inc
				if ${TargetIterator.Value.Distance} > ${Ship.Module_TractorBeams_Range} && ${Tractored}+1 == ${Targeted}
				{
					UI:Update["obj_Salvage", "Approaching - ${TargetIterator.Value.Name}", "g"]
					Move:Approach[${TargetIterator.Value}]
					return FALSE
				}

				
				if !${Ship.IsTractoringID[${TargetIterator.Value.ID}]} && ${TargetIterator.Value.Distance} < ${Ship.Module_TractorBeams_Range} && ${Ship.TotalActivatedTractorBeams} < ${Ship.TotalTractorBeams} && ${TargetIterator.Value.IsLockedTarget}
				{
					;ModuleIndex:Set[${Ship.FindUnactiveModule[${Ship.ModuleList_TractorBeams}}]
					;if ${ModuleIndex} >= 0
					;{
					
							UI:Update["obj_Salvage", "Activating tractor beam - ${TargetIterator.Value.Name}", "g"]
							;Ship.ModuleList_TractorBeams.Get[${ModuleIndex}]:Activate[${TargetIterator.Value.ID}]
							Ship:ActivateFreeTractorBeam[${TargetIterator.Value.ID}]
							return FALSE
					;}
				}
				if ${Ship.IsModuleActiveOn[${Ship.ModuleList_TractorBeams}, ${TargetIterator.Value.ID}]}
				{
					Tractored:Inc
				}
				if ${Ship.IsModuleActiveOn[${Ship.ModuleList_TractorBeams}, ${TargetIterator.Value.ID}]}  && ${TargetIterator.Value.Distance} < LOOT_RANGE
				{
					LootRangeAndTractored:Queue[${TargetIterator.Value.ID}]
				}
				if !${Ship.IsSalvagingID[${TargetIterator.Value.ID}]} && ${TargetIterator.Value.Distance} < ${Ship.Module_Salvagers_Range} && ${Ship.TotalActivatedSalvagers} < ${Ship.TotalSalvagers} && ${TargetIterator.Value.IsLockedTarget}
				{
					;ModuleIndex:Set[${Ship.FindUnactiveModule[${Ship.ModuleList_Salvagers}}]
					;if ${ModuleIndex} >= 0
					;{
						UI:Update["obj_Salvage", "Activating salvager - ${TargetIterator.Value.Name}", "g"]
						;Ship.ModuleList_Salvagers.Get[${ModuleIndex}]:Activate[${TargetIterator.Value.ID}]
						Ship:ActivateFreeSalvager[${TargetIterator.Value.ID}]
						return FALSE
					;}
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		else
		{
			LootCans:Disable			
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
		This:QueueState["CheckBookmarks"]
		return TRUE;
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
		This:QueueState["Loot", 500]
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

		EVE:QueryEntities[Targets, "(GroupID==GROUP_WRECK || GroupID==GROUP_CARGOCONTAINER) && HaveLootRights"]
		Targets:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			do
			{
				if ${EVEWindow[ByItemID, ${TargetIterator.Value}](exists)} && ${TargetIterator.Value.Distance}<LOOT_RANGE
				{
					UI:Update["obj_Salvage", "Looting - ${TargetIterator.Value.Name}", "g"]
					EVEWindow[ByItemID, ${TargetIterator.Value}]:LootAll
					return FALSE
				}
				if !${TargetIterator.Value.IsWreckEmpty} && !${EVEWindow[ByItemID, ${TargetIterator.Value}](exists)} && ${TargetIterator.Value.Distance}<LOOT_RANGE
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