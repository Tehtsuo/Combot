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

objectdef obj_Hauler inherits obj_State
{
	variable float OrcaCargo
	variable index:fleetmember FleetMembers
	variable int64 CurrentCan
	variable bool PopCan
	
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
	}

	method Shutdown()
	{
		Event[ComBot_Orca_Cargo]:DetachAtom[This:OrcaCargoUpdate]
	}	
	
	method Start()
	{
		UI:Update["obj_Hauler", "Started", "g"]
		This:AssignStateQueueDisplay[DebugStateList@Debug@ComBotTab@ComBot]
		if ${This.IsIdle}
		{
			This:QueueState["Haul"]
		}
	}
	
	method Stop()
	{
		This:DeactivateStateQueueDisplay

		UI:Update["obj_Hauler", "Stopped", "r"]
		This:Clear
	}
	method PopulateTargetList(int64 ID)
	{
		variable int64 CharID = ${Entity[${ID}].CharID}
		IR_Cans:ClearQueryString
		IR_Cans:AddQueryString["GroupID==GROUP_CARGOCONTAINER && OwnerID == ${CharID}"]
		IR_Cans.DistanceTarget:Set[${ID}]
		OOR_Cans:ClearQueryString
		OOR_Cans:AddQueryString["GroupID==GROUP_CARGOCONTAINER && OwnerID == ${CharID}"]
		OOR_Cans.DistanceTarget:Set[${ID}]
	}	
	
	
	member:bool OpenCargoHold()
	{
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["obj_Hauler", "Opening inventory", "g"]
			MyShip:Open
			return FALSE
		}
		return TRUE
	}
	
	member:bool CheckCargoHold()
	{
		switch ${Config.Hauler.Dropoff_Type}
		{
			case Container
				if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) >= ${Config.Hauler.Threshold} * .01
				{
					UI:Update["obj_Hauler", "Unload trip required", "g"]
					This:Clear
					Move:Bookmark[${Config.Hauler.Dropoff_Bookmark}]
					This:QueueState["Traveling", 1000]
					This:QueueState["Haul"]
				}
				break
			default
				echo (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) >= ${Config.Hauler.Threshold} * .01
				if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) >= ${Config.Hauler.Threshold} * .01
				{
					UI:Update["obj_Hauler", "Unload trip required", "g"]
					This:Clear
					Move:Bookmark[${Config.Hauler.Dropoff_Bookmark}]
					This:QueueState["Traveling", 1000]
					This:QueueState["PrepOffload", 1000]
					This:QueueState["Offload", 1000]
					This:QueueState["StackItemHangar", 1000]
					This:QueueState["OrcaWait"]
					This:QueueState["GoToPickup", 1000]
					This:QueueState["Traveling", 1000]
					This:QueueState["Haul"]
				}
				break
		}
		return TRUE;
	}

	member:bool OrcaWait()
	{
		if ${Config.Hauler.Pickup_Type.Equal[Orca]}
		{
			if ${OrcaCargo} > ${Config.Hauler.Threshold} * .01 * ${MyShip.CargoCapacity}
			{
				return TRUE
			}
			else
			{
				return FALSE
			}
		}
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

	member:bool PrepOffload()
	{	
		if ${Client.InSpace}
		{
			return TRUE
		}
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["obj_Hauler", "Opening inventory", "g"]
			MyShip:OpenCargo[]
			return FALSE
		}
		switch ${Config.Hauler.Dropoff_Type}
		{
			case Personal Hangar
				break
			default
				if !${EVEWindow[ByName, Inventory].ChildWindowExists[Corporation Hangars]}
				{
					UI:Update["obj_Hauler", "Delivery Location: Corporate Hangars child not found", "r"]
					UI:Update["obj_Hauler", "Closing inventory to fix possible EVE bug", "y"]
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
		UI:Update["obj_Hauler", "Unloading cargo", "g"]
		Cargo:PopulateCargoList[SHIP]
		switch ${Config.Hauler.Dropoff_Type}
		{
			case Personal Hangar
				Cargo:MoveCargoList[HANGAR]
				break
			default
				Cargo:MoveCargoList[CORPORATEHANGAR, ${Config.Hauler.Dropoff_Type}]
				break
		}
		return TRUE
	}

	member:bool Pickup()
	{
		switch ${Config.Hauler.Pickup_Type}
		{
			case Personal Hangar
				UI:Update["obj_Hauler", "Loading cargo", "g"]
				Cargo:PopulateCargoList[STATIONHANGAR]
				Cargo:MoveCargoList[SHIP]
				break
			case Corporation Hangar
				UI:Update["obj_Hauler", "Loading cargo", "g"]
				Cargo:PopulateCargoList[STATIONCORPORATEHANGAR]
				Cargo:MoveCargoList[SHIP]
				break
		}
		return TRUE
	}
	
	member:bool StackItemHangar()
	{
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["obj_Hauler", "Making sure inventory is open", "g"]
			MyShip:Open
			return FALSE
		}

		UI:Update["obj_Hauler", "Stacking dropoff container", "g"]
		switch ${Config.Hauler.Dropoff_Type}
		{
			case Personal Hangar
				EVE:StackItems[MyStationHangar, Hangar]
				break
			default
				EVE:StackItems[MyStationCorporateHangar, StationCorporateHangar, "${Config.Hauler.Dropoff_Type}"]
				break
		}
		return TRUE
	}
	
	member:bool GoToPickup()
	{
		if !${EVE.Bookmark[${Config.Hauler.Pickup_Bookmark}](exists)}
		{
			UI:Update["obj_Hauler", "No Pickup Bookmark defined!  Check your settings", "r"]
		}
		if ${EVE.Bookmark[${Config.Hauler.Pickup_Bookmark}].SolarSystemID} != ${Me.SolarSystemID}
		{
			Move:System[${EVE.Bookmark[${Config.Hauler.Pickup_Bookmark}].SolarSystemID}]
		}
		return TRUE
	}

	member:bool Undock()
	{
		Move:Undock
		return TRUE
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

	
	member:bool LootCans(int64 ID)
	{
		variable iterator CanIter
		
		if ${MyShip.UsedCargoCapacity} > (${Config.Hauler.Threshold} * .01 * ${MyShip.CargoCapacity})
		{
			return TRUE
		}
		
		echo ${IR_Cans.TargetList.Used} cans in range
		echo ${OOR_Cans.TargetList.Used} cans out of range
		
		OOR_Cans:RequestUpdate
		IR_Cans:RequestUpdate
		
		if !${Entity[${CurrentCan}](exists)}
		{
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
			if ${Ship.ModuleList_TractorBeams.Count} > 0 && ${PopCan}
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
			if !${EVEWindow[ByName, Inventory].ChildWindowExists[${CurrentCan}]}
			{
				UI:Update["obj_Hauler", "Opening - ${Entity[${CurrentCan}].Name}", "g"]
				Entity[${CurrentCan}]:OpenCargo
				return FALSE
			}
			if !${EVEWindow[ByItemID, ${CurrentCan}](exists)}
			{
				UI:Update["obj_Hauler", "Activating - ${Entity[${CurrentCan}].Name}", "g"]
				EVEWindow[ByName, Inventory]:MakeChildActive[${CurrentCan}]
				return FALSE
			}
			UI:Update["obj_Hauler", "Looting - ${Entity[${CurrentCan}].Name}", "g"]
			Cargo:PopulateCargoList[CONTAINER, ${CurrentCan}]
			if ${EVEWindow[ByItemID, ${CurrentCan}].UsedCapacity} > ${Math.Calc[${MyShip.CargoCapacity} - ${MyShip.UsedCargoCapacity}]}
			{
				if ${PopCan}
				{
					Cargo:MoveCargoList[SHIP]
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
					Cargo:MoveCargoList[SHIP]
				}
				else
				{
					Cargo:DontPopCan
					Entity[${CurrentCan}]:UnlockTarget
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
	
	
	member:bool Haul()
	{
		variable int64 Container

		This:Clear
		This:QueueState["OpenCargoHold", 10]

		if !${Client.InSpace}
		{
			This:QueueState["CheckCargoHold", 1000]
			This:QueueState["Pickup"]
			This:QueueState["OrcaWait"]
			This:QueueState["Undock"]
			This:QueueState["Haul"]
			return TRUE
		}
		else
		{
			This:QueueState["CheckCargoHold"]
			This:QueueState["GoToPickup"]
			This:QueueState["Traveling", 1000]
			This:QueueState["Haul"]
			if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) >= ${Config.Hauler.Threshold} * .01
			{
				echo Exiting before Haul - (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) >= ${Config.Hauler.Threshold} * .01
				return TRUE
			}
		}

		if ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}

		
		switch ${Config.Hauler.Pickup_Type}
		{
			case Orca
				echo Orca
				if ${Entity[Name = "${Config.Hauler.Pickup_ContainerName}"](exists)}
				{
					Container:Set[${Entity[Name = "${Config.Hauler.Pickup_ContainerName}"].ID}]
					if ${Entity[${Container}].Distance} > LOOT_RANGE
					{
						Move:Approach[${Container}, LOOT_RANGE]
						return FALSE
					}
					else
					{
						if ${OrcaCargo}
						{
							if !${EVEWindow[ByName, Inventory].ChildWindowExists[${Container}]}
							{
								UI:Update["obj_Hauler", "Opening ${Config.Hauler.Pickup_ContainerName}", "g"]
								Entity[${Container}]:Open
								return FALSE
							}
							if !${EVEWindow[ByItemID, ${Container}](exists)} 
							{
								EVEWindow[ByName, Inventory]:MakeChildActive[${Container}]
								return FALSE
							}
							Cargo:PopulateCargoList[CONTAINERCORPORATEHANGAR, ${Container}]
							Cargo:MoveCargoList[SHIP]
							This:Clear
							This:QueueState["Idle", 1000]
							This:QueueState["CheckCargoHold"]
							This:QueueState["Haul"]
							return TRUE
						}
					}
				}
				else
				{
					echo Check for orca
					if ${Local[${Config.Hauler.Pickup_ContainerName}].ToFleetMember(exists)}
						{
							UI:Update["obj_Hauler", "Warping to ${Local[${Config.Hauler.Pickup_ContainerName}].ToFleetMember.ToPilot.Name}", "g"]
							Local[${Config.Hauler.Pickup_ContainerName}].ToFleetMember:WarpTo
							Client:Wait[5000]
							This:Clear
							This:QueueState["Traveling", 1000]
							This:QueueState["Haul"]
							return TRUE
						}
				}
				break

			case Container
				if ${Entity[Name = "${Config.Hauler.Pickup_ContainerName}"](exists)}
				{
					Container:Set[${Entity[Name = "${Config.Hauler.Pickup_ContainerName}"].ID}]
					if ${Entity[${Container}].Distance} > LOOT_RANGE
					{
						Move:Approach[${Container}, LOOT_RANGE]
						return FALSE
					}
					else
					{
						if !${EVEWindow[ByName, Inventory].ChildWindowExists[${Container}]}
						{
							UI:Update["obj_Hauler", "Opening ${Config.Hauler.Pickup_ContainerName}", "g"]
							Entity[${Container}]:Open
							return FALSE
						}
						if !${EVEWindow[ByItemID, ${Container}](exists)} 
						{
							EVEWindow[ByName, Inventory]:MakeChildActive[${Container}]
							return FALSE
						}
						Cargo:PopulateCargoList[CONTAINERCORPORATEHANGAR, ${Container}]
						Cargo:MoveCargoList[SHIP]
						This:Clear
						This:QueueState["Idle", 1000]
						This:QueueState["CheckCargoHold"]
						This:QueueState["Haul"]
						return TRUE
					}
				}
				else
				{
					Move:Bookmark[${Config.Hauler.Pickup_Bookmark}]
					This:Clear
					This:QueueState["Traveling", 1000]
					This:QueueState["Haul"]
					return TRUE
				}
				break
			case Jetcan
				if ${MyShip.UsedCargoCapacity} > (${Config.Hauler.Threshold} * .01 * ${MyShip.CargoCapacity}) || ${EVE.Bookmark[${Config.Hauler.Pickup_Bookmark}].SolarSystemID} != ${Me.SolarSystemID}
				{
					break
				}
				if !${FleetMembers.Used}
				{
					Me.Fleet:GetMembers[FleetMembers]
					FleetMembers:RemoveByQuery[${LavishScript.CreateQuery[ID == ${Me.CharID}]}]
					FleetMembers:Collapse
				}

				if ${FleetMembers.Get[1].ToEntity(exists)}
				{
					UI:Update["obj_Miner", "Looting cans for ${FleetMembers.Get[1].ToPilot.Name}", "g"]
					This:Clear
					This:QueueState["PopulateTargetList", 2000, ${FleetMembers.Get[1].ToEntity.ID}]
					This:QueueState["CheckTargetList", 50]
					This:QueueState["LootCans", 2000]
					This:QueueState["DepopulateTargetList", 2000]
					This:QueueState["Haul"]
					FleetMembers:Remove[1]
					FleetMembers:Collapse
					return TRUE
				}
				else
				{
					Move:Fleetmember[${FleetMembers.Get[1].ID}]
					This:Clear
					This:QueueState["Traveling", 1000]
					This:QueueState["Haul"]
					return TRUE
				}
			
				break
				
			default
			
			Move:Bookmark[${Config.Hauler.Pickup_Bookmark}]
			
		}
		
		if ${Config.Hauler.Dropoff_Type.Equal[Container]}
		{
			if ${Entity[Name = "${Config.Hauler.Dropoff_ContainerName}"](exists)}
			{
				Container:Set[${Entity[Name = "${Config.Hauler.Dropoff_ContainerName}"].ID}]
				if ${Entity[${Container}].Distance} > LOOT_RANGE
				{
					Move:Approach[${Container}, LOOT_RANGE]
					return FALSE
				}
				else
				{
					if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > 0.10
					{
						if !${EVEWindow[ByName, Inventory].ChildWindowExists[${Container}]}
						{
							UI:Update["obj_Miner", "Opening ${Config.Hauler.Dropoff_ContainerName}", "g"]
							Entity[${Container}]:Open
							return FALSE
						}
						if !${EVEWindow[ByItemID, ${Container}](exists)}
						{
							EVEWindow[ByName, Inventory]:MakeChildActive[${Container}]
							return FALSE
						}
						;UI:Update["obj_Miner", "Unloading to ${Config.Hauler.Dropoff_ContainerName}", "g"]
						Cargo:PopulateCargoList[SHIP]
						Cargo:MoveCargoList[SHIPCORPORATEHANGAR, "", ${Container}]
						This:QueueState["Idle", 1000]
						This:QueueState["Haul"]
						return TRUE
					}
				}
			}
		}
		
		if ${Ship.ModuleList_GangLinks.ActiveCount} < ${Ship.ModuleList_GangLinks.Count}
		{
			Ship.ModuleList_GangLinks:ActivateCount[${Math.Calc[${Ship.ModuleList_GangLinks.Count} - ${Ship.ModuleList_GangLinks.ActiveCount}]}]
		}
		
	
		return TRUE
	}
	

	method OrcaCargoUpdate(float value)
	{
		OrcaCargo:Set[${value}]
		UIElement[obj_HaulerOrcaCargo@Hauler@ComBotTab@ComBot]:SetText[Orca Cargo Hold: ${OrcaCargo.Round} m3]
	}
	
}	