objectdef obj_Salvage inherits obj_State
{
	variable obj_LootCans LootCans
	variable bool ForceBookmarkCycle=FALSE
	variable index:int64 HoldOffPlayer
	variable index:int HoldOffTimer
	variable set AlreadySalvaged

	method Initialize()
	{
		This[parent]:Initialize
		This:AssignStateQueueDisplay[obj_SalvageStateList@Salvager@ComBotTab@ComBot]
		UI:Update["obj_Salvage", "Initialized", "g"]
	}

	method Start()
	{
		UI:Update["obj_Salvage", "Started", "g"]
		if ${This.IsIdle}
		{
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold", 5000]
		}
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
		variable string BookmarkDate="9999.99.99"
		variable int64 BookmarkCreator
		variable iterator HoldOffIterator
		variable index:int RemoveHoldOff
		variable int RemoveDecAmount=0
		variable bool InHoldOff
		BookmarkFound:Set[FALSE]
		
		EVE:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		UIElement[obj_SalvageBookmarkList@Salvager@ComBotTab@ComBot]:ClearItems
		
		HoldOffTimer:GetIterator[HoldOffIterator]
		if ${HoldOffIterator:First(exists)}
		do
		{
			if ${LavishScript.RunningTime} >= ${HoldOffIterator.Value}
			{
				RemoveHoldOff:Insert[${HoldOffIterator.Key}]
			}
		}
		while ${HoldOffIterator:Next(exists)}
		
		RemoveHoldOff:GetIterator[HoldOffIterator]
		if ${HoldOffIterator:First(exists)}
		do
		{
			HoldOffPlayer:Remove[${Math.Calc[${HoldOffIterator.Value}-${RemoveDecAmount}]}]
			HoldOffTimer:Remove[${Math.Calc[${HoldOffIterator.Value}-${RemoveDecAmount}]}]
			RemoveDecAmount:Inc
		}
		while ${HoldOffIterator:Next(exists)}
		
		HoldOffPlayer:GetIterator[HoldOffIterator]
		
		if ${BookmarkIterator:First(exists)}
		do
		{	
			if ${BookmarkIterator.Value.Label.Left[8].Upper.Equal["SALVAGE:"]}
			{
				UIElement[obj_SalvageBookmarkList@Salvager@ComBotTab@ComBot]:AddItem[${BookmarkIterator.Value.Label}]
				InHoldOff:Set[FALSE]
				if ${HoldOffIterator:First(exists)}
				do
				{
					if ${HoldOffIterator.Value.Equal[${BookmarkIterator.Value.CreatorID}]}
					{
						UIElement[obj_SalvageBookmarkList@Salvager@ComBotTab@ComBot].ItemByText[${BookmarkIterator.Value.Label}]:SetTextColor[FFFF0000]
						InHoldOff:Set[TRUE]
					}
				}
				while ${HoldOffIterator:Next(exists)}
				if !${InHoldOff}
				{
					if (${BookmarkIterator.Value.TimeCreated.Compare[${BookmarkTime}]} < 0 && ${BookmarkIterator.Value.DateCreated.Compare[${BookmarkDate}]} <= 0) || ${BookmarkIterator.Value.DateCreated.Compare[${BookmarkDate}]} < 0
					{
						UIElement[obj_SalvageBookmarkList@Salvager@ComBotTab@ComBot].ItemByText[${BookmarkIterator.Value.Label}]:SetTextColor[FF0000FF]
						Target:Set[${BookmarkIterator.Value.Label}]
						BookmarkTime:Set[${BookmarkIterator.Value.TimeCreated}]
						BookmarkDate:Set[${BookmarkIterator.Value.DateCreated}]
						BookmarkCreator:Set[${BookmarkIterator.Value.CreatorID}]
						BookmarkFound:Set[TRUE]
					}
				}
			}
		}
		while ${BookmarkIterator:Next(exists)}
		
		if ${BookmarkFound}
		{
			UI:Update["obj_Salvage", "Setting course for ${Target}", "g"]
			Move:Bookmark[${Target}]
			This:QueueState["Traveling"]
			This:QueueState["Log", 1000, "Salvaging at ${Target}"]
			This:QueueState["SalvageWrecks", 500, "${BookmarkCreator}"]
			This:QueueState["ClearAlreadySalvaged", 100]
			This:QueueState["DeleteBookmark", 1000, "${BookmarkCreator}"]
			This:QueueState["GateCheck", 1000, "${BookmarkCreator}"]
			return TRUE
		}

		
		UI:Update["obj_Salvage", "No salvage bookmark found - returning to station", "g"]
		Move:Bookmark["Salvager Home Base"]
		This:QueueState["Traveling"]
		This:QueueState["Offload"]
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

	member:bool SalvageWrecks(int64 BookmarkCreator)
	{
		variable index:entity TargetIndex
		variable iterator TargetIterator
		variable queue:int LootRangeAndTractored
		variable int MaxTarget = ${MyShip.MaxLockedTargets}
		variable int ClosestTractorKey
		variable bool ReactivateTractor = FALSE
		variable int64 SalvageMultiTarget = -1
		
		if ${Targets.NPC}
		{
			UI:Update["obj_Salvage", "Pocket has NPCs - Jumping Clear", "g"]
			HoldOffPlayer:Insert[${BookmarkCreator}]
			HoldOffTimer:Insert[${Math.Calc[${LavishScript.RunningTime} + 600000]}]
			This:Clear
			This:QueueState["JumpToCelestial"]
			This:QueueState["Traveling"]
			This:QueueState["RefreshBookmarks", 3000]
			This:QueueState["CheckBookmarks"]
			return TRUE
		}
		
		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			MaxTarget:Set[${Me.MaxLockedTargets}]
		}
		echo Inactive Tractor Beams - ${Ship.ModuleList_TractorBeams.InactiveCount}
		EVE:QueryEntities[TargetIndex, "(GroupID==GROUP_WRECK || GroupID==GROUP_CARGOCONTAINER) && HaveLootRights && !IsAbandoned"]
		TargetIndex:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			LootCans:Enable
			do
			{
				echo Before Salvage
				if  !${TargetIterator.Value.BeingTargeted} && \
					!${TargetIterator.Value.IsLockedTarget} && \
					${Targets.LockedAndLockingTargets} == ${MaxTarget}
				{
					if ${TargetIterator.Value.Distance} > ${Ship.Module_TractorBeams_Range}
					{
						Move:Approach[${TargetIterator.Value}]
						return FALSE
					}
					if !${SalvageMultiTarget.Equal[-1]} && ${Ship.ModuleList_Salvagers.InactiveCount} > 0
					{
						Ship.ModuleList_Salvagers:Activate[${SalvageMultiTarget}]
						return FALSE
					}
				}
				echo After Salvage
				if  !${TargetIterator.Value.BeingTargeted} && \
					!${TargetIterator.Value.IsLockedTarget} && \
					${Targets.LockedAndLockingTargets} < ${MaxTarget} && \
					${TargetIterator.Value.Distance} < ${MyShip.MaxTargetRange} && \
					!${AlreadySalvaged.Contains[${TargetIterator.Value.ID}]}
				{
					UI:Update["obj_Salvage", "Locking - ${TargetIterator.Value.Name}", "g"]
					TargetIterator.Value:LockTarget
					AlreadySalvaged:Add[${TargetIterator.Value.ID}]
					return FALSE
				}
				if ${TargetIterator.Value.Distance} > ${Ship.Module_TractorBeams_Range}
				{
					Move:Approach[${TargetIterator.Value}]
					return FALSE
				}
				echo ${TargetIterator.Value.Name} - ${Ship.ModuleList_TractorBeams.IsActiveOn[${TargetIterator.Value.ID}]}
				
				if  !${Ship.ModuleList_TractorBeams.IsActiveOn[${TargetIterator.Value.ID}]} &&\
					${TargetIterator.Value.Distance} < ${Ship.Module_TractorBeams_Range} &&\
					${TargetIterator.Value.Distance} > LOOT_RANGE &&\
					${Ship.ModuleList_TractorBeams.InactiveCount} > 0 &&\
					${TargetIterator.Value.IsLockedTarget}
				{
					UI:Update["obj_Salvage", "Activating tractor beam - ${TargetIterator.Value.Name}", "g"]
					Ship.ModuleList_TractorBeams:Activate[${TargetIterator.Value.ID}]
					return FALSE
				}
				echo ${Ship.ModuleList_TractorBeams.IsActiveOn[${TargetIterator.Value.ID}]} - ${TargetIterator.Value.ID}
				if  !${Ship.ModuleList_TractorBeams.IsActiveOn[${TargetIterator.Value.ID}]} &&\
					${TargetIterator.Value.Distance} < ${Ship.Module_TractorBeams_Range} &&\
					${TargetIterator.Value.Distance} > LOOT_RANGE &&\
					${TargetIterator.Value.IsLockedTarget} &&\
					${ReactivateTractor}
				{
					UI:Update["obj_Salvage", "Reactivating tractor beam - ${TargetIterator.Value.Name}", "g"]
					Ship.ModuleList_TractorBeams:Reactivate[${ClosestTractorKey}, ${TargetIterator.Value.ID}]
					return FALSE
				}
				if  ${Ship.ModuleList_TractorBeams.IsActiveOn[${TargetIterator.Value.ID}]} &&\
					${TargetIterator.Value.Distance} < LOOT_RANGE &&\
					!${ReactivateTractor}
				{
					; UI:Update["obj_Salvage", "Deactivating tractor beam - ${TargetIterator.Value.Name}", "g"]
					ClosestTractorKey:Set[${Ship.ModuleList_TractorBeams.GetActiveOn[${TargetIterator.Value.ID}]}]
					ReactivateTractor:Set[TRUE]
				}
				if  !${Ship.ModuleList_Salvagers.IsActiveOn[${TargetIterator.Value.ID}]} &&\
					${TargetIterator.Value.Distance} < ${Ship.Module_Salvagers_Range} &&\
					${Ship.ModuleList_Salvagers.InactiveCount} > 0 &&\
					${TargetIterator.Value.IsLockedTarget}
				{
					UI:Update["obj_Salvage", "Activating salvager - ${TargetIterator.Value.Name}", "g"]
					Ship.ModuleList_Salvagers:Activate[${TargetIterator.Value.ID}]
					return FALSE
				}
				if  ${TargetIterator.Value.Distance} < ${Ship.Module_Salvagers_Range} &&\
					${Ship.ModuleList_Salvagers.InactiveCount} > 0 &&\
					${TargetIterator.Value.IsLockedTarget}
				{
					SalvageMultiTarget:Set[${TargetIterator.Value.ID}]
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		else
		{
			LootCans:Disable
			return TRUE
		}
		if !${SalvageMultiTarget.Equal[-1]} && ${Ship.ModuleList_Salvagers.InactiveCount} > 0
		{
			Ship.ModuleList_Salvagers:Activate[${SalvageMultiTarget}]
		}
		return FALSE
	}
	
	member:bool ClearAlreadySalvaged()
	{
		AlreadySalvaged:Clear
		return TRUE
	}
	
	member:bool GateCheck(int64 BookmarkCreator)
	{
		variable index:bookmark Bookmarks
		variable bool UseJumpGate=FALSE
		if ${Entity[GroupID == GROUP_WARPGATE](exists)}
		{
			EVE:GetBookmarks[Bookmarks]
			Bookmarks:GetIterator[BookmarkIterator]
			if ${BookmarkIterator:First(exists)}
			{
				do
				{
					if ${BookmarkIterator.Value.Label.Left[8].Upper.Equal["SALVAGE:"]} && ${BookmarkIterator.Value.CreatorID.Equal[${BookmarkCreator}]}
					{
						UseJumpGate:Set[True}
					}
				}
				while ${BookmarkIterator:Next(exists)}
			}
			if ${UseJumpGate}
			{
				UI:Update["obj_Salvage", "Gate found, activating", "g"]
				This:Clear
				Move:Gate[${Entity[GroupID == GROUP_WARPGATE].ID}]
				This:QueueState["Idle", 5000]
				This:QueueState["Traveling"]
				This:QueueState["SalvageWrecks", 500, "${BookmarkCreator}"]
				This:QueueState["ClearAlreadySalvaged", 100]
				This:QueueState["DeleteBookmark", 1000, "${BookmarkCreator}"]
				This:QueueState["GateCheck", 1000, "${BookmarkCreator}"]
				This:QueueState["JumpToCelestial"]
				This:QueueState["Traveling"]
			}
			else
			{
				UI:Update["obj_Salvage", "Gate found, but no more bookmarks from player.  Ignoring", "g"]
				This:Clear
				This:QueueState["JumpToCelestial"]
				This:QueueState["Traveling"]
			}
		}
		This:QueueState["OpenCargoHold"]
		This:QueueState["CheckCargoHold", 5000]
		return TRUE
	}
	
	member:bool JumpToCelestial()
	{
		UI:Update["obj_Salvage", "Warping to ${Entity[GroupID = GROUP_SUN].Name}", "g"]
		Move:Warp[${Entity["GroupID = GROUP_SUN"].ID}]
		return TRUE
	}
	
	member:bool DeleteBookmark(int64 BookmarkCreator)
	{
		echo DeleteBookmark
		variable index:bookmark Bookmarks
		variable iterator BookmarkIterator
		EVE:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		if ${BookmarkIterator:First(exists)}
		do
		{
			echo ${BookmarkIterator.Value.Label.Left[8].Upper.Equal["SALVAGE:"]} && ${BookmarkIterator.Value.CreatorID.Equal[${BookmarkCreator}]}
			if ${BookmarkIterator.Value.Label.Left[8].Upper.Equal["SALVAGE:"]} && ${BookmarkIterator.Value.CreatorID.Equal[${BookmarkCreator}]}
			{
				if ${BookmarkIterator.Value.JumpsTo} == 0
				{
					if ${BookmarkIterator.Value.Distance} < 500000
					{
						UI:Update["obj_Salvage", "Finished Salvaging ${BookmarkIterator.Value.Label} - Deleting", "g"]
						BookmarkIterator.Value:Remove
						return TRUE
					}
				}
			}
		}
		while ${BookmarkIterator:Next(exists)}
		return TRUE
	}
	
	member:bool OpenCargoHold()
	{
		UI:Update["obj_Salvage", "Making sure cargo hold is open", "g"]
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			MyShip:OpenCargo[]
		}
		return TRUE
	}
	
	member:bool CheckCargoHold()
	{
		if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > 0.75
		{
			UI:Update["obj_Salvage", "Unload trip required", "g"]
			Move:Bookmark["Salvager Home Base"]
			This:QueueState["Traveling"]
			This:QueueState["Offload"]
		}
		else
		{
			UI:Update["obj_Salvage", "Unload trip not required", "g"]
		}
		This:QueueState["RefreshBookmarks", 3000]
		This:QueueState["CheckBookmarks"]
		return TRUE;
	}

	
	member:bool Offload()
	{
		UI:Update["obj_Salvage", "Unloading cargo", "g"]
		Cargo:PopulateCargoList[SHIP]
		Cargo:MoveCargoList[HANGAR]
		This:Clear
		This:QueueState["Log", 1000, "Idling for 1 minute"]
		This:QueueState["Idle", 60000]
		This:QueueState["RefreshBookmarks", 3000]
		This:QueueState["CheckBookmarks"]
		return TRUE
	}
	
	
	member:bool RefreshBookmarks()
	{
		UI:Update["obj_Salvage", "Refreshing bookmarks", "g"]
	
		EVE:RefreshBookmarks
		return TRUE
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
		variable index:item TargetCargo
		variable iterator CargoIterator
	
		if !${Client.InSpace}
		{
			return FALSE
		}

		if ${Entity[(GroupID==GROUP_WRECK || GroupID==GROUP_CARGOCONTAINER) && IsAbandoned](exists)}
		{
			Entity[(GroupID==GROUP_WRECK || GroupID==GROUP_CARGOCONTAINER) && IsAbandoned]:UnlockTarget
		}
		
		EVE:QueryEntities[Targets, "(GroupID==GROUP_WRECK || GroupID==GROUP_CARGOCONTAINER) && HaveLootRights && !IsWreckEmpty && Distance<LOOT_RANGE && !IsAbandoned"]
		Targets:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			do
			{
				if ${EVEWindow[ByItemID, ${TargetIterator.Value}](exists)}
				{
					Entity[${TargetIterator.Value}]:GetCargo[TargetCargo]
					TargetCargo:GetIterator[CargoIterator]
					if ${CargoIterator:First(exists)}
					{
						do
						{
							if ${CargoIterator.Value.IsContraband}
							{
								TargetIterator.Value:Abandon
								return FALSE
							}
						}
						while ${CargoIterator:Next(exists)}
					}
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