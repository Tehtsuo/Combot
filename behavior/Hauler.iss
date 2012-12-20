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

objectdef obj_Configuration_Hauler
{
	variable string SetName = "Hauler"

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

		This.CommonRef:AddSetting[DropoffContainer,""]
		This.CommonRef:AddSetting[PickupContainer,""]
		This.CommonRef:AddSetting[Dropoff,""]
		This.CommonRef:AddSetting[Pickup,""]
		This.CommonRef:AddSetting[Move,""]
		This.CommonRef:AddSetting[Repeat,FALSE]
		This.CommonRef:AddSetting[Mode,"Continuous"]
	}
	
	Setting(string, PickupSubType, SetPickupSubType)
	Setting(string, Move, SetMove)
	Setting(string, Dropoff, SetDropoff)
	Setting(string, Pickup, SetPickup)
	Setting(string, DropoffType, SetDropoffType)
	Setting(string, PickupType, SetPickupType)
	Setting(string, DropoffContainer, SetDropoffContainer)
	Setting(string, PickupContainer, SetPickupContainer)
	Setting(string, DropoffSubType, SetDropoffSubType)
	Setting(string, Mode, SetMode)
	Setting(int, Threshold, SetThreshold)	
	Setting(bool, Repeat, SetRepeat)	
	Setting(bool, FlybyPickups, SetFlybyPickups)	

}

