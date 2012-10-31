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
		This.CommonRef:AddSetting[TetherName,""]
		
		This.CommonRef:AddSetting[DontMove,FALSE]
		
	}
	
	Setting(string, MiningSystem, SetMiningSystem)	
	Setting(string, Dropoff, SetDropoff)	
	Setting(string, Dropoff_Type, SetDropoff_Type)	
	Setting(string, Dropoff_SubType, SetDropoff_SubType)
	Setting(string, Container_Name, SetContainer_Name)	
	Setting(bool, IceMining, SetIceMining)	
	Setting(bool, GasHarvesting, SetGasHarvesting)
	Setting(bool, OrcaMode, SetOrcaMode)	
	Setting(bool, Tether, SetTether)	
	Setting(bool, ApproachPriority, SetApproachPriority)
	Setting(string, TetherName, SetTetherName)	
	Setting(bool, UseBookmarks, SetUseBookmarks)	
	Setting(string, BeltPrefix, SetBeltPrefix)	
	Setting(string, IceBeltPrefix, SetIceBeltPrefix)	
	Setting(string, GasPrefix, SetGasPrefix)	
	Setting(int, Threshold, SetThreshold)	
	Setting(int, MaxLaserLocks, SetMaxLaserLocks)
	Setting(string, JetcanPrefix, SetJetcanPrefix)
	
	Setting(bool, DontMove, SetDontMove)

}

