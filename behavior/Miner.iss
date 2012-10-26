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

objectdef obj_Configuration_Miner
{
	variable string SetName = "Miner"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["obj_Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["obj_Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	member:settingsetref OreTypesRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Ore_Types]}
	}

	member:settingsetref IceTypesRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Ice_Types]}
	}

	
	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.CommonRef:AddSet[ORE_Types]
		This.OreTypesRef:AddSetting[Vitreous Mercoxit, 1]
		This.OreTypesRef:AddSetting[Magma Mercoxit, 1]
		This.OreTypesRef:AddSetting[Mercoxit, 1]
		This.OreTypesRef:AddSetting[Prime Arkonor, 1]
		This.OreTypesRef:AddSetting[Crimson Arkonor, 1]
		This.OreTypesRef:AddSetting[Arkonor, 1]
		This.OreTypesRef:AddSetting[Monoclinic Bistot, 1]
		This.OreTypesRef:AddSetting[Triclinic Bistot, 1]
		This.OreTypesRef:AddSetting[Bistot, 1]
		This.OreTypesRef:AddSetting[Crystalline Crokite, 1]
		This.OreTypesRef:AddSetting[Sharp Crokite, 1]
		This.OreTypesRef:AddSetting[Crokite, 1]
		This.OreTypesRef:AddSetting[Gleaming Spodumain, 1]
		This.OreTypesRef:AddSetting[Bright Spodumain, 1]
		This.OreTypesRef:AddSetting[Spodumain, 1]
		This.OreTypesRef:AddSetting[Obsidian Ochre, 1]
		This.OreTypesRef:AddSetting[Onyx Ochre, 1]
		This.OreTypesRef:AddSetting[Dark Ochre, 1]
		This.OreTypesRef:AddSetting[Prismatic Gneiss, 1]
		This.OreTypesRef:AddSetting[Iridescent Gneiss, 1]
		This.OreTypesRef:AddSetting[Gneiss, 1]
		This.OreTypesRef:AddSetting[Glazed Hedbergite, 1]
		This.OreTypesRef:AddSetting[Vitric Hedbergite, 1]
		This.OreTypesRef:AddSetting[Hedbergite, 1]
		This.OreTypesRef:AddSetting[Radiant Hemorphite, 1]
		This.OreTypesRef:AddSetting[Vivid Hemorphite, 1]
		This.OreTypesRef:AddSetting[Hemorphite, 1]
		This.OreTypesRef:AddSetting[Pristine Jaspet, 1]
		This.OreTypesRef:AddSetting[Pure Jaspet, 1]
		This.OreTypesRef:AddSetting[Jaspet, 1]
		This.OreTypesRef:AddSetting[Fiery Kernite, 1]
		This.OreTypesRef:AddSetting[Luminous Kernite, 1]
		This.OreTypesRef:AddSetting[Kernite, 1]
		This.OreTypesRef:AddSetting[Golden Omber, 1]
		This.OreTypesRef:AddSetting[Silvery Omber, 1]
		This.OreTypesRef:AddSetting[Omber, 1]
		This.OreTypesRef:AddSetting[Rich Plagioclase, 1]
		This.OreTypesRef:AddSetting[Azure Plagioclase, 1]
		This.OreTypesRef:AddSetting[Plagioclase, 1]
		This.OreTypesRef:AddSetting[Viscous Pyroxeres, 1]
		This.OreTypesRef:AddSetting[Solid Pyroxeres, 1]
		This.OreTypesRef:AddSetting[Pyroxeres, 1]
		This.OreTypesRef:AddSetting[Massive Scordite, 1]
		This.OreTypesRef:AddSetting[Condensed Scordite, 1]
		This.OreTypesRef:AddSetting[Scordite, 1]
		This.OreTypesRef:AddSetting[Dense Veldspar, 1]
		This.OreTypesRef:AddSetting[Concentrated Veldspar, 1]
		This.OreTypesRef:AddSetting[Veldspar, 1]

		This.CommonRef:AddSet[ICE_Types]
		This.IceTypesRef:AddSetting[Dark Glitter, 1]
		This.IceTypesRef:AddSetting[Gelidus, 1]
		This.IceTypesRef:AddSetting[Glare Crust, 1]
		This.IceTypesRef:AddSetting[Krystallos, 1]
		This.IceTypesRef:AddSetting[Clear Icicle, 1]
		This.IceTypesRef:AddSetting[Smooth Glacial Mass, 1]
		This.IceTypesRef:AddSetting[Glacial Mass, 1]
		This.IceTypesRef:AddSetting[Pristine White Glaze, 1]
		This.IceTypesRef:AddSetting[White Glaze, 1]
		This.IceTypesRef:AddSetting[Thick Blue Ice, 1]
		This.IceTypesRef:AddSetting[Enriched Clear Icicle, 1]
		This.IceTypesRef:AddSetting[Blue Ice, 1]
		
		This.CommonRef:AddSetting[Miner_Dropoff_Type,Personal Hangar]
		This.CommonRef:AddSetting[BeltPrefix,Belt:]
		This.CommonRef:AddSetting[IceBeltPrefix,Ice Belt:]
		This.CommonRef:AddSetting[GasPrefix,Gas:]
		This.CommonRef:AddSetting[MaxLasers,3]
		This.CommonRef:AddSetting[MiningSystem,""]
		This.CommonRef:AddSetting[Dropoff,""]
		
	}
	
	Setting(string, MiningSystem, SetMiningSystem)	
	Setting(string, Dropoff, SetDropoff)	
	Setting(string, Dropoff_Type, SetDropoff_Type)	
	Setting(string, Dropoff_SubType, SetDropoff_SubType)
	Setting(string, Container_Name, SetContainer_Name)	
	Setting(bool, IceMining, SetIceMining)	
	Setting(bool, GasHarvesting, SetGasHarvesting)
	Setting(bool, OrcaMode, SetOrcaMode)	
	Setting(bool, UseBookmarks, SetUseBookmarks)	
	Setting(string, BeltPrefix, SetBeltPrefix)	
	Setting(string, IceBeltPrefix, SetIceBeltPrefix)	
	Setting(string, GasPrefix, SetGasPrefix)	
	Setting(int, Threshold, SetThreshold)	
	Setting(int, MaxLaserLocks, SetMaxLaserLocks)
	Setting(string, JetcanPrefix, SetJetcanPrefix)

}

