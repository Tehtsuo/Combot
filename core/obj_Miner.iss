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

objectdef obj_Miner inherits obj_State
{
	variable obj_TargetList Asteroids
	variable bool WarpToOrca=FALSE

	method Initialize()
	{
		This[parent]:Initialize
		LavishScript:RegisterEvent[ComBot_Orca_InBelt]
		Event[ComBot_Orca_InBelt]:AttachAtom[This:OrcaInBelt]
		This:AssignStateQueueDisplay[obj_MinerStateList@Miner@ComBotTab@ComBot]
		PulseFrequency:Set[20]
		UI:Update["obj_Miner", "Initialized", "g"]
	}

	method Shutdown()
	{
		Event[ComBot_Orca_InBelt]:DetachAtom[This:OrcaInBelt]
	}	
	
	method Start()
	{
		This:PopulateTargetList
		Asteroids.AutoLock:Set[TRUE]
		Asteroids.AutoRelock:Set[TRUE]
		Asteroids.AutoRelockPriority:Set[TRUE]

		UI:Update["obj_Miner", "Started", "g"]
		if ${This.IsIdle}
		{
			This:QueueState["Mine"]
		}
	}
	
	method PopulateTargetList()
	{
		Asteroids:ClearQueryString
		
		variable iterator OreTypeIterator
		if ${Config.Miner.IceMining}
		{
			Config.Miner.IceTypesRef:GetSettingIterator[OreTypeIterator]
		}
		else
		{
			Config.Miner.OreTypesRef:GetSettingIterator[OreTypeIterator]
		}

		if ${OreTypeIterator:First(exists)}
		{		
			do
			{
				Asteroids:AddQueryString[CategoryID==CATEGORYID_ORE && Name =- "${OreTypeIterator.Key}"]
			}
			while ${OreTypeIterator:Next(exists)}			
		}
		else
		{
			echo "WARNING: obj_Miner: Ore Type list is empty, please check config"
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
		return TRUE
	}
	
	member:bool CheckCargoHold()
	{
		switch ${Config.Miner.Miner_Dropoff_Type}
		{
			case Orca
				if !${Entity[Name = "${Config.Miner.Miner_OrcaName}"](exists)} && ${Local[${Config.Miner.Miner_OrcaName}].ToFleetMember(exists)} && ${This.WarpToOrca}
				{
					UI:Update["obj_Miner", "Warping to ${Local[${Config.Miner.Miner_OrcaName}].ToFleetMember.ToPilot.Name}", "g"]
					Local[${Config.Miner.Miner_OrcaName}].ToFleetMember:WarpTo
					Client:Wait[5000]
					This:Clear
					This:QueueState["Traveling", 1000]
				}
				if !${This.WarpToOrca}
				{
					This:Clear
				}
				break
			case Container
				if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > 0.95
				{
					UI:Update["obj_Miner", "Unload trip required", "g"]
					if ${Config.Miner.OrcaMode}
					{
						relay all -event ComBot_Orca_InBelt FALSE
					}
					This:Clear
					Move:Bookmark[${Config.Miner.Miner_Dropoff}]
					This:QueueState["Traveling", 1000]
				}
				break
			case No Dropoff
				break
			default
				if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > 0.95
				{
					UI:Update["obj_Miner", "Unload trip required", "g"]
					This:Clear
					Move:Bookmark[${Config.Miner.Miner_Dropoff}]
					This:QueueState["Traveling", 1000]
					This:QueueState["Offload", 1000]
					This:QueueState["StackItemHangar", 1000]
					This:QueueState["GoToMiningSystem", 1000]
				}
				break
		}
		This:QueueState["Mine"]
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
		switch ${Config.Miner.Miner_Dropoff_Type}
		{
			case Personal Hangar
				Cargo:MoveCargoList[HANGAR]
				break
			default
				Cargo:MoveCargoList[CORPORATEHANGAR, ${Config.Miner.Miner_Dropoff_Type}]
				break
		}
		return TRUE
	}
	
	member:bool StackItemHangar()
	{
		variable int64 Orca
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["obj_Miner", "Making sure inventory is open", "g"]
			MyShip:Open
			return FALSE
		}

		UI:Update["obj_Miner", "Stacking dropoff container", "g"]
		switch ${Config.Miner.Miner_Dropoff_Type}
		{
			case Personal Hangar
				EVE:StackItems[MyStationHangar, Hangar]
				break
			case Orca
				if ${Entity[Name = "${Config.Miner.Miner_OrcaName}"](exists)}
				{
					EVE:StackItems[${Entity[Name = "${Config.Miner.Miner_OrcaName}"].ID}, CorpHangars]
				}
			default
				EVE:StackItems[MyStationCorporateHangar, StationCorporateHangar, "${Config.Miner.Miner_Dropoff_Type.Escape}"]
				break
		}
		return TRUE
	}
	
	member:bool GoToMiningSystem()
	{
		if !${EVE.Bookmark[${Config.Miner.MiningSystem}](exists)}
		{
			UI:Update["obj_Miner", "No mining system defined!  Check your settings", "r"]
		}
		if ${EVE.Bookmark[${Config.Miner.MiningSystem}].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:Clear
			Move:System[${EVE.Bookmark[${Config.Miner.MiningSystem}].SolarSystemID}]
			This:QueueState["Traveling", 1000]
		}
		This:QueueState["MoveToBelt", 1000]
		This:QueueState["Traveling", 1000]
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
			variable index:bookmark BookmarkIndex
			variable int RandomBelt
			EVE:GetBookmarks[BookmarkIndex]

			while ${BookmarkIndex.Used} > 0
			{
				RandomBelt:Set[${Math.Rand[${BookmarkIndex.Used}]:Inc[1]}]

				if ${Config.Miner.IceMining}
				{
					prefix:Set[${Config.Miner.IceBeltPrefix}]
				}
				else
				{
					prefix:Set[${Config.Miner.BeltPrefix}]
				}

				Label:Set[${BookmarkIndex[${RandomBelt}].Label}]

				if (${BookmarkIndex[${RandomBelt}].SolarSystemID} != ${Me.SolarSystemID} || \
					${Label.Left[${prefix.Length}].NotEqual[${prefix}]})
				{
					BookmarkIndex:Remove[${RandomBelt}]
					BookmarkIndex:Collapse
					continue
				}

				Move:Bookmark[${BeltBookMarkList[${BookmarkIndex}].Label}]

				return TRUE
			}	
		}
		else
		{
			if !${Client.InSpace}
			{
				Move:Undock
				return FALSE
			}
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

			Move:Object[${Entity[${Belts[${curBelt}].ID}]}]
			return TRUE
		}
	}
	
	member:bool Mine()
	{
		This:Clear
		This:QueueState["OpenCargoHold", 10]

		if !${Client.InSpace}
		{
			This:QueueState["CheckCargoHold", 1000]
			return TRUE
		}
		
		if ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		
		Asteroids.MaxLockCount:Set[${Ship.ModuleList_MiningLaser.Count}]
		
		if ${Config.Miner.Miner_Dropoff_Type.Equal[Orca]} || ${Config.Miner.Miner_Dropoff_Type.Equal[Container]}
		{
			variable int64 Orca
			if ${Entity[Name = "${Config.Miner.Miner_OrcaName}"](exists)}
			{
				Orca:Set[${Entity[Name = "${Config.Miner.Miner_OrcaName}"].ID}]
				Asteroids.DistanceTarget:Set[${Orca}]
				if ${Entity[${Orca}].Distance} > LOOT_RANGE
				{
					Move:Approach[${Orca}, LOOT_RANGE]
					return FALSE
				}
				else
				{
					if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > 0.10
					{
						if !${EVEWindow[ByName, Inventory].ChildWindowExists[${Orca}]}
						{
							UI:Update["obj_Miner", "Opening ${Config.Miner.Miner_OrcaName}", "g"]
							Entity[${Orca}]:Open
							return FALSE
						}
						if !${EVEWindow[ByItemID, ${Orca}](exists)}
						{
							EVEWindow[ByName, Inventory]:MakeChildActive[${Orca}]
							return FALSE
						}
						UI:Update["obj_Miner", "Unloading to ${Config.Miner.Miner_OrcaName}", "g"]
						Cargo:PopulateCargoList[SHIP]
						Cargo:MoveCargoList[SHIPCORPORATEHANGAR, "", ${Orca}]
						This:QueueState["Idle", 1000]
						This:QueueState["StackItemHangar"]
						This:QueueState["Mine"]
						return TRUE
					}
				}
			}
			else
			{
				Asteroids.DistanceTarget:Set[${MyShip.ID}]
			}
		}

		if !${Entity[CategoryID==CATEGORYID_ORE]}
		{
			if ${Config.Miner.OrcaMode}
			{
				relay all -event ComBot_Orca_InBelt FALSE
			}
			Drones:Recall
			UI:Update["obj_Miner", "No asteroids found, moving to a new belt", "g"]
			This:QueueState["CheckCargoHold", 1000]
			This:QueueState["MoveToBelt", 1000]
			This:QueueState["Traveling", 1000]
			return TRUE
		}

		if ${Config.Miner.OrcaMode}
		{
			relay all -event ComBot_Orca_InBelt TRUE
			relay all -event ComBot_Orca_Cargo ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]}
			if ${Config.Miner.IceMining}
			{
				Move:Approach[${Entity[CategoryID==CATEGORYID_ORE]}, 10000]
			}
			else
			{
				Move:Approach[${Entity[CategoryID==CATEGORYID_ORE]}, 8000]
			}
		}
		
		Drones:RemainDocked
		Drones:Aggressive
		
		if ${Ship.ModuleList_GangLinks.ActiveCount} < ${Ship.ModuleList_GangLinks.Count}
		{
			Ship.ModuleList_GangLinks:ActivateCount[${Math.Calc[${Ship.ModuleList_GangLinks.Count} - ${Ship.ModuleList_GangLinks.ActiveCount}]}]
		}
		
		if ${Ship.ModuleList_MiningLaser.ActiveCount} < ${Ship.ModuleList_MiningLaser.Count}
		{
			This:QueueState["ActivateLasers"]
			This:QueueState["Mine"]
			return TRUE
		}
		
		if !${Config.Miner.Miner_Dropoff_Type.Equal[No Dropoff]}
		{
			This:QueueState["CheckCargoHold"]
			return TRUE
		}
		return FALSE
	}


	member:bool ActivateLasers()
	{
		if  ${Ship.ModuleList_MiningLaser.ActiveCount} == ${Ship.ModuleList_MiningLaser.Count}
		{
			return TRUE
		}
		variable iterator Roid
		Asteroids.LockedTargetList:GetIterator[Roid]
		if ${Roid:First(exists)}
		do
		{
			if	${Roid.Value.Distance} > ${Ship.Module_MiningLaser_Range}
			{
				Move:Approach[${Roid.Value.ID}, ${Ship.Module_MiningLaser_Range}]
				return FALSE
			}
			if ${Config.Miner.IceMining}
			{
				UI:Update["obj_Miner", "Activating ${Ship.ModuleList_MiningLaser.InActiveCount} laser(s) on ${Roid.Value.Name} (${ComBot.MetersToKM_Str[${Roid.Value.Distance}]})", "y"]
				Ship.ModuleList_MiningLaser:ActivateCount[${Ship.ModuleList_MiningLaser.InActiveCount}, ${Roid.Value.ID}]
				return TRUE
			}
			else
			{
				if !${Ship.ModuleList_MiningLaser.IsActiveOn[${Roid.Value.ID}]}
				{
					UI:Update["obj_Miner", "Activating 1 laser on ${Roid.Value.Name} (${ComBot.MetersToKM_Str[${Roid.Value.Distance}]})", "y"]
					Ship.ModuleList_MiningLaser:Activate[${Roid.Value.ID}]
					return FALSE
				}
			}
		}
		while ${Roid:Next(exists)}
		return FALSE
	}
	
	member:bool ExpandContainer()
	{
		variable int64 Orca
		if ${Entity[Name = "${Config.Miner.Miner_OrcaName}"](exists)}
		{
			Orca:Set[${Entity[Name = "${Config.Miner.Miner_OrcaName}"].ID}]
			if ${EVEWindow[ByName, Inventory].ChildWindowExists[${Orca}]}
			{
				${EVEWindow[ByName, Inventory]:OpenChildAsNewWindow[${Orca}]
			}
		}
		return TRUE
	}
	
	method OrcaInBelt(bool value)
	{
		WarpToOrca:Set[${value}]
	}
	
}	