objectdef obj_Hauler inherits obj_State
{
	variable obj_Configuration_Hauler Config
	variable obj_HaulerUI LocalUI

	variable index:obj_CargoAction HaulQueue
	variable float OrcaCargo
	variable index:fleetmember FleetMembers
	variable int64 CurrentCan
	variable bool PopCan
	variable IPCQueue:obj_HaulLocation OnDemandHaulQueue = "HaulerOnDemandQueue"
	
	variable obj_TargetList IR_Cans
	variable obj_TargetList OOR_Cans

	method Initialize()
	{
		This[parent]:Initialize
		LavishScript:RegisterEvent[ComBot_Orca_Cargo]
		Event[ComBot_Orca_Cargo]:AttachAtom[This:OrcaCargoUpdate]
		PulseFrequency:Set[500]
		IR_Cans.MaxRange:Set[LOOT_RANGE]
		IR_Cans.ListOutOfRange:Set[FALSE]
		OOR_Cans.MaxRange:Set[WARP_RANGE]
		OOR_Cans.MinRange:Set[LOOT_RANGE]
		DynamicAddBehavior("Hauler", "Hauler")
	}

	method Shutdown()
	{
		Event[ComBot_Orca_Cargo]:DetachAtom[This:OrcaCargoUpdate]
	}	
	
	method Start()
	{
		UI:Update["Hauler", "Started", "g"]
		This:AssignStateQueueDisplay[DebugStateList@Debug@ComBotTab@ComBot]
		if ${This.IsIdle}
		{
			switch ${Config.Mode}
			{
				case Continuous
					This:QueueState["CheckCargoHold"]
					break
				case Queue
					This:QueueState["ProcessQueue"]
					This:QueueState["Traveling"]
					break
				default
					This:QueueState["CheckCargoHold"]
				break
			}
		}
	}
	
	method Stop()
	{
		This:DeactivateStateQueueDisplay
		This:Clear
		noop This.DropCloak[FALSE]
	}
	
	
	member:bool CheckCargoHold(bool OreHold=FALSE, bool CorpHangar=FALSE)
	{
		if !${Client.Inventory}
		{
			return FALSE
		}
		if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold](exists)} && !${OreHold}
		{
			if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold].UsedCapacity} / ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold].Capacity} < ${Config.Threshold} * .01
			{
				Cargo:PopulateCargoList[Ship]
				if ${Cargo.CargoList.Used}
				{
					Cargo:MoveCargoList[OreHold]
					This:InsertState["CheckCargoHold", 500, "TRUE"]
					return TRUE
				}
			}
		}
		if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar](exists)} && !${CorpHangar}
		{
			if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar].UsedCapacity} / ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar].Capacity} < ${Config.Threshold} * .01
			{
				Cargo:PopulateCargoList[Ship]
				if ${Cargo.CargoList.Used}
				{
					Cargo:MoveCargoList[Fleet Hangar]
					This:InsertState["CheckCargoHold", 500, "TRUE"]
					return TRUE
				}
			}
			if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar].UsedCapacity} / ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar].Capacity} < ${Config.Threshold} * .01 && \
				${Config.DropoffType.Equal[No Dropoff]}
			{
				Cargo:PopulateCargoList[OreHold]
				if ${Cargo.CargoList.Used}
				{
					Cargo:MoveCargoList[Fleet Hangar]
					This:InsertState["CheckCargoHold", 500, "TRUE"]
					return TRUE
				}
				relay "all other" -event ComBot_Orca_Cargo ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar].UsedCapacity}
			}
			
		}
		if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].UsedCapacity} / ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].Capacity} >= ${Config.Threshold} * .01 && \
			!${Config.DropoffType.Equal[No Dropoff]}
		{
			UI:Update["Hauler", "Unload trip required", "g"]
			DroneControl:Recall
			if ${Busy.IsBusy}
			{
				return FALSE
			}
			Cargo:At[${Config.Dropoff},${Config.DropoffType},${Config.DropoffSubType}, ${Config.DropoffContainer}]:Unload["!(Name =- \"Crystal\")"]:Unload["!(Name =- \"Crystal\")",0,ShipCorpHangar]:Unload["",0,OreHold]
			This:QueueState["Traveling"]
			This:QueueState["CheckCargoHold"]
			return TRUE
		}
		else
		{
			This:QueueState["CheckForWork"]
			This:QueueState["QueuePickup"]
			return TRUE
		}
	}

	method OrcaCargoUpdate(float value)
	{
		echo ORCA CARGO AT ${value}
		OrcaCargo:Set[${value}]
	}
	
	member:bool CheckForWork()
	{
		if ${Config.PickupType.Equal[Fleet Hangar]}
		{
			if !${Client.Inventory}
			{
				return FALSE
			}
			
			if ${OrcaCargo} > ${Config.Threshold} * .01 * ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].Capacity} || \
				!${Config.FlybyPickups}
			{
				return TRUE
			}
			else
			{
				Move:Bookmark[${Config.Dropoff}]
				This:InsertState["Traveling"]
				This:InsertState["Idle", 30000]
				This:InsertState["CheckForWork"]
				return TRUE
			}
		}
		return TRUE
	}
	
	member:bool QueuePickup()
	{
		if ${Config.PickupType.Equal[Jetcan]}
		{
			switch ${Config.PickupSubType}
			{
				case Fleet Jetcan
					Move:System[${EVE.Bookmark[${Config.Pickup}].SolarSystemID}]
					This:QueueState["Traveling"]
					This:QueueState["FleetJetcan"]
					break
				case Fleet Jetcan(Pop All)
					Move:System[${EVE.Bookmark[${Config.Pickup}].SolarSystemID}]
					This:QueueState["Traveling"]
					This:QueueState["FleetJetcanPopAll"]
					break
			}
		}
		else
		{
			Cargo:At[${Config.Pickup},${Config.PickupType},${Config.PickupSubType},${Config.PickupContainer}]:Load["GroupID != GROUP_MINING_CRYSTAL"]
			This:QueueState["Traveling"]
			This:QueueState["CheckCargoHold"]
		}
		return TRUE
	}
	
	
	member:bool Traveling()
	{
		if ${Cargo.Processing} || ${Move.Traveling} || ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		return TRUE
	}

	member:bool FleetJetcan()
	{
		if !${FleetMembers.Used}
		{
			Me.Fleet:GetMembers[FleetMembers]
			FleetMembers:RemoveByQuery[${LavishScript.CreateQuery[ID == ${Me.CharID}]}]
			FleetMembers:Collapse
		}
	
		if ${FleetMembers.Get[1].ToEntity(exists)}
		{
			This:QueueState["PopulateTargetList", 2000, ${FleetMembers.Get[1].ToEntity.ID}]
			This:QueueState["CheckTargetList", 50]
			This:QueueState["DropCloak", 50, TRUE]
			This:QueueState["LootCans", 1000, ${FleetMembers.Get[1].ToEntity.ID}]
			This:QueueState["DropCloak", 50, FALSE]
			This:QueueState["DepopulateTargetList", 2000]
			This:QueueState["CheckCargoHold"]
			FleetMembers:Remove[1]
			FleetMembers:Collapse
			return TRUE
		}
		elseif !${FleetMembers.Get[1].ToPilot(exists)}
		{
			FleetMembers:Remove[1]
			FleetMembers:Collapse
			return FALSE
		}
		else
		{
			Move:Fleetmember[${FleetMembers.Get[1].ID}, TRUE]
			This:QueueState["Traveling"]
			This:QueueState["FleetJetcan"]
			return TRUE
		}
	}
	
	member:bool FleetJetcanPopAll()
	{
		if !${FleetMembers.Used}
		{
			Me.Fleet:GetMembers[FleetMembers]
			FleetMembers:RemoveByQuery[${LavishScript.CreateQuery[ID == ${Me.CharID}]}]
			FleetMembers:Collapse
		}
	
		if ${FleetMembers.Get[1].ToEntity(exists)}
		{
			This:QueueState["PopulateTargetListAllCans", 2000]
			This:QueueState["CheckTargetList", 50]
			This:QueueState["DropCloak", 50, TRUE]
			This:QueueState["LootCans", 1000, ${FleetMembers.Get[1].ToEntity.ID}]
			This:QueueState["DropCloak", 50, FALSE]
			This:QueueState["DepopulateTargetList", 2000]
			This:QueueState["CheckCargoHold"]
			FleetMembers:Remove[1]
			FleetMembers:Collapse
			return TRUE
		}
		elseif !${FleetMembers.Get[1].ToPilot(exists)}
		{
			FleetMembers:Remove[1]
			FleetMembers:Collapse
			return FALSE
		}
		else
		{
			Move:Fleetmember[${FleetMembers.Get[1].ID}, TRUE]
			This:QueueState["Traveling"]
			This:QueueState["FleetJetcanPopAll"]
			return TRUE
		}
	}
	
	
	
	member:bool PopulateTargetList(int64 ID)
	{
		variable int64 CharID = ${Entity[${ID}].CharID}
		IR_Cans:ClearQueryString
		IR_Cans:AddQueryString[GroupID == GROUP_CARGOCONTAINER && OwnerID == ${CharID}]
		IR_Cans.DistanceTarget:Set[${ID}]
		OOR_Cans:ClearQueryString
		OOR_Cans:AddQueryString[GroupID == GROUP_CARGOCONTAINER && OwnerID == ${CharID}]
		OOR_Cans.DistanceTarget:Set[${ID}]
		
		OOR_Cans.MinRange:Set[LOOT_RANGE]

		IR_Cans.AutoLock:Set[FALSE]
		OOR_Cans.AutoLock:Set[FALSE]
		
		OOR_Cans:RequestUpdate
		IR_Cans:RequestUpdate
		
		return TRUE
	}
	
	member:bool PopulateTargetListAllCans()
	{
		IR_Cans:ClearQueryString
		OOR_Cans:ClearQueryString
		OOR_Cans:AddQueryString[((GroupID == GROUP_CARGOCONTAINER) || (GroupID==GROUP_WRECK && !IsWreckEmpty)) && HaveLootRights]
		
		OOR_Cans.DistanceTarget:Set[${MyShip.ID}]
		
		OOR_Cans.MinRange:Set[0]
		
		IR_Cans.AutoLock:Set[FALSE]
		OOR_Cans.AutoLock:Set[FALSE]
		
		OOR_Cans:RequestUpdate
		IR_Cans:RequestUpdate
		
		return TRUE
	}
	
	member:bool CheckTargetList()
	{
		if ${IR_Cans.Updated} && ${OOR_Cans.Updated}
		{
			return TRUE
		}
		return FALSE
	}

	member:bool DropCloak(bool arg)
	{
		AutoModule.DropCloak:Set[${arg}]
		return TRUE
	}
	
	member:bool LootCans(int64 ID)
	{
		if !${Entity[${ID}](exists)}
		{
			return TRUE
		}
		if !${Client.Inventory}
		{
			return FALSE
		}
		
		variable iterator CanIter
		
		
		if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].UsedCapacity} > (${Config.Threshold} * .01 * ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].Capacity}
		{
			return TRUE
		}
		
		OOR_Cans:RequestUpdate
		IR_Cans:RequestUpdate
		
		if !${Entity[${CurrentCan}](exists)}
		{
			CurrentCan:Set[-1]
		}
		
		if ${Entity[${CurrentCan}].GroupID} == GROUP_WRECK && ${Entity[${CurrentCan}].IsWreckEmpty}
		{
			Ship.ModuleList_TractorBeams:Deactivate[${CurrentCan}]
			Entity[${CurrentCan}]:UnlockTarget
			CurrentCan:Set[-1]
		}
		
		if ${OOR_Cans.TargetList.Used} > 0 && ${CurrentCan.Equal[-1]}
		{
			CurrentCan:Set[${OOR_Cans.TargetList.Get[1].ID}]
			PopCan:Set[TRUE]
		}

		if ${IR_Cans.TargetList.Used} > 0 && ${CurrentCan.Equal[-1]}
		{
			CurrentCan:Set[${IR_Cans.TargetList.Get[1].ID}]
			PopCan:Set[TRUE]
			if ${IR_Cans.TargetList.Used} == 1
			{
				PopCan:Set[FALSE]
			}
		}
		
		if ${CurrentCan.Equal[-1]}
		{
			return TRUE
		}
		
		if ${Entity[${CurrentCan}].Distance} > ${MyShip.MaxTargetRange}
		{
			Move:Approach[${CurrentCan}, LOOT_RANGE]
			return FALSE
		}
		
		if !${Entity[${CurrentCan}].IsLockedTarget} && ${PopCan} && ${Ship.ModuleList_TractorBeams.Count} > 0 && ${Entity[${CurrentCan}].Distance} > LOOT_RANGE
		{
			if !${Entity[${CurrentCan}].BeingTargeted}
			{
				Entity[${CurrentCan}]:LockTarget
				return FALSE
			}
			return FALSE
		}
		
		if ${Entity[${CurrentCan}].Distance} > LOOT_RANGE
		{
			if ${Ship.ModuleList_TractorBeams.Count} > 0 && ${PopCan} && ${Entity[${CurrentCan}].Distance} <= ${Ship.ModuleList_TractorBeams.Range}
			{
				if !${Ship.ModuleList_TractorBeams.IsActiveOn[${CurrentCan}]}
				{
					Ship.ModuleList_TractorBeams:Activate[${CurrentCan}]
					return FALSE
				}
			}
			else
			{
				Move:Approach[${CurrentCan}, LOOT_RANGE]
				return FALSE
			}
		}
		else
		{
			if !${EVEWindow[Inventory].ChildWindow[${CurrentCan}](exists)}
			{
				Entity[${CurrentCan}]:Open
				return FALSE
			}
			if !${EVEWindow[ByItemID, ${CurrentCan}](exists)}
			{
				EVEWindow[Inventory].ChildWindow[${CurrentCan}]:MakeActive
				return FALSE
			}
			Cargo:PopulateCargoList[Container, ${CurrentCan}]
			
			if ${EVEWindow[Inventory].ChildWindow[${CurrentCan}].UsedCapacity} > ${Math.Calc[${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].Capacity} - ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].UsedCapacity}]}
			{
				if ${PopCan}
				{
					Cargo:MoveCargoList[Ship]
				}
				else
				{
					Cargo:DontPopCan
				}
				Ship.ModuleList_TractorBeams:Deactivate[${CurrentCan}]
				Entity[${CurrentCan}]:UnlockTarget
				return TRUE
			}
			else
			{
				if ${PopCan}
				{
					Cargo:MoveCargoList[Ship]
				}
				else
				{
					Cargo:DontPopCan
					Entity[${CurrentCan}]:UnlockTarget
					if ${Config.JetCanMode.Equal["Service Corporate Bookmarks"]}
					{
						variable index:bookmark Bookmarks
						variable iterator BookmarkIterator
						EVE:GetBookmarks[Bookmarks]
						Bookmarks:GetIterator[BookmarkIterator]
						if ${BookmarkIterator:First(exists)}
						do
						{
							if ${BookmarkIterator.Value.Label.Left[5].Upper.Equal["Haul:"]} && ${BookmarkIterator.Value.CreatorID.Equal[${BookmarkCreator}]}
							{
								if ${BookmarkIterator.Value.JumpsTo} == 0
								{
									if ${BookmarkIterator.Value.Distance} < 500000
									{
										UI:Update["obj_Hauler", "Finished Salvaging ${BookmarkIterator.Value.Label} - Deleting", "g"]
										BookmarkIterator.Value:Remove
										return TRUE
									}
								}
							}
						}
						while ${BookmarkIterator:Next(exists)}
					}
					
					if ${Config.JetCanMode.Equal["Service On-Demand"]}
					{
						OnDemandHaulQueue:Dequeue
					}
					return TRUE
				}
			}
			return FALSE
		}
		return FALSE
	}

	member:bool DepopulateTargetList()
	{
		IR_Cans.AutoLock:Set[FALSE]
		OOR_Cans.AutoLock:Set[FALSE]
		CurrentCan:Set[-1]
		return TRUE
	}	
	
	
	member:bool ProcessQueue()
	{
		Cargo:At[${This.HaulQueue.Get[1].Bookmark},${This.HaulQueue.Get[1].LocationType},${This.HaulQueue.Get[1].LocationSubtype},${This.HaulQueue.Get[1].Container}]:${This.HaulQueue.Get[1].Action}["",0]
		if ${Config.Repeat}
		{
			This.HaulQueue:Insert[${This.HaulQueue.Get[1].Bookmark},${This.HaulQueue.Get[1].Action},${This.HaulQueue.Get[1].LocationType},${This.HaulQueue.Get[1].LocationSubtype},${This.HaulQueue.Get[1].Container},"",0]
		}
		This:Remove
		if ${This.HaulQueue.Used} == 0
		{
			This:Clear
			This:QueueState["Traveling"]
			This:QueueState["Log", 1000, "Haul operations complete - idling, o"]
			return TRUE
		}
		This:QueueState["ProcessQueue"]
		This:QueueState["Traveling"]
		return TRUE
	}

	member:bool Log(string text, string color)
	{
		UI:Update["obj_Hauler", "${text}", "${color}"]
		return TRUE
	}
	
	method Add(string Action)
	{
		switch ${Action}
		{
			case Load
				This.HaulQueue:Insert[${Config.Pickup},${Action},${Config.PickupType},${Config.PickupSubType},${Config.PickupContainer},"",0]
				break
			case Unload
				This.HaulQueue:Insert[${Config.Dropoff},${Action},${Config.DropoffType},${Config.DropoffSubType},${Config.DropoffContainer},"",0]
				break
			case Move
				This.HaulQueue:Insert[${Config.Move},${Action},"","","","",0]
				break
		}
		LocalUI:UpdateQueueList
	}

	method Remove(int ID=0)
	{
		This.HaulQueue:Remove[${ID:Inc}]
		This.HaulQueue:Collapse
		LocalUI:UpdateQueueList
	}
	
	
	
	;	HAUL IS NOT USED ANYMORE - It remains here to be used as a palette for future jetcan implementations
	
	member:bool Haul()
	{

				Switch ${Config.PickupSubType}
				{
					case Fleet Jetcan
							;	Already implemented
						break
					case Corporate Bookmark Jetcan
						variable string Target
						variable string BookmarkTime="24:00"
						variable bool BookmarkFound
						variable string BookmarkDate="9999.99.99"
						variable int64 BookmarkCreator
						variable index:bookmark Bookmarks
						variable iterator BookmarkIterator
						EVE:GetBookmarks[Bookmarks]
						Bookmarks:GetIterator[BookmarkIterator]
						if ${BookmarkIterator:First(exists)}
						do
						{	
							if ${BookmarkIterator.Value.Label.Left[5].Upper.Equal["Haul:"]} && ${BookmarkIterator.Value.JumpsTo} <= 0
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
						while ${BookmarkIterator:Next(exists)}
						
						if ${BookmarkIterator:First(exists)} && !${BookmarkFound}
						do
						{	
							if ${BookmarkIterator.Value.Label.Left[8].Upper.Equal[${Config.Salvager.Salvager_Prefix}]}
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
						while ${BookmarkIterator:Next(exists)}
						
						if ${BookmarkFound}
						{
							;UI:Update["obj_Miner", "Looting cans for ${FleetMembers.Get[1].ToPilot.Name}", "g"]
							This:Clear
							Move:Bookmark[${Target}, TRUE]
							This:QueueState["Traveling", 1000]
							This:QueueState["PopulateTargetList", 2000, ${BookmarkCreator}]
							This:QueueState["CheckTargetList", 50]
							This:QueueState["LootCans", 1000, ${BookmarkCreator}]
							This:QueueState["DepopulateTargetList", 2000]
							This:QueueState["Haul"]
							return TRUE
						}
						
						break
						
					case On-Demand Jetcan
						
						if ${Entity[${OnDemandHaulQueue.Peek.BeltID}](exists)}
						{
							
							Move:Object[${OnDemandHaulQueue.Peek.BeltID}]
							This:QueueState["Traveling", 1000]
							This:QueueState["PopulateTargetList", 2000, ${OnDemandHaulQueue.Peek.CharID}]
							This:QueueState["CheckTargetList", 50]
							This:QueueState["LootCans", 1000, ${OnDemandHaulQueue.Peek.CharID}]
							This:QueueState["DepopulateTargetList", 2000]
							This:QueueState["Haul"]
							return TRUE
						}
						
						break
				}

	}
	

	
}	


objectdef obj_HaulerUI inherits obj_State
{


	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
	}
	
	method Start()
	{
		if ${This.IsIdle}
		{
			This:QueueState["UpdateBookmarkLists", 5]
		}
	}
	
	method Stop()
	{
		This:Clear
	}

	
	method UpdateQueueList()
	{
		variable iterator Haul
		Hauler.HaulQueue:GetIterator[Haul]
		UIElement[Queue@QueueFrame@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler]:ClearItems
		if ${Haul:First(exists)}
			do
			{
				UIElement[Queue@QueueFrame@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler]:AddItem[${Haul.Value.Action} at ${Haul.Value.Bookmark} - ${Haul.Value.LocationType} ${Haul.Value.LocationSubtype} ${Haul.Value.Container}]
			}
			while ${Haul:Next(exists)}
	}
	
	member:bool UpdateBookmarkLists()
	{
		variable index:bookmark Bookmarks
		variable iterator BookmarkIterator

		EVE:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		
		UIElement[DropoffList@DropoffFrame@Continuous@HaulerTab@Hauler_Frame@ComBot_Hauler]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[Dropoff@DropoffFrame@Continuous@HaulerTab@Hauler_Frame@ComBot_Hauler].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Hauler.Config.Dropoff.Length}].Equal[${Hauler.Config.Dropoff}]}
						UIElement[DropoffList@DropoffFrame@Continuous@HaulerTab@Hauler_Frame@ComBot_Hauler]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[DropoffList@DropoffFrame@Continuous@HaulerTab@Hauler_Frame@ComBot_Hauler]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}
			
		UIElement[PickupList@PickupFrame@Continuous@HaulerTab@Hauler_Frame@ComBot_Hauler]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[Pickup@PickupFrame@Continuous@HaulerTab@Hauler_Frame@ComBot_Hauler].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Hauler.Config.Pickup.Length}].Equal[${Hauler.Config.Pickup}]}
						UIElement[PickupList@PickupFrame@Continuous@HaulerTab@Hauler_Frame@ComBot_Hauler]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[PickupList@PickupFrame@Continuous@HaulerTab@Hauler_Frame@ComBot_Hauler]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}
		
		UIElement[PickupList@PickupFrame@Load@Action@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[Pickup@PickupFrame@Load@Action@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Hauler.Config.Pickup.Length}].Equal[${Hauler.Config.Pickup}]}
						UIElement[PickupList@PickupFrame@Load@Action@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[PickupList@PickupFrame@Load@Action@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}

		UIElement[DropoffList@DropoffFrame@Unload@Action@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[Dropoff@DropoffFrame@Unload@Action@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Hauler.Config.Dropoff.Length}].Equal[${Hauler.Config.Dropoff}]}
						UIElement[DropoffList@DropoffFrame@Unload@Action@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[DropoffList@DropoffFrame@Unload@Action@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}
			
		UIElement[MoveList@MoveFrame@Move@Action@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[Move@MoveFrame@Move@Action@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Hauler.Config.Move.Length}].Equal[${Hauler.Config.Move}]}
						UIElement[MoveList@MoveFrame@Move@Action@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[MoveList@MoveFrame@Move@Action@Queue@HaulerTab@Hauler_Frame@ComBot_Hauler]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}
			
		return FALSE
	}

}