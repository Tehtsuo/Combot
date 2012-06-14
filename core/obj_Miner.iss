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

	method Initialize()
	{
		This[parent]:Initialize
		This:AssignStateQueueDisplay[obj_MinerStateList@Miner@ComBotTab@ComBot]
		PulseFrequency:Set[20]
		UI:Update["obj_Miner", "Initialized", "g"]
	}

	method Start()
	{
		UI:Update["obj_Miner", "Started", "g"]
		if ${This.IsIdle}
		{
			Asteroids:QueueState["UpdateList"]
			This:QueueState["Idle", 2000]
			This:QueueState["Mine"]
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
		switch ${Config.Miner.Miner_Dropoff_Type}
		{
			case Orca
				variable int64 Orca
				if !${Entity[${Config.Miner.Miner_OrcaName}](exists)} && ${Local[${Config.Miner.Miner_OrcaName}].ToFleetMember(exists)}
				{
					Orca:Set[${Local[${Config.Miner.Miner_OrcaName}].ToFleetMember.ID}]
					Me.Fleet.FleetMember[${Orca}]:WarpTo
					Client:Wait[5000]
					This:QueueState["Traveling", 1000]
				}
				break
			case Do Nothing
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
		This:Clear
		Move:System[${EVE.Bookmark[${Config.Miner.MiningSystem}].SolarSystemID}]
		This:QueueState["Traveling", 1000]
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
		This:QueueState["OpenCargoHold", 10]

		if !${Client.InSpace}
		{
			This:QueueState["CheckCargoHold", 1000]
			This:QueueState["GoToMiningSystem", 1000]
			return TRUE
		}
		
		
		if ${Asteroids.AsteroidList.Used} == 0
		{
			Drones:Recall
			UI:Update["obj_Miner", "${Asteroids.AsteroidList.Used} asteroids found, moving to another belt", "g"]
			This:QueueState["CheckCargoHold", 1000]
			This:QueueState["GoToMiningSystem", 1000]
			return TRUE
		}

		echo Setting Aggresive
		Drones:RemainDocked
		Drones:Aggressive
		
		if ${Config.Miner.Miner_Dropoff_Type.Equal[Orca]}
		{
			variable int64 Orca
			if ${Entity[${Config.Miner.Miner_OrcaName}](exists)}
			{
				Orca:Set[${Entity[${Config.Miner.Miner_OrcaName}].ID}]
				if ${Entity[${Orca}].Distance} > LOOT_RANGE
				{
					Move:Approach[${Orca}, LOOT_RANGE]
					return FALSE
				}
				else
				{
					if !${EVEWindow[ByItemID, ${Orca}](exists)}
					{
						UI:Update["obj_Miner", "Opening ${Config.Miner.Miner_OrcaName}'s Corporate Hangar", "g"]
						Entity[${Orca}]:Open
						return FALSE
					}
					if  ${EVEWindow[ByItemID, ${Orca}](exists)} &&\
						(${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > 0.10
					{
						UI:Update["obj_Miner", "Unloading to ${Config.Miner.Miner_OrcaName}'s Corporate Hangar", "g"]
						Cargo:PopulateCargoList[SHIP]
						Cargo:MoveCargoList[SHIPCORPORATEHANGAR, "Corporation Folder 1", ${Orca}]
						return FALSE
					}
				}
			}
		}
		
		if ${Config.Miner.IceMining}
		{
			if  ${Targets.Asteroids.Used} < 1
			{
				This:QueueState["TargetAsteroids", 50, 1]
				This:QueueState["Mine"]
				return TRUE
				
			}
		}
		else
		{
			if  ${Targets.Asteroids.Used} < ${Ship.ModuleList_MiningLaser.Count}
			{
				This:QueueState["TargetAsteroids"]
				This:QueueState["Mine"]
				return TRUE
			}
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
		}
		return TRUE
	}
	
	member:bool TargetAsteroids()
	{
		if ${Targets.Asteroids.Used} == ${Ship.ModuleList_MiningLaser.Count}
		{
			return TRUE
		}
		variable iterator Roid
		Asteroids.AsteroidList:GetIterator[Roid]
		if ${Roid:First(exists)}
		do
		{
			if ${Targets.AsteroidIsInRangeOfOthers[${Roid.Value.ID}]}
			{
				if  !${Roid.Value.BeingTargeted} &&\
					!${Roid.Value.IsLockedTarget} &&\
					${Roid.Value.Distance} >= ${MyShip.MaxTargetRange}
				{
					Move:Approach[${Roid.Value.ID}, ${MyShip.MaxTargetRange}]
					return FALSE
				}

				if  !${Roid.Value.BeingTargeted} &&\
					!${Roid.Value.IsLockedTarget}
				{
					UI:Update["obj_Miner", "Locking ${Roid.Value.Name} (${ComBot.MetersToKM_Str[${Roid.Value.Distance}]})", "y"]
					Roid.Value:LockTarget
					return FALSE
				}
			}
		}
		while ${Roid:Next(exists)}
		return FALSE
	}

	member:bool ActivateLasers()
	{
		if  ${Ship.ModuleList_MiningLaser.ActiveCount} == ${Ship.ModuleList_MiningLaser.Count} ||\
			${Targets.Asteroids.Used} < ${Ship.ModuleList_MiningLaser.Count}
		{
			return TRUE
		}
		variable iterator Roid
		Targets.Asteroids:GetIterator[Roid]
		if ${Roid:First(exists)}
		do
		{
			if  ${Roid.Value.BeingTargeted}
			{
				continue
			}
			if	${Roid.Value.Distance} > ${Ship.Module_MiningLaser_Range}
			{
				Move:Approach[${Roid.Value.ID}, ${Ship.Module_MiningLaser_Range}]
				return FALSE
			}
			if ${Config.Miner.IceMining}
			{
				UI:Update["obj_Miner", "Activating ${Ship.ModuleList_MiningLaser.InActiveCount} laser(s) on ${Roid.Value.Name} (${ComBot.MetersToKM_Str[${Roid.Value.Distance}]})", "y"]
				Ship.ModuleList_MiningLaser:ActivateCount[${Ship.ModuleList_MiningLaser.InActiveCount}, ${Roid.Value.ID}]
				return FALSE
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
	
}	