objectdef obj_Miner inherits obj_State
{
	variable obj_Configuration_Miner Config
	variable obj_MinerUI LocalUI
	
	variable obj_TargetList Asteroids
	variable bool WarpToOrca=FALSE
	variable index:bookmark BookmarkIndex
	variable index:entity Belts

	method Initialize()
	{
		This[parent]:Initialize
		LavishScript:RegisterEvent[ComBot_Orca_InBelt]
		Event[ComBot_Orca_InBelt]:AttachAtom[This:OrcaInBelt]
		PulseFrequency:Set[500]
		Asteroids.LockOutOfRange:Set[FALSE]
		Asteroids.MaxRange:Set[${Ship.ModuleList_MiningLaser.Range}]
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
			if ${Client.InSpace}
			{
				This:QueueState["RequestUpdate"]
				This:QueueState["Updated"]
			}
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold"]
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
		Profiling:StartTrack["Miner: CheckCargoHold"]
		if 	${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipOreHold]} / ${EVEWindow[ByName, Inventory].ChildCapacity[ShipOreHold]} >= ${Config.Threshold} * .01 && \
			${MyShip.HasOreHold} && \
			!${Config.Dropoff_Type.Equal[No Dropoff]} && \
			!${Config.Dropoff_Type.Equal[Jetcan]} && \
			!${Config.OrcaMode}
		{
			UI:Update["obj_Miner", "Unload trip required", "g"]
			This:QueueState["PrepareWarp"]
			This:QueueState["Dropoff"]
			This:QueueState["Traveling"]
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold"]
			Profiling:EndTrack
			return TRUE
		}
		elseif ${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity} >= ${Config.Threshold} * .01 && \
			!${MyShip.HasOreHold} && \
			!${Config.Dropoff_Type.Equal[No Dropoff]} && \
			!${Config.Dropoff_Type.Equal[Jetcan]} && \
			!${Config.OrcaMode}
		{
			UI:Update["obj_Miner", "Unload trip required", "g"]
			This:QueueState["PrepareWarp"]
			This:QueueState["Dropoff"]
			This:QueueState["Traveling"]
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold"]
			Profiling:EndTrack
			return TRUE
		}
		elseif ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]} / ${EVEWindow[ByName, Inventory].ChildCapacity[ShipCorpHangar]} >= ${Config.Threshold} * .01 && \
			!${Config.Dropoff_Type.Equal[No Dropoff]} && \
			!${Config.Dropoff_Type.Equal[Jetcan]} && \
			${Config.OrcaMode}
		{
			UI:Update["obj_Miner", "Unload trip required", "g"]
			This:QueueState["PrepareWarp"]
			This:QueueState["Dropoff"]
			This:QueueState["Traveling"]
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold"]
			Profiling:EndTrack
			return TRUE
		}
		else
		{
			This:QueueState["GoToMiningSystem"]
			This:QueueState["Traveling"]
			This:QueueState["Undock"]
			This:QueueState["WaitForSpace"]
;			This:QueueState["RequestUpdate"]
;			This:QueueState["Updated"]
			This:QueueState["CheckForWork"]
			Profiling:EndTrack
			return TRUE
		}
	}
	
	member:bool PrepareWarp()
	{
		Profiling:StartTrack["Miner: PrepareWarp"]
		if ${Drones.DronesInSpace}
		{
			Drones:Recall
			This:InsertState["PrepareWarp"]
			This:InsertState["Idle", 5000]
			Profiling:EndTrack
			return TRUE
		}
		if ${Config.OrcaMode}
		{
			relay all -event ComBot_Orca_InBelt FALSE
		}
		if ${Asteroids.TargetList.Used} && !${Config.Dropoff_Type.Equal[Orca]} && !${Config.Tether}
		{
			Move:SaveSpot
		}
		Asteroids:ClearExclusions
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool Dropoff()
	{
		Profiling:StartTrack["Miner: Dropoff"]
		variable string Dropoff_Type=${Config.Dropoff_Type}
		variable string Bookmark=${Config.Dropoff}
		if ${Dropoff_Type.Equal[Orca]}
		{
			echo OrcaWarp - ${This.WarpToOrca}
			if ${This.WarpToOrca}
			{
				Dropoff_Type:Set[Container]
				Bookmark:Set[${Config.MiningSystem}]
			}
			else
			{
				Profiling:EndTrack
				return TRUE
			}
		}
		if ${MyShip.HasOreHold}
		{
			Cargo:At[${Bookmark},${Config.Dropoff_Type},${Config.Dropoff_SubType}, ${Config.Container_Name}]:Unload["", 0, OreHold]
		}
		if ${Config.OrcaMode}
		{
			Cargo:At[${Bookmark},${Config.Dropoff_Type},${Config.Dropoff_SubType}, ${Config.Container_Name}]:Unload["", 0, ShipCorpHangar]
		}
		Cargo:At[${Bookmark},${Config.Dropoff_Type},${Config.Dropoff_SubType}, ${Config.Container_Name}]:Unload["", 0, Ship]
		Profiling:EndTrack
		return TRUE
	}
		
	
	member:bool Traveling()
	{
		Profiling:StartTrack["Miner: Traveling"]
		if ${Cargo.Processing} || ${Move.Traveling} || ${Me.ToEntity.Mode} == 3
		{
			Profiling:EndTrack
			return FALSE
		}
		Profiling:EndTrack
		return TRUE
	}
	
	
	member:bool GoToMiningSystem()
	{
		Profiling:StartTrack["Miner: GoToMiningSystem"]
		if !${EVE.Bookmark[${Config.MiningSystem}](exists)}
		{
			UI:Update["obj_Miner", "No mining system defined!  Check your settings", "r"]
		}
		if ${EVE.Bookmark[${Config.MiningSystem}].SolarSystemID} != ${Me.SolarSystemID}
		{
			Move:System[${EVE.Bookmark[${Config.MiningSystem}].SolarSystemID}]
		}
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool Undock()
	{
		Profiling:StartTrack["Miner: Undock"]
		if !${Client.InSpace}
		{
			Move:Undock
		}
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool WaitForSpace()
	{
		return ${Client.InSpace}
	}
	
	member:bool RequestUpdate()
	{
		Profiling:StartTrack["Miner: RequestUpdate"]
		Asteroids:RequestUpdate
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool Updated()
	{
		return ${Asteroids.Updated}
	}
	
	member:bool CheckForWork()
	{
		Profiling:StartTrack["Miner: CheckForWork"]
		if !${Asteroids.TargetList.Used}
		{
			This:QueueState["MoveToBelt"]
;			This:QueueState["RequestUpdate"]
;			This:QueueState["Updated"]
			This:QueueState["CheckForWork"]
		}
		else
		{
			This:QueueState["Mine"]
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold"]
		}
		Profiling:EndTrack
		return TRUE
	}
	
	
	member:bool MoveToBelt()
	{
		Profiling:StartTrack["Miner: MoveToBelt"]
		if ${Config.Tether} && ${Local[${Config.TetherName}](exists)}
		{
			Move:Fleetmember[${Local[${Config.TetherName}].ID}]
			This:InsertState["Updated"]
			This:InsertState["RequestUpdate"]
			This:InsertState["Traveling"]
			Profiling:EndTrack
			return TRUE
		}
		
		if ${Move.SavedSpotExists}
		{
			Move:GotoSavedSpot
			This:InsertState["Updated"]
			This:InsertState["RequestUpdate"]
			This:InsertState["RemoveSavedSpot"]
			This:InsertState["Traveling", 2000]
			Profiling:EndTrack
			return TRUE
		}
		
		if ${Config.Dropoff_Type.Equal[Orca]} && ${This.WarpToOrca} && ${Local[${Config.Container_Name}](exists)}
		{
			Move:Fleetmember[${Local[${Config.Container_Name}].ID}]
			This:InsertState["Updated"]
			This:InsertState["RequestUpdate"]
			This:InsertState["Traveling"]
			Profiling:EndTrack
			return TRUE
		}
		
		if ${Config.UseBookmarks} || ${Config.GasHarvesting}
		{

			variable string prefix
			if ${Config.GasHarvesting}
			{
				prefix:Set[${Config.GasPrefix}]
			}
			elseif ${Config.IceMining}
			{
				prefix:Set[${Config.IceBeltPrefix}]
			}
			else
			{
				prefix:Set[${Config.BeltPrefix}]
			}
			
			if ${BookmarkIndex.Used} == 0
			{
				EVE:GetBookmarks[BookmarkIndex]
				BookmarkIndex:RemoveByQuery[${LavishScript.CreateQuery[SolarSystemID == ${Me.SolarSystemID}]}, FALSE]
				BookmarkIndex:RemoveByQuery[${LavishScript.CreateQuery[Label =- "${prefix}"]}, FALSE]
				BookmarkIndex:Collapse
				
			}
			else
			{
				if ${Config.GasHarvesting}
				{
					BookmarkIndex.Get[1]:Remove
					BookmarkIndex:Remove[1]
					BookmarkIndex:Collapse
				}
			}
		
			Move:Bookmark[${BookmarkIndex.Get[1].Label}]
			BookmarkIndex:Remove[1]
			BookmarkIndex:Collapse
			This:InsertState["Updated"]
			This:InsertState["RequestUpdate"]
			This:InsertState["Traveling"]
			Profiling:EndTrack
			return TRUE
		}
		else
		{
			variable string beltsubstring
		
			if !${Client.InSpace}
			{
				Move:Undock
				return FALSE
			}

			if ${Belts.Used} == 0
			{
				EVE:QueryEntities[Belts, "GroupID = GROUP_ASTEROIDBELT"]
				
				if ${Config.IceMining}
				{
					beltsubstring:Set["ICE FIELD"]
				}
				else
				{
					beltsubstring:Set["ASTEROID BELT"]
				}
				
				Belts:RemoveByQuery[${LavishScript.CreateQuery[Name =- "${beltsubstring}"]}, FALSE]
			}

			Move:Object[${Belts.Get[1].ID}]
			Belts:Remove[1]
			Belts:Collapse
			This:InsertState["Updated"]
			This:InsertState["RequestUpdate"]
			This:InsertState["Traveling"]
			Profiling:EndTrack
			return TRUE
		}
	}	
	
	member:bool RemoveSavedSpot()
	{
		Move:RemoveSavedSpot
		return TRUE
	}
	
	
	
	
	
	


	



	member:bool Mine()
	{
		Profiling:StartTrack["Miner: MoveToBelt"]
		
		if ${Me.ToEntity.Mode} == 3
		{
			Profiling:EndTrack
			return FALSE
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
		
		if ${Config.Dropoff_Type.Equal[Jetcan]}
		{
			Jetcan:Enable
		}
		else
		{
			Jetcan:Disable
		}
		
	
		variable int64 Orca
		if ${Config.Dropoff_Type.Equal[Orca]}
		{
			if ${Entity[Name = "${Config.Container_Name}"](exists)}
			{
				Orca:Set[${Entity[Name = "${Config.Container_Name}"].ID}]
				Asteroids.DistanceTarget:Set[${Orca}]
			}
			else
			{
				Asteroids.DistanceTarget:Set[${MyShip.ID}]
			}
		}
		elseif ${Config.Tether}
		{
			if ${Entity[Name = "${Config.TetherName}"](exists)}
			{
				Orca:Set[${Entity[Name = "${Config.TetherName}"].ID}]
				Asteroids.DistanceTarget:Set[${Orca}]
			}
			else
			{
				Asteroids.DistanceTarget:Set[${MyShip.ID}]
			}
		}
		else
		{
			Asteroids.DistanceTarget:Set[${MyShip.ID}]
		}
		
		
		
		variable index:entity Roids
		variable iterator Roid
		if ${Config.ApproachPriority}
		{
			Asteroids.TargetList:GetIterator[Roid]
		}
		else
		{
			EVE:QueryEntities[Roids, "GroupID==GROUP_HARVESTABLECLOUD || CategoryID==CATEGORYID_ORE"]
			Roids:GetIterator[Roid]
		}
		if ${Config.OrcaMode}
		{
			Asteroids.AutoLock:Set[FALSE]
			Asteroids.LockTop:Set[FALSE]
			
			relay all -event ComBot_Orca_InBelt TRUE
			relay all -event ComBot_Orca_Cargo ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipCorpHangar]}
			Cargo:PopulateCargoList[ShipCorpHangar]
			if ${Cargo.CargoList.Used} && !${Config.Dropoff_Type.Equal[No Dropoff]}
			{
				if ${EVEWindow[ByName, Inventory].ChildUsedCapacity[ShipOreHold]} / ${EVEWindow[ByName, Inventory].ChildCapacity[ShipOreHold]} < ${Config.Threshold} * .01
				{
					Cargo:Filter[CategoryID==CATEGORYID_ORE]
					Cargo:MoveCargoList[OreHold]
					return TRUE
				}
				elseif ${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity} < ${Config.Threshold} * .01
				{
					Cargo:Filter[GroupID==GROUP_HARVESTABLECLOUD || CategoryID==CATEGORYID_ORE]
					Cargo:MoveCargoList[Ship]
					return TRUE
				}
			}
			
			if !${Config.DontMove}
			{
				if ${Roid:First(exists)}
				{
					if ${Config.IceMining}
					{
						Move:Approach[${Roid.Value.ID}, 10000]
					}
					elseif ${Config.GasHarvesting}
					{
						Move:Approach[${Roid.Value.ID}, 1000]
					}
					else
					{
						Move:Approach[${Roid.Value.ID}, 8000]
					}
				}
			}
		}
		else
		{
			Asteroids.AutoLock:Set[TRUE]
			Asteroids.LockTop:Set[TRUE]
			
			if !${Config.DontMove}
			{
				if ${Roid:First(exists)}
				{
					if ${Roid.Value.Distance} > ${Math.Calc[${Ship.ModuleList_MiningLaser.Range} * (3/4)]}
					{
						Move:Approach[${Roid.Value.ID}, ${Math.Calc[${Ship.ModuleList_MiningLaser.Range} * (1/2)]}]
					}
				}
			}
		}


		if ${Ship.ModuleList_MiningLaser.ActiveCount} < ${Ship.ModuleList_MiningLaser.Count}
		{
			This:InsertState["ActivateLasers", 2000]
			This:InsertState["Updated"]
			This:InsertState["RequestUpdate"]
		}
		
		Profiling:EndTrack
		return TRUE
	}


	member:bool ActivateLasers()
	{
		Profiling:StartTrack["Miner: ActivateLasers"]
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
						Move:Approach[${Roid.Value.ID}, ${Ship.ModuleList_MiningLaser.Range}]
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
	
	method OrcaInBelt(bool value)
	{
		WarpToOrca:Set[${value}]
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
		Profiling:StartTrack["Miner: UI"]

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
			
		Profiling:EndTrack
		return FALSE
	}

}
