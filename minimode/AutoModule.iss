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

objectdef obj_Configuration_AutoModule
{
	variable string SetName = "AutoModule"

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

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		This.CommonRef:AddSetting[ActiveHardeners, TRUE]
		This.CommonRef:AddSetting[ActiveShieldBoost, 95]
		This.CommonRef:AddSetting[ActiveArmorRepair, 95]
		This.CommonRef:AddSetting[ActiveShieldCap, 35]
		This.CommonRef:AddSetting[ActiveArmorCap, 35]
		This.CommonRef:AddSetting[Cloak, TRUE]
		This.CommonRef:AddSetting[GangLink, TRUE]
		This.CommonRef:AddSetting[SensorBoosters, TRUE]
		This.CommonRef:AddSetting[TrackingComputers, TRUE]
		This.CommonRef:AddSetting[ECCM, TRUE]
		This.CommonRef:AddSetting[DroneControlUnit, TRUE]
	}

	Setting(bool, ActiveHardeners, SetActiveHardeners)
	Setting(bool, ShieldBoost, SetShieldBoost)
	Setting(int, ActiveShieldBoost, SetActiveShieldBoost)
	Setting(int, ActiveShieldCap, SetActiveShieldCap)
	Setting(bool, ArmorRepair, SetArmorRepair)
	Setting(int, ActiveArmorRepair, SetActiveArmorRepair)
	Setting(int, ActiveArmorCap, SetActiveArmorCap)
	Setting(bool, Cloak, SetCloak)
	Setting(bool, GangLink, SetGangLink)
	Setting(bool, SensorBoosters, SetSensorBoosters)
	Setting(bool, TrackingComputers, SetTrackingComputers)
	Setting(bool, ECCM, SetECCM)
	Setting(bool, DroneControlUnit, SetDroneControlUnit)
	
}

objectdef obj_AutoModule inherits obj_State
{
	variable obj_Configuration_AutoModule Config
	variable bool SafetyOveride=FALSE
	variable bool DropCloak=FALSE
	
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		This.PulseFrequency:Set[100]
		DynamicAddMiniMode("AutoModule", "AutoModule")
	}
	
	method Start()
	{
		This:QueueState["AutoModule"]
	}
	
	method Stop()
	{
		This:Clear
	}
	
	member:bool AutoModule()
	{
		if !${Client.InSpace} || ${SafetyOveride}
		{
			return FALSE
		}
		if ${Me.ToEntity.IsCloaked}
		{
			return FALSE
		}
		if ${Ship.ModuleList_Cloaks.Count} && ${Config.Cloak}
		{
			if ${This.DropCloak}
			{
				if ${Ship.ModuleList_Cloaks.ActiveCount}
				{
					Ship.ModuleList_Cloaks:Deactivate
				}
			}
			else
			{
				if !${Ship.ModuleList_Cloaks.ActiveCount}
				{
					Ship.ModuleList_Cloaks:Activate
				}
			}
		}

		if ${Ship.ModuleList_Regen_Shield.InactiveCount} && ((${MyShip.ShieldPct} < ${Config.ActiveShieldBoost} && ${MyShip.CapacitorPct} > ${Config.ActiveShieldCap}) || ${Config.ShieldBoost})
		{
			Ship.ModuleList_Regen_Shield:ActivateCount[${Ship.ModuleList_Regen_Shield.InactiveCount}]
		}
		if ${Ship.ModuleList_Regen_Shield.ActiveCount} && (${MyShip.ShieldPct} > ${Config.ActiveShieldBoost} || ${MyShip.CapacitorPct} < ${Config.ActiveShieldCap}) && !${Config.ShieldBoost}
		{
			Ship.ModuleList_Regen_Shield:DeactivateCount[${Ship.ModuleList_Regen_Shield.ActiveCount}]
		}
		
		if ${Ship.ModuleList_Repair_Armor.InactiveCount} && ((${MyShip.ArmorPct} < ${Config.ActiveArmorRepair} && ${MyShip.CapacitorPct} > ${Config.ActiveArmorCap}) || ${Config.ArmorRepair})
		{
			Ship.ModuleList_Repair_Armor:ActivateCount[${Ship.ModuleList_Repair_Armor.InactiveCount}]
		}
		if ${Ship.ModuleList_Repair_Armor.ActiveCount} && (${MyShip.ArmorPct} > ${Config.ActiveArmorRepair} || ${MyShip.CapacitorPct} < ${Config.ActiveArmorCap}) && !${Config.ArmorRepair}
		{
			Ship.ModuleList_Repair_Armor:DeactivateCount[${Ship.ModuleList_Repair_Armor.ActiveCount}]
		}
		
		if ${Ship.ModuleList_ActiveResists.Count} && ${Config.ActiveHardeners}
		{
			Ship.ModuleList_ActiveResists:ActivateCount[${Ship.ModuleList_ActiveResists.Count}]
		}
		
		if ${Ship.ModuleList_GangLinks.ActiveCount} < ${Ship.ModuleList_GangLinks.Count} && ${Me.ToEntity.Mode} != 3 && ${Config.GangLink}
		{
			Ship.ModuleList_GangLinks:ActivateCount[${Math.Calc[${Ship.ModuleList_GangLinks.Count} - ${Ship.ModuleList_GangLinks.ActiveCount}]}]
		}

		if ${Ship.ModuleList_SensorBoost.ActiveCount} < ${Ship.ModuleList_SensorBoost.Count} && ${Config.SensorBoosters}
		{
			Ship.ModuleList_SensorBoost:ActivateCount[${Math.Calc[${Ship.ModuleList_SensorBoost.Count} - ${Ship.ModuleList_SensorBoost.ActiveCount}]}]
		}
		
		if ${Ship.ModuleList_TrackingComputer.ActiveCount} < ${Ship.ModuleList_TrackingComputer.Count} && ${Config.TrackingComputers}
		{
			Ship.ModuleList_TrackingComputer:ActivateCount[${Math.Calc[${Ship.ModuleList_TrackingComputer.Count} - ${Ship.ModuleList_TrackingComputer.ActiveCount}]}]
		}
		
		if ${Ship.ModuleList_ECCM.ActiveCount} < ${Ship.ModuleList_ECCM.Count} && ${Config.ECCM}
		{
			Ship.ModuleList_ECCM:ActivateCount[${Math.Calc[${Ship.ModuleList_ECCM.Count} - ${Ship.ModuleList_ECCM.ActiveCount}]}]
		}

		if ${Ship.ModuleList_DroneControlUnit.ActiveCount} < ${Ship.ModuleList_DroneControlUnit.Count} && ${Config.DroneControlUnit}
		{
			UI:Update["AutoModule", "Activating DroneControlUnit", "g"]
			Ship.ModuleList_DroneControlUnit:ActivateCount[${Math.Calc[${Ship.ModuleList_DroneControlUnit.Count} - ${Ship.ModuleList_DroneControlUnit.ActiveCount}]}, FALSE]
		}
		
		return FALSE
	}

}