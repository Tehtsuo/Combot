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
		if !${Client.InSpace}
		{
			This:QueueState["OpenCargoHold", 1000]
			This:QueueState["CheckCargoHold", 1000]
			This:QueueState["GoToMiningSystem", 1000]
			return TRUE
		}
		if ${Asteroids.AsteroidList.Used} == 0
		{
			UI:Update["obj_Miner", "${Asteroids.AsteroidList.Used} asteroids found, moving to another belt", "g"]
			This:QueueState["OpenCargoHold", 1000]
			This:QueueState["CheckCargoHold", 1000]
			This:QueueState["GoToMiningSystem", 1000]
			return TRUE
		}
		if ${Ship.ModuleList_MiningLaser.InactiveCount} > 0
		{
			This:QueueState["ActivateLaser"]
			This:QueueState["Mine"]
			return TRUE
		}
		
		This:QueueState["CheckCargoHold"]
		return TRUE
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
			
			if  ${Roid.Value.Distance} > ${Ship.Module_MiningLaser_Range} &&\
				(${Roid.Value.IsLockedTarget} || ${Roid.Value.BeingTargeted})
			
			{
				Move:Approach[${Roid.Value}, ${Ship.Module_MiningLaser_Range}]
				return FALSE
			}

			if  !${Ship.ModuleList_MiningLaser.IsActiveOn[${Roid.Value.ID}]} &&\
				${Roid.Value.Distance} < ${Ship.Module_MiningLaser_Range} &&\
				${Ship.ModuleList_MiningLaser.InactiveCount} > 0 &&\
				${Roid.Value.IsLockedTarget}
			{
				UI:Update["obj_Miner", "Activating mining laser - ${Roid.Value.Name}", "g"]
				Ship.ModuleList_MiningLaser:Activate[${Roid.Value.ID}]
				return TRUE
			}
			

			
			
		}
		while ${Roid:Next(exists)}
	}
	
}	