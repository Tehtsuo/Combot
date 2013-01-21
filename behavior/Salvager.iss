/*

ComBot  Copyright © 2012  Tehtsuo and Vendan

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



objectdef obj_Configuration_Salvager
{
	variable string SetName = "Salvager"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.CommonRef:AddSetting[Dropoff_Type,Personal Hangar]
		This.CommonRef:AddSetting[Prefix,Salvage:]
		This.CommonRef:AddSetting[Dropoff,""]
		This.CommonRef:AddSetting[Size,"Small"]
		This.CommonRef:AddSetting[FollowGates,TRUE]
	}

	Setting(string, Prefix, SetPrefix)
	Setting(string, Dropoff, SetDropoff)
	Setting(string, DropoffType, SetDropoffType)
	Setting(string, DropoffSubType, SetDropoffSubType)
	Setting(bool, BeltPatrolEnabled, SetBeltPatrolEnabled)
	Setting(bool, SalvageYellow, SetSalvageYellow)
	Setting(bool, AvoidShips, SetAvoidShips)
	Setting(bool, FollowGates, SetFollowGates)
	Setting(bool, Relay, SetRelay)
	Setting(string, BeltPatrol, SetBeltPatrol)
	Setting(string, DropoffContainer, SetDropoffContainer)
	Setting(string, Size, SetSize)
}

objectdef obj_Salvager inherits obj_State
{
	variable obj_Configuration_Salvager Config
	variable obj_SalvageUI LocalUI
	
	variable bool ForceBookmarkCycle=FALSE
	variable index:int64 HoldOffPlayer
	variable index:int HoldOffTimer
	variable float NonDedicatedFullPercent = 0.95
	variable bool NonDedicatedNPCRun = FALSE
	variable bool Dedicated = TRUE
	variable bool Salvaging = FALSE
	variable queue:entity BeltPatrol
	variable set UsedBookmarks
	
	variable obj_TargetList NPCs
	
	method Initialize()
	{
		This[parent]:Initialize
		LavishScript:RegisterEvent[ComBot_RemoveBookmark]
		Event[ComBot_RemoveBookmark]:AttachAtom[This:RemoveBookmarkEvent]
		NPCs:AddAllNPCs
		DynamicAddBehavior("Salvager", "Dedicated Salvager")
	}

	method Start()
	{
		UI:Update["obj_Salvage", "Started", "g"]
		This:AssignStateQueueDisplay[DebugStateList@Debug@ComBotTab@ComBot]
		if ${This.IsIdle}
		{
			This:QueueState["CheckCargoHold", 500]
		}
	}
	
	method Stop()
	{
		This:DeactivateStateQueueDisplay
		This:Clear
		noop This.DropCloak[FALSE]
	}
	
	method RemoveBookmarkEvent(int64 ID)
	{
		This:QueueState["RemoveBookmarkEventState", 10000, ${ID}]
	}
	
	member:bool RemoveBookmarkEventState(int64 ID)
	{
		variable index:bookmark Bookmarks
		variable iterator Bookmark
		EVE:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[Bookmark]
		if ${Bookmark:First(exists)}
			do
			{
				if  ${Bookmark.Value.ID} == ${ID} &&\
					${Bookmark.Value.CreatorID} == ${Me.CharID}
				{
					UI:Update["Salvager", "Removing bookmark from relay - ${Bookmark.Value.Label}", "o", TRUE]
					Bookmark.Value:Remove
					return TRUE
				}
			}
			while ${Bookmark:Next(exists)}
		return TRUE
	}

	member:bool CheckBookmarks()
	{
		variable index:bookmark Bookmarks
		variable iterator BookmarkIterator
		variable string Target
		variable int64 BookmarkTime=0
		variable bool BookmarkFound
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
			if ${BookmarkIterator.Value.Label.Left[${Config.Prefix.Length}].Upper.Equal[${Config.Prefix}]} && ${BookmarkIterator.Value.JumpsTo} <= 0
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
					if ${BookmarkIterator.Value.Created.AsInt64} + 72000000000 < ${EVETime.AsInt64} && !${UsedBookmarks.Contains[${BookmarkIterator.Value.ID}]}
					{
						UI:Update["Salvager", "Removing expired bookmark - ${BookmarkIterator.Value.Label}", "o", TRUE]
						if ${Config.Relay}
						{
							relay "all other" -event ComBot_RemoveBookmark ${BookmarkIterator.Value.ID}						
						}
						BookmarkIterator.Value:Remove
						UsedBookmarks:Add[${BookmarkIterator.Value.ID}]
						This:InsertState["CheckBookmarks"]
						This:InsertState["Idle", 5000]
						return FALSE
					}
					if (${BookmarkIterator.Value.Created.AsInt64} < ${BookmarkTime} || ${BookmarkTime} == 0) && !${UsedBookmarks.Contains[${BookmarkIterator.Value.ID}]}
					{
						Target:Set[${BookmarkIterator.Value.Label}]
						BookmarkTime:Set[${BookmarkIterator.Value.Created.AsInt64}]
						BookmarkCreator:Set[${BookmarkIterator.Value.CreatorID}]
						BookmarkFound:Set[TRUE]
					}
				}
			}
		}
		while ${BookmarkIterator:Next(exists)}
		
		if ${BookmarkIterator:First(exists)} && !${BookmarkFound}
		do
		{	
			if ${BookmarkIterator.Value.Label.Left[${Config.Prefix.Length}].Upper.Equal[${Config.Prefix}]}
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
					if ${BookmarkIterator.Value.Created.AsInt64} + 72000000000 < ${EVETime.AsInt64} && !${UsedBookmarks.Contains[${BookmarkIterator.Value.ID}]}
					{
						UI:Update["Salvager", "Removing expired bookmark - ${BookmarkIterator.Value.Label}", "o", TRUE]
						if ${Config.Relay}
						{
							relay "all other" -event ComBot_RemoveBookmark ${BookmarkIterator.Value.ID}						
						}
						BookmarkIterator.Value:Remove
						UsedBookmarks:Add[${BookmarkIterator.Value.ID}]
						This:InsertState["CheckBookmarks"]
						This:InsertState["Idle", 5000]
						return TRUE
					}
					if (${BookmarkIterator.Value.Created.AsInt64} < ${BookmarkTime} || ${BookmarkTime} == 0) && !${UsedBookmarks.Contains[${BookmarkIterator.Value.ID}]}
					{
						Target:Set[${BookmarkIterator.Value.Label}]
						BookmarkTime:Set[${BookmarkIterator.Value.Created.AsInt64}]
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
			This:QueueState["DropCloak", 50, TRUE]
			This:QueueState["SalvageWrecks", 500, "${BookmarkCreator}"]
			This:QueueState["DropCloak", 50, FALSE]
			This:QueueState["ClearAlreadySalvaged", 100]
			This:QueueState["DeleteBookmark", 1000, "${BookmarkCreator}"]
			This:QueueState["RefreshBookmarks", 3000]
			This:QueueState["GateCheck", 1000, "${BookmarkCreator}"]
			return TRUE
		}

		if ${Config.BeltPatrolEnabled}
		{
			UI:Update["obj_Salvage", "No salvage bookmark found - beginning belt patrol", "g"]
			Move:System[${EVE.Bookmark[${Config.BeltPatrol}].SolarSystemID}]
			This:QueueState["Traveling"]
			This:QueueState["MoveToBelt"]
			This:QueueState["Traveling"]
			This:QueueState["Log", 1000, "Salvaging in belt"]
			This:QueueState["InitialUpdate", 100]
			This:QueueState["Updated", 100]
			This:QueueState["DropCloak", 50, TRUE]
			This:QueueState["SalvageWrecks", 500, "${Me.CharID}"]
			This:QueueState["DropCloak", 50, FALSE]
			This:QueueState["ClearAlreadySalvaged", 100]
			This:QueueState["RefreshBookmarks", 3000]
			This:QueueState["CheckCargoHold", 500]
			return TRUE
		}
		else
		{
			UI:Update["obj_Salvage", "No salvage bookmark found - returning to station", "g"]
			This:QueueState["Offload"]
			This:QueueState["Traveling"]
			This:QueueState["Log", 10, "Idling for 5 minutes"]
			This:QueueState["Idle", 300000]
			This:QueueState["CheckCargoHold", 500]
			return TRUE
		}
	}

	member:bool Traveling()
	{
		if ${Cargo.Processing} || ${Move.Traveling} || ${Me.ToEntity.Mode} == 3
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
		This:QueueState["DropCloak", 50, TRUE]
		This:QueueState["SalvageWrecks", 500, "0"]
		This:QueueState["DropCloak", 50, FALSE]
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
		NPCs:RequestUpdate
		return TRUE
	}
	
	member:bool Updated()
	{
		return ${NPCs.Updated}
	}

	member:bool DropCloak(bool arg)
	{
		AutoModule.DropCloak:Set[${arg}]
		return TRUE
	}
	
	member:bool SalvageWrecks(int64 BookmarkCreator)
	{
		variable float FullHold = 0.95
		variable bool NPCRun = TRUE


		if !${Dedicated}
		{
			FullHold:Set[${NonDedicatedFullPercent}]
			NPCRun:Set[${NonDedicatedNPCRun}]
		}
		
		NPCs:RequestUpdate
		
		if ${Config.AvoidShips}
		{
			if 	${Entity[CategoryID == CATEGORYID_SHIP && !IsFleetMember]} && \
				${Entity[GroupID == GROUP_ASTEROIDBELT](exists)} &&\
				${Entity[GroupID == GROUP_ASTEROIDBELT].Distance} < WARP_RANGE
			{
				UI:Update["obj_Salvage", "There's another ship in this belt, warping to next", "g"]
				This:Clear
				This:QueueState["MoveToBelt"]
				This:QueueState["Traveling"]
				This:QueueState["Log", 10, "Salvaging in belt"]
				This:QueueState["InitialUpdate", 100]
				This:QueueState["Updated", 100]
				This:QueueState["DropCloak", 50, TRUE]
				This:QueueState["SalvageWrecks", 500, "${Me.CharID}"]
				This:QueueState["DropCloak", 50, FALSE]
				This:QueueState["ClearAlreadySalvaged", 100]
				This:QueueState["RefreshBookmarks", 3000]
				This:QueueState["CheckCargoHold", 500]
				return TRUE
			}
		}
		
		if ${NPCs.TargetList.Used} && ${NPCRun}
		{
			UI:Update["obj_Salvage", "Pocket has NPCs - Jumping Clear", "g"]
			
			if ${Entity[GroupID == GROUP_ASTEROIDBELT](exists)} && ${Entity[GroupID == GROUP_ASTEROIDBELT].Distance} < WARP_RANGE
			{
				This:Clear
				This:QueueState["MoveToBelt"]
				This:QueueState["Traveling"]
				This:QueueState["Log", 10, "Salvaging in belt"]
				This:QueueState["InitialUpdate", 100]
				This:QueueState["Updated", 100]
				This:QueueState["DropCloak", 50, TRUE]
				This:QueueState["SalvageWrecks", 500, "${Me.CharID}"]
				This:QueueState["DropCloak", 50, FALSE]
				This:QueueState["ClearAlreadySalvaged", 100]
				This:QueueState["RefreshBookmarks", 3000]
				This:QueueState["CheckCargoHold", 500]
				return TRUE
			}

			if ${Dedicated}
			{
				HoldOffPlayer:Insert[${BookmarkCreator}]
				HoldOffTimer:Insert[${Math.Calc[${LavishScript.RunningTime} + 600000]}]
				This:Clear
				This:QueueState["JumpToCelestial"]
				This:QueueState["Traveling"]
				This:QueueState["RefreshBookmarks", 3000]
				This:QueueState["CheckBookmarks", 3000]
			}
			return TRUE
		}

		if !${Client.Inventory}
		{
			return FALSE
		}

		if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].UsedCapacity} / ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].Capacity} > ${FullHold}
		{
			UI:Update["Salvage", "Unload trip required", "g"]
			if ${Dedicated}
			{
				This:Clear
				This:QueueState["Offload"]
				This:QueueState["Traveling"]
				This:QueueState["RefreshBookmarks", 3000]
				This:QueueState["CheckBookmarks", 3000]
			}
			return TRUE
		}

		if ${Salvage.Wrecks.TargetList.Used} == 0
		{
			return TRUE
		}
		else
		{
			variable float MaxRange = ${Ship.ModuleList_TractorBeams.Range}
			if ${MaxRange} > ${MyShip.MaxTargetRange}
			{
				MaxRange:Set[${MyShip.MaxTargetRange}]
			}

			variable iterator TargetIterator
			Salvage.Wrecks.TargetList:GetIterator[TargetIterator]
			if ${TargetIterator:First(exists)}
			{
				do
				{
					if ${TargetIterator.Value.ID(exists)}
					{
						if ${Salvage.Config.SalvageYellow} && !${TargetIterator.Value.HaveLootRights}
						{
							Move:Approach[${TargetIterator.Value.ID}]
							return FALSE
						}
						elseif	${TargetIterator.Value.Distance} > ${MaxRange}
						{
							Move:Approach[${TargetIterator.Value.ID}]
							return FALSE
						}
					}
				}
				while ${TargetIterator:Next(exists)}
			}
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
			if !${Config.FollowGates}
			{
				HoldOffPlayer:Insert[${BookmarkCreator}]
				HoldOffTimer:Insert[${Math.Calc[${LavishScript.RunningTime} + 600000]}]
				This:Clear
				This:QueueState["RefreshBookmarks", 3000]
				This:QueueState["CheckBookmarks", 3000]
				return TRUE
			}
			
			EVE:GetBookmarks[Bookmarks]
			Bookmarks:GetIterator[BookmarkIterator]
			if ${BookmarkIterator:First(exists)}
			{
				do
				{
					if ${BookmarkIterator.Value.Label.Left[${Config.Prefix.Length}].Upper.Equal[${Config.Prefix}]} && ${BookmarkIterator.Value.CreatorID.Equal[${BookmarkCreator}]}
					{
						UseJumpGate:Set[TRUE]
					}
				}
				while ${BookmarkIterator:Next(exists)}
			}

			if ${EVEWindow[ByName, modal].Text.Find["This gate is locked!"](exists)}
			{
				UI:Update["obj_Salvage", "Locked gate detected - Jumping clear", "g"]
				EVEWindow[ByName,modal]:ClickButtonOK
				HoldOffPlayer:Insert[${BookmarkCreator}]
				HoldOffTimer:Insert[${Math.Calc[${LavishScript.RunningTime} + 600000]}]
				This:Clear
				This:QueueState["RefreshBookmarks", 3000]
				This:QueueState["CheckBookmarks", 3000]
				return TRUE
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
				This:QueueState["DropCloak", 50, TRUE]
				This:QueueState["SalvageWrecks", 500, "${BookmarkCreator}"]
				This:QueueState["DropCloak", 50, FALSE]
				This:QueueState["ClearAlreadySalvaged", 100]
				This:QueueState["DeleteBookmark", 1000, "${BookmarkCreator}"]
				This:QueueState["RefreshBookmarks", 1000]
				This:QueueState["GateCheck", 1000, "${BookmarkCreator}"]
				This:QueueState["Traveling"]
			}
			else
			{
				UI:Update["Salvager", "Gate found, but no more bookmarks from player.  Ignoring", "g"]
				This:Clear
			}
		}
		This:QueueState["CheckCargoHold", 500]
		return TRUE
	}
	
	member:bool JumpToCelestial()
	{
		UI:Update["Salvager", "Warping to ${Entity[GroupID = GROUP_SUN].Name}", "g"]
		Move:Warp[${Entity["GroupID = GROUP_SUN"].ID}]
		return TRUE
	}
	
	member:bool DeleteBookmark(int64 BookmarkCreator, int Removed=-1)
	{
		variable index:bookmark Bookmarks
		variable iterator BookmarkIterator
		EVE:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		if ${BookmarkIterator:First(exists)}
		do
		{
			if ${BookmarkIterator.Value.Label.Left[${Config.Prefix.Length}].Upper.Equal[${Config.Prefix}]} && ${BookmarkIterator.Value.CreatorID.Equal[${BookmarkCreator}]}
			{
				if ${BookmarkIterator.Value.JumpsTo} == 0
				{
					if ${BookmarkIterator.Value.Distance} < WARP_RANGE 
					{
						if ${Removed} != ${BookmarkIterator.Value.ID}
						{
							UI:Update["obj_Salvage", "Finished Salvaging ${BookmarkIterator.Value.Label} - Deleting", "g"]
							This:InsertState["DeleteBookmark", 1000, "${BookmarkCreator},${BookmarkIterator.Value.ID}"]
							if ${Config.Relay}
							{
								relay "all other" -event ComBot_RemoveBookmark ${BookmarkIterator.Value.ID}						
							}
							BookmarkIterator.Value:Remove
							return TRUE
						}
						else
						{
							
							UsedBookmarks:Add[${BookmarkIterator.Value.ID}]
							return TRUE
						}
					}
				}
			}
		}
		while ${BookmarkIterator:Next(exists)}
		return TRUE
	}
	
	
	member:bool CheckCargoHold()
	{
		if !${Client.Inventory}
		{
			return FALSE
		}
		if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].UsedCapacity} / ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].Capacity} > 0.75
		{
			UI:Update["obj_Salvage", "Unload trip required", "g"]
			This:QueueState["Offload"]
			This:QueueState["Traveling"]
		}
		else
		{
			UI:Update["obj_Salvage", "Unload trip not required", "g"]
		}
		This:QueueState["RefreshBookmarks", 3000]
		This:QueueState["CheckBookmarks", 3000]
		return TRUE;
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
	
	member:bool Offload()
	{
		switch ${Config.DropoffType}
		{
			case Personal Hangar
				Cargo:At[${Config.Dropoff}]:Unload
				break
			default
				Cargo:At[${Config.Dropoff},${Config.DropoffType},${Config.DropoffSubType},${Config.DropoffContainer}]:Unload
				break
		}
		return TRUE
	}

}




objectdef obj_SalvageUI inherits obj_State
{


	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
	}
	
	method Start()
	{
		This:QueueState["UpdateBookmarkLists", 5]
	}
	
	method Stop()
	{
		This:Clear
	}

	member:bool UpdateBookmarkLists()
	{
		variable index:bookmark Bookmarks
		variable iterator BookmarkIterator

		EVE:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		echo running

		UIElement[DropoffList@DropoffFrame@ComBot_DedicatedSalvager_Frame@ComBot_DedicatedSalvager]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[Dropoff@DropoffFrame@ComBot_DedicatedSalvager_Frame@ComBot_DedicatedSalvager].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Salvager.Config.Dropoff.Length}].Equal[${Salvager.Config.Dropoff}]}
						UIElement[DropoffList@DropoffFrame@ComBot_DedicatedSalvager_Frame@ComBot_DedicatedSalvager]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[DropoffList@DropoffFrame@ComBot_DedicatedSalvager_Frame@ComBot_DedicatedSalvager]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}

		UIElement[BeltPatrolBookmarkList@SalvageFrame@ComBot_DedicatedSalvager_Frame@ComBot_DedicatedSalvager]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[BeltPatrolBookmark@SalvageFrame@ComBot_DedicatedSalvager_Frame@ComBot_DedicatedSalvager].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Salvager.Config.BeltPatrol.Length}].Equal[${Salvager.Config.BeltPatrol}]}
						UIElement[BeltPatrolBookmarkList@SalvageFrame@ComBot_DedicatedSalvager_Frame@ComBot_DedicatedSalvager]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[BeltPatrolBookmarkList@SalvageFrame@ComBot_DedicatedSalvager_Frame@ComBot_DedicatedSalvager]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}

			
		return FALSE
	}

}