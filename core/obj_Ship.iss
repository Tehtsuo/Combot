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

objectdef obj_Ship
{
	variable int NextPulse = ${Math.Calc[${LavishScript.RunningTime} + ${PulseIntervalInMilliseconds} + ${Math.Rand[500]}]}
	variable int PulseIntervalInMilliseconds = 2000
	

	variable int RetryUpdateModuleList=1
	
	variable index:module ModuleList
	variable obj_ModuleList ModuleList_ShieldTransporters
	variable obj_ModuleList ModuleList_MiningLaser
	variable obj_ModuleList ModuleList_Weapon
	variable obj_ModuleList ModuleList_ECCM
	variable obj_ModuleList ModuleList_ActiveResists
	variable obj_ModuleList ModuleList_Regen_Shield
	variable obj_ModuleList ModuleList_Repair_Armor
	variable obj_ModuleList ModuleList_Repair_Hull
	variable obj_ModuleList ModuleList_AB_MWD
	variable index:module ModuleList_Passive
	variable obj_ModuleList ModuleList_Salvagers
	variable obj_ModuleList ModuleList_TractorBeams
	variable obj_ModuleList ModuleList_Cloaks
	variable obj_ModuleList ModuleList_StasisWeb
	variable obj_ModuleList ModuleList_SensorBoost
	variable obj_ModuleList ModuleList_TargetPainter
	variable obj_ModuleList ModuleList_TrackingComputer
	variable obj_ModuleList ModuleList_GangLinks

	variable float Module_Salvagers_Range
	variable float Module_TractorBeams_Range
	variable float Module_MiningLaser_Range


	

	method Initialize()
	{
		Event[ISXEVE_onFrame]:AttachAtom[This:Pulse]
		UI:Update["obj_Ship", "Initialized", "g"]
	}

	method Shutdown()
	{
		Event[ISXEVE_onFrame]:DetachAtom[This:Pulse]
	}	

	method Pulse()
	{
	    if ${LavishScript.RunningTime} >= ${This.NextPulse}
		{
			if !${Me.InStation} && ${Client.InSpace}
			{
				if ${RetryUpdateModuleList} == 10
				{
					UI:Update["obj_Ship", "UpdateModuleList - No modules found. Pausing.", "r"]
					UI:Update["obj_Ship", "UpdateModuleList - If this ship has slots, you must have at least one module equipped, of any type.", "r"]
					RetryUpdateModuleList:Set[0]
					EVEBot:Pause
				}

				if ${RetryUpdateModuleList} > 0
				{
					This:UpdateModuleList
				}
			}
				
    		This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${PulseIntervalInMilliseconds} + ${Math.Rand[500]}]}]
		}
	}	
	
	
	method UpdateModuleList()
	{
		if !${Client.InSpace}
		{
			UI:Update["obj_Ship", "UpdateModuleList called while in station", "o"]
			RetryUpdateModuleList:Set[1]
			return
		}

		/* build module lists */
		This.ModuleList:Clear
		This.ModuleList_MiningLaser:Clear
		This.ModuleList_ECCM:Clear
		This.ModuleList_Weapon:Clear
		This.ModuleList_ActiveResists:Clear
		This.ModuleList_Regen_Shield:Clear
		This.ModuleList_Repair_Armor:Clear
		This.ModuleList_AB_MWD:Clear
		This.ModuleList_Passive:Clear
		This.ModuleList_Repair_Armor:Clear
		This.ModuleList_Repair_Hull:Clear
		This.ModuleList_Salvagers:Clear
		This.ModuleList_TractorBeams:Clear
		This.ModuleList_Cloaks:Clear
		This.ModuleList_StasisWeb:Clear
		This.ModuleList_SensorBoost:Clear
		This.ModuleList_TargetPainter:Clear
		This.ModuleList_TrackingComputer:Clear
		This.ModuleList_GangLinks:Clear
		This.ModuleList_ShieldTransporters:Clear

		Me.Ship:GetModules[This.ModuleList]

		if !${This.ModuleList.Used} && ${Me.Ship.HighSlots} > 0
		{
			UI:Update["obj_Ship", "UpdateModuleList - No modules found. Retrying in a few seconds", "o"]
			UI:Update["obj_Ship", "If this ship has slots, you must have at least one module equipped, of any type.", "o"]
			RetryUpdateModuleList:Inc
			return
		}
		RetryUpdateModuleList:Set[0]
		
		variable iterator ModuleIter
		
		This.ModuleList:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		do
		{
			variable int GroupID
			GroupID:Set[${ModuleIter.Value.ToItem.GroupID}]
			variable int TypeID
			TypeID:Set[${ModuleIter.Value.ToItem.TypeID}]
			
			if !${ModuleIter.Value(exists)}
			{
				UI:Update["obj_Ship", "UpdateModuleList - Null module found. Retrying in a few seconds.", "o"]
				RetryUpdateModuleList:Inc
				return
			}
			
			if !${ModuleIter.Value.IsActivatable}
			{
				This.ModuleList_Passive:Insert[${ModuleIter.Value.ID}]
				continue
			}
			
			if ${ModuleIter.Value.MiningAmount(exists)}
			{
				This.Module_MiningLaser_Range:Set[${ModuleIter.Value.OptimalRange}]
				This.ModuleList_MiningLaser:Insert[${ModuleIter.Value.ID}]
				continue
			}
			
			
			switch ${GroupID}
			{
				case GROUP_SHIELD_TRANSPORTER
					This.ModuleList_ShieldTransporters:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_DAMAGE_CONTROL
				case GROUP_SHIELD_HARDENER
				case GROUP_ARMOR_HARDENERS
					This.ModuleList_ActiveResists:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_ENERGYWEAPON
				case GROUP_PROJECTILEWEAPON
				case GROUP_HYBRIDWEAPON
				case GROUP_MISSILELAUNCHER
				case GROUP_MISSILELAUNCHERASSAULT
				case GROUP_MISSILELAUNCHERBOMB
				case GROUP_MISSILELAUNCHERCITADEL
				case GROUP_MISSILELAUNCHERCRUISE
				case GROUP_MISSILELAUNCHERDEFENDER
				case GROUP_MISSILELAUNCHERHEAVY
				case GROUP_MISSILELAUNCHERHEAVYASSAULT
				case GROUP_MISSILELAUNCHERROCKET
				case GROUP_MISSILELAUNCHERSIEGE
				case GROUP_MISSILELAUNCHERSNOWBALL
				case GROUP_MISSILELAUNCHERSTANDARD
					This.ModuleList_Weapon:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_ECCM
					This.ModuleList_ECCM:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_FREQUENCY_MINING_LASER
					break
				case GROUP_SHIELD_BOOSTER
					This.ModuleList_Regen_Shield:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_AFTERBURNER
					This.ModuleList_AB_MWD:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_ARMOR_REPAIRERS
					This.ModuleList_Repair_Armor:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_DATA_MINER
					if ${TypeID} == TYPE_SALVAGER
					{
						This.Module_Salvagers_Range:Set[${ModuleIter.Value.OptimalRange}]
						This.ModuleList_Salvagers:Insert[${ModuleIter.Value.ID}]
					}
					break
				case GROUP_SALVAGER
					This.Module_Salvagers_Range:Set[${ModuleIter.Value.OptimalRange}]
					This.ModuleList_Salvagers:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_TRACTOR_BEAM
					This.Module_TractorBeams_Range:Set[${ModuleIter.Value.OptimalRange}]
					This.ModuleList_TractorBeams:Insert[${ModuleIter.Value.ID}]
					break
				case NONE
					This.ModuleList_Repair_Hull:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_CLOAKING_DEVICE
					This.ModuleList_Cloaks:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_STASIS_WEB
					This.ModuleList_StasisWeb:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_SENSORBOOSTER
					This.ModuleList_SensorBoost:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_TARGETPAINTER
					This.ModuleList_TargetPainter:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_TRACKINGCOMPUTER
					This.ModuleList_TrackingComputer:Insert[${ModuleIter.Value.ID}]
					break
				case GROUP_GANGLINK
					This.ModuleList_GangLinks:Insert[${ModuleIter.Value.ID}]
					break
				default
					break
			}
		}
		while ${ModuleIter:Next(exists)}

		UI:Update["obj_Ship", "Ship Module Inventory", "y"]
		
		This.ModuleList_Weapon:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Weapons:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot} ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}

		This.ModuleList_ECCM:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "ECCM Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot} ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}

		This.ModuleList_GangLinks:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Gang Link Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot} ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}
		
		This.ModuleList_ActiveResists:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Active Resistance Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}

		This.ModuleList_Passive:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Passive Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}
			
		This.ModuleList_MiningLaser:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Mining Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}
			
		This.ModuleList_Repair_Armor:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Armor Repair Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}
			
		This.ModuleList_Regen_Shield:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Shield Regen Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}

		This.ModuleList_AB_MWD:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "AfterBurner Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}

		This.ModuleList_Salvagers:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Salvaging Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}

		This.ModuleList_TractorBeams:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Tractor Beam Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}

		This.ModuleList_Cloaks:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Cloaking Device Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}

		This.ModuleList_StasisWeb:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Stasis Web Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}

		This.ModuleList_SensorBoost:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Sensor Boost Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}

		This.ModuleList_TargetPainter:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Target Painter Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}
			
		This.ModuleList_TrackingComputer:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Tracking Computer Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}

		This.ModuleList_ShieldTransporters:GetIterator[ModuleIter]
		if ${ModuleIter:First(exists)}
		{
			UI:Update["obj_Ship", "Shield Transporter Modules:", "g"]
			do
			{
				UI:Update["obj_Ship", " Slot: ${ModuleIter.Value.ToItem.Slot}  ${ModuleIter.Value.ToItem.Name}", "-g"]
			}
			while ${ModuleIter:Next(exists)}
		}

		if ${This.ModuleList_AB_MWD.Used} > 1
		{
			UI:Update["obj_Ship", "Warning: More than 1 Afterburner or MWD was detected, I will only use the first one.", "o"]
		}
	}


}