objectdef obj_Miner inherits obj_State
{
	variable obj_Configuration_Miner Config
	variable obj_MinerUI LocalUI
	
	variable obj_TargetList Asteroids
	variable bool WarpToOrca=FALSE

	method Initialize()
	{
		This[parent]:Initialize
		LavishScript:RegisterEvent[ComBot_Orca_InBelt]
		Event[ComBot_Orca_InBelt]:AttachAtom[This:OrcaInBelt]
		PulseFrequency:Set[500]
		Asteroids.LockOutOfRange:Set[FALSE]
		Asteroids:SetIPCExclusion["MiningTargets"]
		Asteroids.ForceLockExclusion:Set[TRUE]
		DynamicAddBehavior("Miner", "Miner")
	}

	method Shutdown()
	{
		Event[ComBot_Orca_InBelt]:DetachAtom[This:OrcaInBelt]
	}	
	
	method Start()
	{
		This:PopulateTargetList
		Drones:RemainDocked
		Drones:Defensive
		UI:Update["obj_Miner", "Started", "g"]
		This:AssignStateQueueDisplay[DebugStateList@Debug@ComBotTab@ComBot]
		if ${This.IsIdle}
		{
			This:QueueState["OpenCargoHold"]
			This:QueueState["Mine"]
		}
	}
	
	method Stop()
	{
		This:DeactivateStateQueueDisplay
		Asteroids:ClearExclusions
		This:Clear
	}
	
	method PopulateTargetList()
	{
		Asteroids:ClearQueryString

		if !${Config.GasHarvesting}
		{
			variable iterator OreTypeIterator
			if ${Config.IceMining}
			{
				Config.IceTypesRef:GetSettingIterator[OreTypeIterator]
			}
			else
			{
				Config.OreTypesRef:GetSettingIterator[OreTypeIterator]
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
		else
		{
			Asteroids:AddQueryString[GroupID==GROUP_HARVESTABLECLOUD]
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
		Profiling:StartTrack["Miner_CheckCargohold"]
		switch ${Config.Dropoff_Type}
		{
			case Orca
				if !${Client.InSpace}
				{
					This:QueueState["Undock"]
					This:QueueState["Mine"]
					return TRUE
				}
				if !${Entity[Name = "${Config.Container_Name}"](exists)} && ${Local[${Config.Container_Name}].ToFleetMember(exists)} && ${This.WarpToOrca}
				{
					if ${Drones.DronesInSpace}
					{
						Drones:Recall
						return FALSE
					}
					UI:Update["obj_Miner", "Warping to ${Local[${Config.Container_Name}].ToFleetMember.ToPilot.Name}", "g", TRUE]
					UI:Log["Redacted:  obj_Miner - Warping to XXXXXXX (FleetMember)"]
					Local[${Config.Container_Name}].ToFleetMember:WarpTo
					Asteroids:ClearExclusions
					Client:Wait[5000]
					This:Clear
					Asteroids.LockedTargetList:Clear
					This:QueueState["Traveling", 1000]
					This:QueueState["Mine"]
				}
				if !${This.WarpToOrca}
				{
					This:Clear
					This:QueueState["Mine"]
				}
				break
			case Container
				if  ${MyShip.HasOreHold}
				{
					if ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipOreHold]} / ${EVEWindow[ByName, Inventory].ChildCapacity[ShipOreHold]} < ${Config.Threshold} * .01
					{
						break
					}
				}
				else
				{
					if ${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity} < ${Config.Threshold} * .01
					{
						break
					}
				}
				
				if ${Drones.DronesInSpace}
				{
					Drones:Recall
					This:InsertState["CheckCargoHold"]
					This:InsertState["Idle", 5000]
					return TRUE
				}
				UI:Update["obj_Miner", "Unload trip required", "g"]
				if ${Config.OrcaMode}
				{
					relay all -event ComBot_Orca_InBelt FALSE
				}
				Move:SaveSpot
				This:Clear
				Asteroids.LockedTargetList:Clear
				Asteroids:ClearExclusions
				Move:Bookmark[${Config.Dropoff}]
				This:QueueState["Traveling", 1000]
				This:QueueState["Mine"]
					
				break
			case No Dropoff
				break
			case Jetcan
				break		
			default
				if  ${MyShip.HasOreHold}
				{
					if ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipOreHold]} / ${EVEWindow[ByName, Inventory].ChildCapacity[ShipOreHold]} < ${Config.Threshold} * .01
					{
						break
					}
				}
				else
				{
					if ${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity} < ${Config.Threshold} * .01
					{
						break
					}
				}

				if ${Drones.DronesInSpace}
				{
					Drones:Recall
					This:InsertState["CheckCargoHold"]
					This:InsertState["Idle", 5000]
					return TRUE
				}
				UI:Update["obj_Miner", "Unload trip required", "g"]
				if ${Client.InSpace}
				{
					Move:SaveSpot
				}
				if ${Config.OrcaMode}
				{
					relay all -event ComBot_Orca_InBelt FALSE
				}
				This:Clear
				Asteroids.LockedTargetList:Clear
				Asteroids:ClearExclusions
				Move:Bookmark[${Config.Dropoff}]
				This:QueueState["Traveling", 1000]
				This:QueueState["PrepOffload", 1000]
				This:QueueState["Offload", 1000]
				This:QueueState["StackItemHangar", 1000]
				This:QueueState["GoToMiningSystem", 1000]
				This:QueueState["Traveling", 1000]
				This:QueueState["Mine"]
		}
		Profiling:EndTrack
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
			UI:Update["obj_Miner", "Opening inventory", "g"]
			MyShip:OpenCargo[]
			return FALSE
		}
		switch ${Config.Dropoff_Type}
		{
			case Corporation Folder
				if !${EVEWindow[ByName, Inventory].ChildWindowExists[Corporation Hangars]}
				{
					UI:Update["obj_Miner", "Delivery Location: Corporate Hangars child not found", "r"]
					UI:Update["obj_Miner", "Closing inventory to fix possible EVE bug", "y"]
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
		Profiling:StartTrack["Miner_Offload"]
		UI:Update["obj_Miner", "Unloading cargo", "g"]
		if ${MyShip.HasOreHold}
		{
			Cargo:PopulateCargoList[SHIPOREHOLD]
		}
		else
		{
			Cargo:PopulateCargoList[SHIP]
			Cargo:Filter["CategoryID == CATEGORYID_ORE", FALSE]
		}
		switch ${Config.Dropoff_Type}
		{
			case Personal Hangar
				Cargo:MoveCargoList[HANGAR]
				break
			case Corporation Folder
				Cargo:MoveCargoList[CORPORATEHANGAR, ${Config.Dropoff_SubType}]
				break
		}
		Profiling:EndTrack
		if ${Config.OrcaMode}
		{
			This:InsertState["OffloadOrca"]
		}
		return TRUE
	}
	member:bool OffloadOrca()
	{
		Profiling:StartTrack["Miner_OffloadOrca"]
		Cargo:PopulateCargoList[SHIP]
		Cargo:Filter["CategoryID == CATEGORYID_ORE", FALSE]
		if !${Cargo.CargoList.Used}
		{
			Cargo:PopulateCargoList[SHIPCORPORATEHANGAR]
			Cargo:Filter["CategoryID == CATEGORYID_ORE", FALSE]
		}
		switch ${Config.Dropoff_Type}
		{
			case Personal Hangar
				Cargo:MoveCargoList[HANGAR]
				break
			case Corporation Folder
				Cargo:MoveCargoList[CORPORATEHANGAR, ${Config.Dropoff_SubType}]
				break
		}
		Cargo:PopulateCargoList[SHIPCORPORATEHANGAR]
		Cargo:Filter["CategoryID == CATEGORYID_ORE", FALSE]
		Profiling:EndTrack

		if ${Cargo.CargoList.Used}
		{
			return FALSE
		}
		else
		{
			return TRUE
		}
	}	
	
	member:bool StackItemHangar()
	{
		Profiling:StartTrack["Miner_StackItemHanger"]
		variable int64 Orca
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["obj_Miner", "Making sure inventory is open", "g"]
			MyShip:Open
			Profiling:EndTrack
			return FALSE
		}

		;UI:Update["obj_Miner", "Stacking dropoff container", "g"]
		switch ${Config.Dropoff_Type}
		{
			case Personal Hangar
				EVE:StackItems[MyStationHangar, Hangar]
				break
			case Orca
				if ${Entity[Name = "${Config.Container_Name}"](exists)}
				{
					EVE:StackItems[${Entity[Name = "${Config.Container_Name}"].ID}, CorpHangars]
				}
				break
			case Container
				if ${Entity[Name = "${Config.Container_Name}"](exists)}
				{
					EVE:StackItems[${Entity[Name = "${Config.Container_Name}"].ID}, CorpHangars]
				}
				break
			case Corporation Folder
				EVE:StackItems[MyStationCorporateHangar, StationCorporateHangar, "${Config.Dropoff_SubType.Escape}"]
				break
			default
				break
		}
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool GoToMiningSystem()
	{
		if !${EVE.Bookmark[${Config.MiningSystem}](exists)}
		{
			UI:Update["obj_Miner", "No mining system defined!  Check your settings", "r"]
		}
		if ${EVE.Bookmark[${Config.MiningSystem}].SolarSystemID} != ${Me.SolarSystemID}
		{
			Move:System[${EVE.Bookmark[${Config.MiningSystem}].SolarSystemID}]
		}
		return TRUE
	}
	
	member:bool RemoveSavedSpot()
	{
		Move:RemoveSavedSpot
		return TRUE
	}

	member:bool MoveToBelt()
	{
		if ${Move.SavedSpotExists}
		{
			Move:GotoSavedSpot
			return TRUE
		}

		variable index:bookmark BookmarkIndex
		variable int RandomBelt
		variable string Label
		variable string prefix
		EVE:GetBookmarks[BookmarkIndex]
		
		
		if ${Config.GasHarvesting}
		{
			while ${BookmarkIndex.Used} > 0
			{
				RandomBelt:Set[${Math.Rand[${BookmarkIndex.Used}]:Inc[1]}]

				prefix:Set[${Config.GasPrefix}]

				Label:Set[${BookmarkIndex[${RandomBelt}].Label}]

				if (${BookmarkIndex[${RandomBelt}].SolarSystemID} != ${Me.SolarSystemID} || \
					${Label.Left[${prefix.Length}].NotEqual[${prefix}]})
				{
					BookmarkIndex:Remove[${RandomBelt}]
					BookmarkIndex:Collapse
					continue
				}

				Move:Bookmark[${BookmarkIndex[${RandomBelt}].Label}]

				return TRUE
			}
			return TRUE
		}
	
		if ${Config.UseBookmarks}
		{
			while ${BookmarkIndex.Used} > 0
			{
				RandomBelt:Set[${Math.Rand[${BookmarkIndex.Used}]:Inc[1]}]

				if ${Config.IceMining}
				{
					prefix:Set[${Config.IceBeltPrefix}]
				}
				else
				{
					prefix:Set[${Config.BeltPrefix}]
				}

				Label:Set[${BookmarkIndex[${RandomBelt}].Label}]

				if (${BookmarkIndex[${RandomBelt}].SolarSystemID} != ${Me.SolarSystemID} || \
					${Label.Left[${prefix.Length}].NotEqual[${prefix}]})
				{
					BookmarkIndex:Remove[${RandomBelt}]
					BookmarkIndex:Collapse
					continue
				}

				Move:Bookmark[${BookmarkIndex[${RandomBelt}].Label}]

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
			if ${Config.IceMining}
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

	member:bool Undock()
	{
		Move:Undock
		return TRUE
	}
	
	member:bool Mine()
	{
		variable iterator Roid
		
		Profiling:StartTrack["Miner_Mine"]
		if ${Me.ToEntity.Mode} == 3
		{
			Profiling:EndTrack
			return FALSE
		}
		
		This:Clear
		This:QueueState["OpenCargoHold", 10]

		if !${Client.InSpace}
		{
			This:QueueState["CheckCargoHold", 1000]
			This:QueueState["Undock"]
			This:QueueState["Mine"]
			Profiling:EndTrack
			return TRUE
		}
		
		variable int MaxTarget = ${MyShip.MaxLockedTargets}
		if ${Me.MaxLockedTargets} < ${MaxTarget}
		{
			MaxTarget:Set[${Math.Calc[${Me.MaxLockedTargets}]}]
		}
		if ${Config.MaxLaserLocks} < ${MaxTarget}
		{
			MaxTarget:Set[${Config.MaxLaserLocks}]
		}
		if ${Ship.ModuleList_MiningLaser.Count} < ${MaxTarget}
		{
			MaxTarget:Set[${Ship.ModuleList_MiningLaser.Count}]
		}
		if ${Config.IceMining} || ${Config.GasHarvesting}
		{
			MaxTarget:Set[1]
		}
		
		
		Asteroids.MinLockCount:Set[${MaxTarget}]
		Asteroids.MaxRange:Set[${Ship.ModuleList_MiningLaser.Range}]
		
		if ${Config.OrcaMode}
		{
			Asteroids.AutoLock:Set[FALSE]
			Asteroids.AutoRelock:Set[FALSE]
			Asteroids.AutoRelockPriority:Set[FALSE]
			
			
			Cargo:PopulateCargoList[SHIPCORPORATEHANGAR]
			Cargo:Filter["CategoryID == CATEGORYID_ORE", FALSE]
			
			if ${Config.Dropoff_Type.Equal[No Dropoff]}
			{
			}
			elseif ${Cargo.CargoList.Used}
			{
				Cargo:MoveCargoList[SHIPOREHOLD]
				Cargo:PopulateCargoList[SHIPCORPORATEHANGAR]
				Cargo:Filter["CategoryID == CATEGORYID_ORE", FALSE]
				Cargo:MoveCargoList[SHIP]
				This:QueueState["StackOreHold", 1000]
				This:QueueState["StackCargoHold", 1000]
				This:QueueState["CheckCargoHold", 1000]
				This:QueueState["Idle", 1000]
				This:QueueState["Mine"]
				Profiling:EndTrack
				return TRUE
			}
		}
		
		if ${Config.Dropoff_Type.Equal[Orca]} || ${Config.Dropoff_Type.Equal[Container]}
		{
			variable int64 Orca
			if ${Entity[Name = "${Config.Container_Name}"](exists)}
			{
				Orca:Set[${Entity[Name = "${Config.Container_Name}"].ID}]
				Asteroids.DistanceTarget:Set[${Orca}]
				if ${Entity[${Orca}].Distance} > LOOT_RANGE
				{
					Move:Approach[${Orca}, LOOT_RANGE]
					Profiling:EndTrack
					This:Clear
					This:QueueState["Mine"]
					return FALSE
				}
				else
				{
					if  ${MyShip.HasOreHold}
					{
						if ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipOreHold]} / ${EVEWindow[ByName, Inventory].ChildCapacity[ShipOreHold]} >= ${Config.Threshold} * .01
						{
							if !${EVEWindow[ByName, Inventory].ChildWindowExists[${Orca}]}
							{
								UI:Update["obj_Miner", "Opening ${Config.Container_Name}", "g"]
								Entity[${Orca}]:Open
								Profiling:EndTrack
								This:Clear
								This:QueueState["Mine"]
								return FALSE
							}
							if !${EVEWindow[ByItemID, ${Orca}](exists)}
							{
								EVEWindow[ByName, Inventory]:MakeChildActive[${Orca}]
								Profiling:EndTrack
								This:Clear
								This:QueueState["Mine"]
								return FALSE
							}
							;UI:Update["obj_Miner", "Unloading to ${Config.Container_Name}", "g"]
							Cargo:PopulateCargoList[SHIPOREHOLD]
							Cargo:MoveCargoList[SHIPCORPORATEHANGAR, "", ${Orca}]
							This:QueueState["Idle", 1000]
							This:QueueState["StackItemHangar"]
							This:QueueState["Mine"]
							Profiling:EndTrack
							return TRUE
						}
					}
					else
					{
						if ${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity} >= ${Config.Threshold} * .01
						{
							if !${EVEWindow[ByName, Inventory].ChildWindowExists[${Orca}]}
							{
								UI:Update["obj_Miner", "Opening ${Config.Container_Name}", "g"]
								Entity[${Orca}]:Open
								Profiling:EndTrack
								This:Clear
								This:QueueState["Mine"]
								return FALSE
							}
							if !${EVEWindow[ByItemID, ${Orca}](exists)}
							{
								EVEWindow[ByName, Inventory]:MakeChildActive[${Orca}]
								Profiling:EndTrack
								This:Clear
								This:QueueState["Mine"]
								return FALSE
							}
							;UI:Update["obj_Miner", "Unloading to ${Config.Container_Name}", "g"]
							Cargo:PopulateCargoList[SHIP]
							Cargo:Filter["CategoryID == CATEGORYID_ORE", FALSE]
							Cargo:MoveCargoList[SHIPCORPORATEHANGAR, "", ${Orca}]
							This:QueueState["Idle", 1000]
							This:QueueState["StackItemHangar"]
							This:QueueState["Mine"]
							Profiling:EndTrack
							return TRUE
						}
					}
				}
			}
			else
			{
				Asteroids.DistanceTarget:Set[${MyShip.ID}]
			}
		}
		
		if !${Config.Dropoff_Type.Equal[Orca]}
		{
			Asteroids.DistanceTarget:Set[${MyShip.ID}]
		}
		
		if !${Config.OrcaMode}
		{
			Asteroids.AutoLock:Set[TRUE]
			Asteroids.AutoRelock:Set[TRUE]
			Asteroids.AutoRelockPriority:Set[TRUE]
		}

		
		if ${Config.Dropoff_Type.Equal[Jetcan]}
		{
			Jetcan:Enable
		}
		else
		{
			Jetcan:Disable
		}

		if !${Entity[CategoryID==CATEGORYID_ORE]} && !${Entity[GroupID==GROUP_HARVESTABLECLOUD]}
		{
			if ${Config.OrcaMode}
			{
				relay all -event ComBot_Orca_InBelt FALSE
			}
			Drones:Recall
			UI:Update["obj_Miner", "No asteroids found, moving to a new belt", "g"]
			This:QueueState["CheckCargoHold", 1000]
			This:QueueState["GoToMiningSystem", 1000]
			This:QueueState["Traveling", 1000]
			This:QueueState["MoveToBelt", 1000]
			This:QueueState["Traveling", 1000]
			This:QueueState["RemoveSavedSpot", 1000]
			This:QueueState["Mine"]
			Profiling:EndTrack
			return TRUE
		}

		if ${Config.OrcaMode}
		{
			relay all -event ComBot_Orca_InBelt TRUE
			relay all -event ComBot_Orca_Cargo ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]}
			Asteroids:RequestUpdate
			Asteroids.TargetList:GetIterator[Roid]
			
			if ${Roid:First(exists)}
			{
				if ${Config.IceMining}
				{
					Move:Approach[${Roid.Value.ID}, 10000]
				}
				else
				{
					Move:Approach[${Roid.Value.ID}, 8000]
				}
			}
			else
			{
				This:Clear
				This:QueueState["Mine"]
				return FALSE
			}
		}
		else
		{
			Asteroids:RequestUpdate
			Asteroids.TargetList:GetIterator[Roid]
			if ${Roid:First(exists)}
			{
				if ${Roid.Value.Distance} > ${Math.Calc[${Ship.ModuleList_MiningLaser.Range} * (3/4)]}
				{
					Move:Approach[${Roid.Value.ID}, ${Math.Calc[${Ship.ModuleList_MiningLaser.Range} * (1/2)]}]
				}
			}
			else
			{
				This:Clear
				This:QueueState["Mine"]
				return FALSE
			}
		}
		
		if ${Ship.ModuleList_MiningLaser.ActiveCount} < ${Ship.ModuleList_MiningLaser.Count}
		{
			This:QueueState["ActivateLasers", 2000]
			This:QueueState["Mine"]
			Profiling:EndTrack
			return TRUE
		}
		
		if !${Config.Dropoff_Type.Equal[No Dropoff]}
		{
			This:QueueState["CheckCargoHold"]
			This:QueueState["Mine"]
			Profiling:EndTrack
			return TRUE
		}
		Profiling:EndTrack
		This:Clear
		This:QueueState["Mine"]
		return FALSE
	}


	member:bool ActivateLasers()
	{
		Profiling:StartTrack["Miner_ActivateLasers"]
		if  ${Ship.ModuleList_MiningLaser.ActiveCount} == ${Ship.ModuleList_MiningLaser.Count}
		{
			Profiling:EndTrack
			return TRUE
		}
		Asteroids:RequestUpdate
		
		
		
		variable iterator Roid
		Asteroids.LockedTargetList:GetIterator[Roid]
		
		variable float LaserSplitCount = ${Math.Calc[${Ship.ModuleList_MiningLaser.Count} / ${Asteroids.MinLockCount}]}
		variable int LaserRoidSplitCount = ${Math.Calc[${Ship.ModuleList_MiningLaser.Count} % ${Asteroids.MinLockCount}]}
		variable int LaserCount = ${LaserSplitCount.Ceil}
		variable int LaserRoidCount = 0
		
		
		if ${Roid:First(exists)}
		{
			do
			{
				if ${Roid.Value.ID(exists)}
				{
					LaserRoidCount:Inc
					if ${LaserRoidCount} > ${LaserRoidSplitCount}
					{
						LaserCount:Set[${LaserSplitCount.Int}]
					}
					if ${Roid.Value.Distance} > ${Ship.ModuleList_MiningLaser.Range}
					{
						continue
					}
					if ${Config.IceMining}
					{
						UI:Update["obj_Miner", "Activating ${Ship.ModuleList_MiningLaser.InactiveCount} laser(s) on ${Roid.Value.Name} (${ComBot.MetersToKM_Str[${Roid.Value.Distance}]})", "y"]
						Ship.ModuleList_MiningLaser:ActivateCount[${Ship.ModuleList_MiningLaser.InactiveCount}, ${Roid.Value.ID}]
						Profiling:EndTrack
						return TRUE
					}
					elseif ${Config.GasHarvesting}
					{
						variable int MoreLasers=${Math.Calc[${Me.Skill[Gas Cloud Harvesting].Level} - ${Ship.ModuleList_MiningLaser.ActiveCount}]}
						UI:Update["obj_Miner", "Activating ${MoreLasers} harvester(s) on ${Roid.Value.Name} (${ComBot.MetersToKM_Str[${Roid.Value.Distance}]})", "y"]
						Ship.ModuleList_MiningLaser:ActivateCount[${MoreLasers}, ${Roid.Value.ID}]
						Profiling:EndTrack
						return TRUE
					}
					else
					{
						if ${Ship.ModuleList_MiningLaser.ActiveCountOn[${Roid.Value.ID}]} < ${LaserCount}
						{
							UI:Update["obj_Miner", "Activating 1 laser on ${Roid.Value.Name} (${ComBot.MetersToKM_Str[${Roid.Value.Distance}]})", "y"]
							Ship.ModuleList_MiningLaser:Activate[${Roid.Value.ID}]
							Profiling:EndTrack
							return FALSE
						}
					}
				}
			}
			while ${Roid:Next(exists)}
		}
		
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool ExpandContainer()
	{
		variable int64 Orca
		if ${Entity[Name = "${Config.Container_Name}"](exists)}
		{
			Orca:Set[${Entity[Name = "${Config.Container_Name}"].ID}]
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
	
	member:bool StackOreHold()
	{
		EVE:StackItems[MyShip,OreHold]
		return TRUE
	}
	member:bool StackCargoHold()
	{
		EVE:StackItems[MyShip,CargoHold]
		return TRUE
	}
	
}	






objectdef obj_MinerUI inherits obj_State
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
			This:QueueState["OpenCargoHold"]
			This:QueueState["UpdateBookmarkLists", 5]
		}
	}
	
	method Stop()
	{
		This:Clear
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
	
	member:bool UpdateBookmarkLists()
	{
		variable index:bookmark Bookmarks
		variable iterator BookmarkIterator

		EVE:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		
		UIElement[MiningSystemList@MiningFrame@Miner_Frame@ComBot_Miner]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[MiningSystem@MiningFrame@Miner_Frame@ComBot_Miner].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Miner.Config.MiningSystem.Length}].Equal[${Miner.Config.MiningSystem}]}
						UIElement[MiningSystemList@MiningFrame@Miner_Frame@ComBot_Miner]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[MiningSystemList@MiningFrame@Miner_Frame@ComBot_Miner]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}

		UIElement[DropoffList@DropoffFrame@Miner_Frame@ComBot_Miner]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[Dropoff@DropoffFrame@Miner_Frame@ComBot_Miner].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Miner.Config.Dropoff.Length}].Equal[${Miner.Config.Dropoff}]}
						UIElement[DropoffList@DropoffFrame@Miner_Frame@ComBot_Miner]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[DropoffList@DropoffFrame@Miner_Frame@ComBot_Miner]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}
			
		return FALSE
	}

}
