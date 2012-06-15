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

	method Initialize()
	{
		This[parent]:Initialize
		LavishScript:RegisterEvent[ComBot_Orca_Cargo]
		Event[ComBot_Orca_Cargo]:AttachAtom[This:OrcaCargoUpdate]
		This:AssignStateQueueDisplay[obj_HaulerStateList@Hauler@ComBotTab@ComBot]
		PulseFrequency:Set[20]
		UI:Update["obj_Hauler", "Initialized", "g"]
	}

	method Shutdown()
	{
		Event[ComBot_Orca_Cargo]:DetachAtom[This:OrcaInBelt]
	}	
	
	method Start()
	{
		UI:Update["obj_Hauler", "Started", "g"]
		if ${This.IsIdle}
		{
			This:QueueState["Haul"]
		}
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
		switch ${Config.Hauler.Hauler_Dropoff_Type}
		{
			default
				if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > 0.95
				{
					UI:Update["obj_Hauler", "Unload trip required", "g"]
					This:Clear
					Move:Bookmark[${Config.Hauler.Hauler_Dropoff}]
					This:QueueState["Traveling", 1000]
					This:QueueState["Offload", 1000]
					This:QueueState["StackItemHangar", 1000]
					This:QueueState["GoToMiningSystem", 1000]
				}
				break
		}
		This:QueueState["Haul"]
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
		UI:Update["obj_Hauler", "Unloading cargo", "g"]
		Cargo:PopulateCargoList[SHIP]
		switch ${Config.Hauler.Hauler_Dropoff_Type}
		{
			case Personal Hangar
				Cargo:MoveCargoList[HANGAR]
				break
			default
				Cargo:MoveCargoList[CORPORATEHANGAR, ${Config.Hauler.Hauler_Dropoff_Type}]
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
		switch ${Config.Hauler.Hauler_Dropoff_Type}
		{
			case Personal Hangar
				EVE:StackItems[MyStationHangar, Hangar]
				break
			default
				EVE:StackItems[MyStationCorporateHangar, StationCorporateHangar, "${Config.Hauler.Hauler_Dropoff_Type.Escape}"]
				break
		}
		return TRUE
	}
	
	member:bool GoToMiningSystem()
	{
		if !${EVE.Bookmark[${Config.Hauler.MiningSystem}](exists)}
		{
			UI:Update["obj_Hauler", "No mining system defined!  Check your settings", "r"]
		}
		if ${EVE.Bookmark[${Config.Hauler.MiningSystem}].SolarSystemID} != ${Me.SolarSystemID}
		{
			This:Clear
			Move:System[${EVE.Bookmark[${Config.Hauler.MiningSystem}].SolarSystemID}]
			This:QueueState["Traveling", 1000]
		}
		This:QueueState["Haul"]
		return TRUE
	}

	
	
	
	member:bool Haul()
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
		
		
		if ${Config.Hauler.Hauler_Dropoff_Type.Equal[Container]}
		{
			variable int64 Container
			if ${Entity[Name = "${Config.Hauler.Hauler_ContainerName}"](exists)}
			{
				Container:Set[${Entity[Name = "${Config.Hauler.Hauler_ContainerName}"].ID}]
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
							UI:Update["obj_Hauler", "Opening ${Config.Hauler.Hauler_ContainerName}", "g"]
							Entity[${Container}]:Open
							return FALSE
						}
						if !${EVEWindow[ByItemID, ${Container}](exists)}
						{
							EVEWindow[ByName, Inventory]:MakeChildActive[${Container}]
							return FALSE
						}
						UI:Update["obj_Hauler", "Unloading to ${Config.Hauler.Hauler_ContainerName}", "g"]
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
		

		This:QueueState["CheckCargoHold"]
		return TRUE
	}
	

	method OrcaInBelt(bool value)
	{
		WarpToOrca:Set[${value}]
	}
	
}	