/*

ComBot  Copyright � 2012  Tehtsuo and Vendan

This file is part of ComBot.

ComBot is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ComBot is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ComBot.  If not, see <http://www.gnu.org/licenses/>.

*/

objectdef obj_Salvage inherits obj_State
{
	variable obj_LootCans LootCans
	variable bool ForceBookmarkCycle=FALSE
	variable index:int64 HoldOffPlayer
	variable index:int HoldOffTimer
	variable collection:int64 AlreadySalvaged
	variable float NonDedicatedFullPercent = 0.95
	variable bool NonDedicatedNPCRun = FALSE
	variable bool Dedicated = TRUE
	variable bool Salvaging = FALSE
	variable queue:entity BeltPatrol
	
	variable obj_TargetList Wrecks

	method Initialize()
	{
		This[parent]:Initialize
		Wrecks:AddQueryString["(GroupID==GROUP_WRECK || GroupID==GROUP_CARGOCONTAINER) && HaveLootRights && !IsAbandoned && !IsMoribund"]
	}

	method Start()
	{
		UI:Update["obj_Salvage", "Started", "g"]
		This:AssignStateQueueDisplay[DebugStateList@Debug@ComBotTab@ComBot]
		if ${This.IsIdle}
		{
			This:QueueState["OpenCargoHold", 500]
			This:QueueState["CheckCargoHold", 500]
		}
	}
	
	method Stop()
	{
		UI:Update["obj_Salvage", "Salvage stopped, setting destination to station", "g"]
		This:Clear()
		Move:Bookmark[${Config.Salvager.Salvager_Dropoff}]
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
			if ${BookmarkIterator.Value.Label.Left[8].Upper.Equal[${Config.Salvager.Salvager_Prefix}]}
			{
				InHoldOff:Set[FALSE]
				if ${HoldOffIterator:First(exists)}
				do
				{
					if ${HoldOffIterator.Value.Equal[${BookmarkIterator.Value.CreatorID}]}
					{
						InHoldOff:Set[TRUE]
					}
				}
				while ${HoldOffIterator:Next(exists)}
				if !${InHoldOff}
				{
					if (${BookmarkIterator.Value.TimeCreated.Compare[${BookmarkTime}]} < 0 && ${BookmarkIterator.Value.DateCreated.Compare[${BookmarkDate}]} <= 0) || ${BookmarkIterator.Value.DateCreated.Compare[${BookmarkDate}]} < 0
					{
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
			Move:Bookmark[${Target}, TRUE]
			This:QueueState["Traveling"]
			This:QueueState["Log", 1000, "Salvaging at ${Target}"]
			This:QueueState["InitialUpdate", 100]
			This:QueueState["Updated", 100]
			This:QueueState["SalvageWrecks", 500, "${BookmarkCreator}"]
			This:QueueState["ClearAlreadySalvaged", 100]
			This:QueueState["DeleteBookmark", 1000, "${BookmarkCreator}"]
			This:QueueState["RefreshBookmarks", 3000]
			This:QueueState["GateCheck", 1000, "${BookmarkCreator}"]
			return TRUE
		}

		if ${Config.Salvager.BeltPatrol}
		{
			UI:Update["obj_Salvage", "No salvage bookmark found - beginning belt patrol", "g"]
			Move:System[${EVE.Bookmark[${Config.Salvager.BeltPatrolBookmark}].SolarSystemID}]
			This:QueueState["Traveling"]
			This:QueueState["MoveToBelt"]
			This:QueueState["Traveling"]
			This:QueueState["Log", 1000, "Salvaging in belt"]
			This:QueueState["InitialUpdate", 100]
			This:QueueState["Updated", 100]
			This:QueueState["SalvageWrecks", 500, "${Me.CharID}"]
			This:QueueState["ClearAlreadySalvaged", 100]
			This:QueueState["RefreshBookmarks", 3000]
			This:QueueState["OpenCargoHold", 500]
			This:QueueState["CheckCargoHold", 500]
			return TRUE
		}
		else
		{
			UI:Update["obj_Salvage", "No salvage bookmark found - returning to station", "g"]
			Move:Bookmark[${Config.Salvager.Salvager_Dropoff}, TRUE]
			This:QueueState["Traveling"]
			This:QueueState["PrepOffload"]
			This:QueueState["Offload"]
			return TRUE
		}
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
	
	method NonDedicatedSalvage(float FullThreshold = 0.95, bool NPCRun = FALSE)
	{
		Dedicated:Set[FALSE]
		NonDedicatedFullPercent:Set[${FullThreshold}]
		NonDedicatedNPCRun:Set[${NPCRun}]
		This:QueueState["InitialUpdate", 100]
		This:QueueState["Updated", 100]
		This:QueueState["SalvageWrecks", 500, "0"]
		This:QueueState["DoneSalvaging"]
		Salvaging:Set[TRUE]
	}
	
	member:bool DoneSalvaging()
	{
		Salvaging:Set[FALSE]
		Dedicated:Set[TRUE]
	}
	
	member:bool InitialUpdate()
	{
		Wrecks:RequestUpdate
		return TRUE
	}
	
	member:bool Updated()
	{
		return ${Wrecks.Updated}
	}

	member:bool SalvageWrecks(int64 BookmarkCreator)
	{
		variable iterator TargetIterator
		variable queue:int LootRangeAndTractored
		variable int MaxTarget = ${MyShip.MaxLockedTargets}
		variable int ClosestTractorKey
		variable bool ReactivateTractor = FALSE
		variable int64 SalvageMultiTarget = -1
		variable float FullHold = 0.95
		variable bool NPCRun = TRUE


		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			MaxTarget:Set[${Me.MaxLockedTargets}]
		}
		Wrecks.MaxRange:Set[${MyShip.MaxTargetRange.Round}}
		Wrecks.MinLockCount:Set[${MaxTarget}]
		Wrecks.AutoLock:Set[TRUE]
		
		if !${Dedicated}
		{
			FullHold:Set[${NonDedicatedFullPercent}]
			NPCRun:Set[${NonDedicatedNPCRun}]
		}
		
		if ${Targets.NPC} && ${NPCRun}
		{
			UI:Update["obj_Salvage", "Pocket has NPCs - Jumping Clear", "g"]
			LootCans:Disable
			if ${Dedicated}
			{
				HoldOffPlayer:Insert[${BookmarkCreator}]
				HoldOffTimer:Insert[${Math.Calc[${LavishScript.RunningTime} + 600000]}]
				This:Clear
				This:QueueState["JumpToCelestial"]
				This:QueueState["Traveling"]
				This:QueueState["RefreshBookmarks", 3000]
				This:QueueState["CheckBookmarks"]
			}
			Wrecks.AutoLock:Set[FALSE]
			return TRUE
		}

		if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > ${FullHold}
		{
			UI:Update["obj_Salvage", "Unload trip required", "g"]
			LootCans:Disable
			if ${Dedicated}
			{
				Move:Bookmark[${Config.Salvager.Salvager_Dropoff}]
				This:Clear
				This:QueueState["Traveling"]
				This:QueueState["Offload"]
				This:QueueState["RefreshBookmarks", 3000]
				This:QueueState["CheckBookmarks"]
			}
			Wrecks.AutoLock:Set[FALSE]
			return TRUE
		}
		

		
		Wrecks:RequestUpdate
		
		echo Inactive Tractor Beams - ${Ship.ModuleList_TractorBeams.InactiveCount}
		
		if ${Wrecks.TargetList.Used} > 0
		{
			Ship.ModuleList_SensorBoost:Activate
		}
		
		
		Wrecks.TargetList:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)}
		{
			LootCans:Enable
			do
			{
				if ${TargetIterator.Value.ID(exists)}
				{
					if ${TargetIterator.Value.Distance} > ${Ship.ModuleList_TractorBeams.Range}
					{
						Move:Approach[${TargetIterator.Value.ID}]
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
					echo ${Ship.ModuleList_TractorBeams.IsActiveOn[${TargetIterator.Value.ID}]} - ${TargetIterator.Value.ID}
					if  !${Ship.ModuleList_TractorBeams.IsActiveOn[${TargetIterator.Value.ID}]} &&\
						${TargetIterator.Value.Distance} < ${Ship.ModuleList_TractorBeams.Range} &&\
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
						${TargetIterator.Value.Distance} < ${Ship.ModuleList_Salvagers.Range} &&\
						${Ship.ModuleList_Salvagers.InactiveCount} > 0 &&\
						${TargetIterator.Value.IsLockedTarget} && ${Ship.ModuleList_Salvagers.Count} > 0
					{
						UI:Update["obj_Salvage", "Activating salvager - ${TargetIterator.Value.Name}", "g"]
						Ship.ModuleList_Salvagers:Activate[${TargetIterator.Value.ID}]
						return FALSE
					}
					if  !${Ship.ModuleList_Salvagers.IsActiveOn[${TargetIterator.Value.ID}]} &&\
						${TargetIterator.Value.IsWreckEmpty} &&\
						${TargetIterator.Value.IsLockedTarget} && ${Ship.ModuleList_Salvagers.Count} == 0
					{
						TargetIterator.Value:Abandon
						TargetIterator.Value:UnlockTarget
					}
					if  ${TargetIterator.Value.Distance} < ${Ship.ModuleList_Salvagers.Range} &&\
						${Ship.ModuleList_Salvagers.InactiveCount} > 0 &&\
						${TargetIterator.Value.IsLockedTarget}
					{
						SalvageMultiTarget:Set[${TargetIterator.Value.ID}]
					}
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		else
		{
			if ${Wrecks.TargetList.Used} > 0
			{
				if ${Wrecks.TargetList.Get[1].Distance} > ${Ship.ModuleList_TractorBeams.Range}
				{
					Move:Approach[${TargetIterator.Value}]
					return FALSE
				}
			}
			else
			{
				LootCans:Disable
				Wrecks.AutoLock:Set[FALSE]
				return TRUE
			}
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
		variable iterator BookmarkIterator
		variable bool UseJumpGate=FALSE
		if ${Entity[GroupID == GROUP_WARPGATE](exists)}
		{
			EVE:GetBookmarks[Bookmarks]
			Bookmarks:GetIterator[BookmarkIterator]
			if ${BookmarkIterator:First(exists)}
			{
				do
				{
					if ${BookmarkIterator.Value.Label.Left[8].Upper.Equal[${Config.Salvager.Salvager_Prefix}]} && ${BookmarkIterator.Value.CreatorID.Equal[${BookmarkCreator}]}
					{
						UseJumpGate:Set[TRUE]
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
				This:QueueState["InitialUpdate", 100]
				This:QueueState["Updated", 100]
				This:QueueState["SalvageWrecks", 500, "${BookmarkCreator}"]
				This:QueueState["ClearAlreadySalvaged", 100]
				This:QueueState["DeleteBookmark", 1000, "${BookmarkCreator}"]
				This:QueueState["RefreshBookmarks", 1000]
				This:QueueState["GateCheck", 1000, "${BookmarkCreator}"]
				This:QueueState["Traveling"]
			}
			else
			{
				UI:Update["obj_Salvage", "Gate found, but no more bookmarks from player.  Ignoring", "g"]
				This:Clear
			}
		}
		This:QueueState["OpenCargoHold", 500]
		This:QueueState["CheckCargoHold", 500]
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
			echo ${BookmarkIterator.Value.Label.Left[8].Upper.Equal[${Config.Salvager.Salvager_Prefix}]} && ${BookmarkIterator.Value.CreatorID.Equal[${BookmarkCreator}]}
			if ${BookmarkIterator.Value.Label.Left[8].Upper.Equal[${Config.Salvager.Salvager_Prefix}]} && ${BookmarkIterator.Value.CreatorID.Equal[${BookmarkCreator}]}
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
		if ${EVEWindow[byCaption, "wreck"](exists)}
		{
			UI:Update["obj_Salvage", "Bugged inventory window found, closing", "y"]
			EVEWindow[byCaption, "wreck"]:Close
			return FALSE
		}
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["obj_Salvage", "Opening inventory", "g"]
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
			UI:Update["obj_Salvage", "Unload trip required", "g"]
			Move:Bookmark[${Config.Salvager.Salvager_Dropoff}]
			This:QueueState["Traveling"]
			This:QueueState["PrepOffload"]
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

	member:bool PrepOffload()
	{
		if ${Client.InSpace}
		{
			return TRUE
		}
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["obj_Salvage", "Opening inventory", "g"]
			MyShip:OpenCargo[]
			return FALSE
		}
		switch ${Config.Salvager.Salvager_Dropoff_Type}
		{
			case Personal Hangar
				break
			default
				if !${EVEWindow[ByName, Inventory].ChildWindowExists[Corporation Hangars]}
				{
					UI:Update["obj_Salvage", "Delivery Location: Corporate Hangars child not found", "r"]
					UI:Update["obj_Salvage", "Closing inventory to fix possible EVE bug", "y"]
					EVEWindow[ByName, Inventory]:Close
					return FALSE
				}
				EVEWindow[ByName, Inventory]:MakeChildActive[Corporation Hangars]
				break
		}
		return TRUE
	}
	
	member:bool Offload()
	{
		UI:Update["obj_Salvage", "Unloading cargo", "g"]
		Cargo:PopulateCargoList[SHIP]
		switch ${Config.Salvager.Salvager_Dropoff_Type}
		{
			case Personal Hangar
				Cargo:MoveCargoList[HANGAR]
				break
			default
				Cargo:MoveCargoList[CORPORATEHANGAR, ${Config.Salvager.Salvager_Dropoff_Type}]
				break
		}
		This:Clear
		This:QueueState["StackItemHangar"]
		This:QueueState["Log", 1000, "Idling for 1 minute"]
		This:QueueState["Idle", 60000]
		This:QueueState["RefreshBookmarks", 3000]
		This:QueueState["CheckBookmarks"]
		return TRUE
	}
	
	member:bool StackItemHangar()
	{
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["obj_Salvage", "Making sure inventory is open", "g"]
			MyShip:Open
			return FALSE
		}

		UI:Update["obj_Salvage", "Stacking dropoff container", "g"]
		switch ${Config.Salvager.Salvager_Dropoff_Type}
		{
			case Personal Hangar
				EVE:StackItems[MyStationHangar, Hangar]
				break
			default
				EVE:StackItems[MyStationCorporateHangar, StationCorporateHangar, "${Config.Salvager.Salvager_Dropoff_Type.Escape}"]
				break
		}
		
		return TRUE
	}

	member:bool RefreshBookmarks()
	{
		UI:Update["obj_Salvage", "Refreshing bookmarks", "g"]
	
		EVE:RefreshBookmarks
		return TRUE
	}
	
	member:bool MoveToBelt()
	{
		if !${Client.InSpace}
		{
			Move:Undock
			return FALSE
		}

		if ${BeltPatrol.Used} == 0
		{
			variable index:entity Belts
			variable iterator BeltIterator
			EVE:QueryEntities[Belts, "GroupID = GROUP_ASTEROIDBELT"]
			Belts:GetIterator[BeltIterator]
			if ${BeltIterator:First(exists)}
				do
				{
					BeltPatrol:Queue[${BeltIterator.Value}]
				}
				while ${BeltIterator:Next(exists)}
		}
		
		
		Move:Object[${BeltPatrol.Peek.ID}]
		BeltPatrol:Dequeue
		return TRUE
	}	
	

}






objectdef obj_LootCans inherits obj_State
{
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
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

		if ${Entity[(GroupID==GROUP_CARGOCONTAINER) && IsAbandoned](exists)}
		{
			Entity[(GroupID==GROUP_WRECK || GroupID==GROUP_CARGOCONTAINER) && IsAbandoned]:UnlockTarget
		}
		
		EVE:QueryEntities[Targets, "(GroupID==GROUP_WRECK || GroupID==GROUP_CARGOCONTAINER) && HaveLootRights && !IsWreckEmpty && Distance<LOOT_RANGE && !IsAbandoned"]
		Targets:GetIterator[TargetIterator]
		if ${TargetIterator:First(exists)} && ${EVEWindow[ByName, Inventory](exists)}
		{
			do
			{
				if ${EVEWindow[ByName, Inventory].ChildWindowExists[${TargetIterator.Value}]}
				{
					if !${EVEWindow[ByItemID, ${TargetIterator.Value}](exists)}
					{
						EVEWindow[ByName, Inventory]:MakeChildActive[${TargetIterator.Value}]
						return FALSE
					}
					
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
				if !${EVEWindow[ByName, Inventory].ChildWindowExists[${TargetIterator.Value}]}
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