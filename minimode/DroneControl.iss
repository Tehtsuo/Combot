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

objectdef obj_Configuration_DroneControl inherits obj_Base_Configuration
{
	method Initialize()
	{
		This[parent]:Initialize["DroneControl"]
	}
	
	method Set_Default_Values()
	{
		This.CommonRef:AddSetting[Sentries, FALSE]
		This.CommonRef:AddSetting[SentryRange, 30]
		This.CommonRef:AddSetting[OutDelay, 10]
		This.CommonRef:AddSetting[DroneCount, 5]
		This.CommonRef:AddSetting[LockCount, 2]
		This.CommonRef:AddSetting[UseIPC, TRUE]
		This.CommonRef:AddSetting[Aggressive, FALSE]
		
		
		
	}

Setting(bool, Sentries, SetSentries)
Setting(int, SentryRange, SetSentryRange)
Setting(int, OutDelay, SetOutDelay)
Setting(int, DroneCount, SetDroneCount)
Setting(int, LockCount, SetLockCount)
Setting(bool, UseIPC, SetUseIPC)
Setting(bool, Aggressive, SetAggressive)

}



objectdef obj_DroneControl inherits obj_State
{
	variable obj_TargetList DroneTargets
	variable obj_Configuration_DroneControl Config
	variable int RecallDelay
	variable int64 CurrentTarget = -1
	variable bool IsBusy
	variable collection:float DroneHealth
	
	variable bool CurAggressive
	variable bool CurIPC
	
	method Initialize()
	{
		This[parent]:Initialize
		DynamicAddMiniMode("DroneControl", "DroneControl")
		DroneTargets.MaxRange:Set[${Me.DroneControlDistance}]
		DroneTargets.AutoLock:Set[TRUE]
		DroneTargets.MinLockCount:Set[${Config.LockCount}]
		This:SetAggressiveState[]
		DroneTargets:SetIPCName[DroneTargets]
		DroneTargets.UseIPC:Set[${Config.UseIPC}]
		CurIPC:Set[${Config.UseIPC}]
	}
	
	method SetAggressiveState()
	{
		variable iterator classIterator
		variable iterator groupIterator
		variable string groups = ""
		variable string seperator = ""
		
		DroneTargets:ClearQueryString
		
		if ${Config.Aggressive}
		{
			NPCData.BaseRef:GetSetIterator[classIterator]
			if ${classIterator:First(exists)}
			{
				do
				{
					seperator:Set[""]
					groups:Set[""]
					classIterator.Value:GetSettingIterator[groupIterator]
					if ${groupIterator:First(exists)}
					{
						do
						{
							groups:Concat["${seperator}GroupID = ${groupIterator.Key}"]
							seperator:Set[" || "]
						}
						while ${groupIterator:Next(exists)}
					}
					DroneTargets:AddQueryString["IsNPC && !IsMoribund && (${groups})"]
				}
				while ${classIterator:Next(exists)}
			}
			DroneTargets:AddTargetingMe
		}
		else
		{
			DroneTargets:AddTargetingMe
		}
		CurAggressive:Set[${Config.Aggressive}]
		
	}
	
	member:int FindBestType(int TargetGroupID)
	{
		variable string TargetClass
		variable int DroneType
		TargetClass:Set[${NPCData.NPCType[${TargetGroupID}]}]
		echo ${TargetClass}
		switch ${TargetClass}
		{
			case Frigate
			case Destroyer
			
				DroneType:Set[${Drones.Data.FindType["Light Scout Drones"]}]
				if ${DroneType} != -1
				{
					return ${DroneType}
				}
			
			case Cruiser
			case BattleCruiser
			
				DroneType:Set[${Drones.Data.FindType["Medium Scout Drones"]}]
				if ${DroneType} != -1
				{
					return ${DroneType}
				}
				
				DroneType:Set[${Drones.Data.FindType["Light Scout Drones"]}]
				if ${DroneType} != -1
				{
					return ${DroneType}
				}
			
			case Battleship
			
			
				DroneType:Set[${Drones.Data.FindType["Heavy Attack Drones"]}]
				if ${DroneType} != -1
				{
					return ${DroneType}
				}
				
				DroneType:Set[${Drones.Data.FindType["Fighters"]}]
				if ${DroneType} != -1
				{
					return ${DroneType}
				}
				
				DroneType:Set[${Drones.Data.FindType["Medium Scout Drones"]}]
				if ${DroneType} != -1
				{
					return ${DroneType}
				}
				
				DroneType:Set[${Drones.Data.FindType["Light Scout Drones"]}]
				if ${DroneType} != -1
				{
					return ${DroneType}
				}
		}
	}
	
	member:int SentryCount()
	{
		variable iterator typeIterator
		variable string types = ""
		variable string seperator = ""
		
		seperator:Set[""]
		types:Set[""]
		Drones.Data.BaseRef.FindSet["Sentry Drones"]:GetSettingIterator[typeIterator]
		if ${typeIterator:First(exists)}
		{
			do
			{
				types:Concat["${seperator}TypeID = ${typeIterator.Key}"]
				seperator:Set[" || "]
			}
			while ${typeIterator:Next(exists)}
		}
		return ${Drones.ActiveDroneCount["${types}"]}
	}
	
	method RecallAllSentry()
	{
		variable iterator typeIterator
		variable string types = ""
		variable string seperator = ""
		
		seperator:Set[""]
		types:Set[""]
		Drones.Data.BaseRef.FindSet["Sentry Drones"]:GetSettingIterator[typeIterator]
		if ${typeIterator:First(exists)}
		{
			do
			{
				types:Concat["${seperator}TypeID = ${typeIterator.Key}"]
				seperator:Set[" || "]
			}
			while ${typeIterator:Next(exists)}
		}
		Drones:Recall["${types}", ${Drones.ActiveDroneCount["${types}"]}]
	}
	
	member:int NonSentryCount()
	{
		variable iterator typeIterator
		variable string types = ""
		variable string seperator = ""
		
		seperator:Set[""]
		types:Set[""]
		Drones.Data.BaseRef.FindSet["Sentry Drones"]:GetSettingIterator[typeIterator]
		if ${typeIterator:First(exists)}
		{
			do
			{
				types:Concat["${seperator}TypeID != ${typeIterator.Key}"]
				seperator:Set[" && "]
			}
			while ${typeIterator:Next(exists)}
		}
		return ${Drones.ActiveDroneCount["ToEntity.GroupID = 100 && (${types})"]}
	}
	
	method RecallAllNonSentry()
	{
		variable iterator typeIterator
		variable string types = ""
		variable string seperator = ""
		
		seperator:Set[""]
		types:Set[""]
		Drones.Data.BaseRef.FindSet["Sentry Drones"]:GetSettingIterator[typeIterator]
		if ${typeIterator:First(exists)}
		{
			do
			{
				types:Concat["${seperator}TypeID != ${typeIterator.Key}"]
				seperator:Set[" && "]
			}
			while ${typeIterator:Next(exists)}
		}
		Drones:Recall["ToEntity.GroupID = 100 && (${types})", ${Drones.ActiveDroneCount["ToEntity.GroupID == 100 && (${types})"]}]
	}
	
	method Start()
	{
		This:QueueState["DroneControl"]
	}
	
	method Stop()
	{
		This:Clear
	}
	
	member:bool DroneControl()
	{
		variable index:activedrone ActiveDrones
		variable iterator DroneIter
		variable float CurDroneHealth
		variable iterator DroneTypesIter
		variable int DroneCount = ${Config.DroneCount}
		if ${DroneCount} > ${Me.MaxActiveDrones}
		{
			DroneCount:Set[${Me.MaxActiveDrones}]
		}
		
		DroneTargets.MinLockCount:Set[${Config.LockCount}]
		variable iterator TargetIterator
		if !${Client.InSpace}
		{
			return FALSE
		}
		if ${Me.ToEntity.Mode} == 3
		{
			if ${Drones.ActiveCount["ToEntity.GroupID == 100"]} > 0
			{
				Drones:Recall["ToEntity.GroupID = 100"]
			}
			return FALSE
		}
		DroneTargets:RequestUpdate
		if ${Drones.DronesInBay.Equal[0]} && ${Drones.DronesInSpace.Equal[0]}
		{
			Busy:UnsetBusy["DroneControl"]
			return FALSE
		}
		if ${IsBusy}
		{
			if ${Drones.DronesInSpace.Equal[0]}
			{
				Busy:UnsetBusy["DroneControl"]
				IsBusy:Set[FALSE]
			}
		}
		
		if ${CurAggressive} != ${Config.Aggressive}
		{
			This:SetAggressiveState[]
		}
		
		if ${CurIPC} != ${Config.UseIPC}
		{
			DroneTargets.UseIPC:Set[${Config.UseIPC}]
			CurIPC:Set[${Config.UseIPC}]
		}
		
		Me:GetActiveDrones[ActiveDrones]
		ActiveDrones:GetIterator[DroneIter]
		if ${DroneIter:First(exists)}
		{
			do
			{
				CurDroneHealth:Set[${Math.Calc[${DroneIter.Value.ToEntity.ShieldPct} + ${DroneIter.Value.ToEntity.ArmorPct} + ${DroneIter.Value.ToEntity.StructurePct}]}]
				
				if ${CurDroneHealth} < 275 && ${CurDroneHealth} < ${DroneHealth.Element[${DroneIter.Value.ID}]} && ${DroneIter.Value.State} != 4 && ${DroneIter.Value.State} != 5
				{
					Drones:Recall["ID = ${DroneIter.Value.ID}", 1]
				}
				
				DroneHealth:Set[${DroneIter.Value.ID}, ${CurDroneHealth}]
			}
			while ${DroneIter:Next(exists)}
		}
		
		
		
		
		
		
		DroneTargets.LockedTargetList:GetIterator[TargetIterator]
		
		if !${Entity[${CurrentTarget}](exists)} || !${Entity[${CurrentTarget}].IsLockedTarget}
		{
			CurrentTarget:Set[-1]
		}
		else
		{
			RecallDelay:Set[${Math.Calc[${LavishScript.RunningTime} + (${Config.OutDelay} * 1000)]}]
			echo ${This.SentryCount} - ${This.NonSentryCount} - ${Entity[${CurrentTarget}].Distance} - ${Math.Calc[(${Config.SentryRange} * 1000)]}
			if ${Entity[${CurrentTarget}].Distance} < (${Config.SentryRange} * 1000)
			{
				if ${This.SentryCount} > 0
				{
					This:RecallAllSentry[]
					This:QueueState["Idle", 5000]
					This:QueueState["DroneControl"]
					return TRUE
				}
			}
			if ${Entity[${CurrentTarget}].Distance} > (${Config.SentryRange} * 1000) && ${Config.Sentries}
			{
				if ${This.NonSentryCount} > 0
				{
					This:RecallAllNonSentry[]
					This:QueueState["Idle", 5000]
					This:QueueState["DroneControl"]
					return TRUE
				}
			}
			if ${Drones.ActiveDroneCount["ToEntity.GroupID == 100"]} > 0
			{
				echo Engage Target
				Drones:Engage["ToEntity.GroupID = 100", ${CurrentTarget}, ${DroneCount}]
			}
			if ${DroneCount} > ${Drones.ActiveDroneCount["ToEntity.GroupID == 100"]}
			{
				if ${Entity[${CurrentTarget}].Distance} > (${Config.SentryRange} * 1000) && ${Config.Sentries}
				{
					Drones:Deploy["TypeID = ${Drones.Data.FindType[Sentry Drones]}", ${Math.Calc[${DroneCount} - ${Drones.ActiveDroneCount["ToEntity.GroupID == 100"]}]}]
				}
				else
				{
					echo Deploy Drones: ${This.FindBestType[${Entity[${CurrentTarget}].GroupID}]} - ${Math.Calc[${DroneCount} - ${Drones.ActiveDroneCount["ToEntity.GroupID == 100"]}]}
					Drones:Deploy["TypeID = ${This.FindBestType[${Entity[${CurrentTarget}].GroupID}]}", ${Math.Calc[${DroneCount} - ${Drones.ActiveDroneCount["ToEntity.GroupID == 100"]}]}]
				}
				IsBusy:Set[TRUE]
				Busy:SetBusy["DroneControl"]
			}
			
			Drones:RefreshActiveTypes
			
			
			
		}
		
		if ${TargetIterator:First(exists)}
		{
			do
			{
				if ${CurrentTarget.Equal[-1]} && ${TargetIterator.Value.Distance} < ${Me.DroneControlDistance}
				{
					CurrentTarget:Set[${TargetIterator.Value.ID}]
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		else
		{
			if ${Drones.ActiveDroneCount["ToEntity.GroupID = 100"]} > 0 && ${LavishScript.RunningTime} > ${RecallDelay}
			{
				Drones:Recall["ToEntity.GroupID = 100"]
				This:QueueState["Idle", 5000]
				This:QueueState["DroneControl"]
				return TRUE
			}
		}
		return FALSE
	}
}