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

objectdef obj_Configuration_Security
{
	variable string SetName = "Security"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]
		
		This.CommonRef:AddSetting[FleeTo,""]
		This.CommonRef:AddSetting[FleeWaitTime,10]
		This.CommonRef:AddSetting[CapFleeThreshold,20]
		This.CommonRef:AddSetting[ShieldFleeThreshold,40]
		This.CommonRef:AddSetting[ArmorFleeThreshold,40]
	}

	Setting(bool, NegativeStanding, SetNegativeStanding)
	Setting(bool, NullStanding, SetNullStanding)
	Setting(bool, FleeWaitTime_Enabled, SetFleeWaitTime_Enabled)	
	Setting(int, FleeWaitTime, SetFleeWaitTime)	
	Setting(string, FleeTo, SetFleeTo)	
	Setting(bool, TargetFlee, SetTargetFlee)	
	Setting(bool, CorpFlee, SetCorpFlee)
	Setting(bool, AllianceFlee, SetAllianceFlee)
	Setting(bool, FleetFlee, SetFleetFlee)
	Setting(bool, CapFlee, SetCapFlee)
	Setting(int, CapFleeThreshold, SetCapFleeThreshold)
	Setting(bool, ShieldFlee, SetShieldFlee)
	Setting(int, ShieldFleeThreshold, SetShieldFleeThreshold)
	Setting(bool, ArmorFlee, SetArmorFlee)
	Setting(int, ArmorFleeThreshold, SetArmorFleeThreshold)
	
}	

objectdef obj_Security inherits obj_State
{
	variable obj_Configuration_Security Config
	variable obj_SecurityUI LocalUI

	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		DynamicAddMiniMode("Security", "Security")

		if !${Config.FleeTo(exists)} || ${Config.FleeTo.Equal[NULL]} || ${Config.FleeTo.Equal[]}
		{
			UI:Update["Security", "No flee bookmark set.  This is DANGEROUS!", "r"]
			UI:Update["Security", "Specify a flee bookmark in the Security settings!", "r"]
		}
	}
	
	method Start()
	{
		if ${This.IsIdle}
		{
			This:QueueState["WaitForLogin"]
			This:QueueState["Idle", 5000]
			This:QueueState["CheckSafe", 500]
		}
	}
	
	method Stop()
	{
		This:Clear
	}
	
	member:bool WaitForLogin()
	{
		if ${Me(exists)} && ${MyShip(exists)} && (${Me.InSpace} || ${Me.InStation})
		{
			EVE:RefreshStandings
			return TRUE
		}
		return FALSE
	}
	
	member:bool CheckSafe(bool ClearFlee=FALSE)
	{
		Profiling:StartTrack["Security_CheckSafe"]
		variable index:pilot Pilots
		variable iterator Pilot_Iterator
		
		if ${This.InPod}
		{
			This:QueueState["PrepFlee", 500, "I am in a pod!"]
			This:QueueState["Flee", 500]
			Profiling:EndTrack
			return TRUE
		}
		
		if ${Client.InSpace}
		{
			if ${Config.CapFlee} && ${MyShip.CapacitorPct} <= ${Config.CapFleeThreshold}
			{
				This:QueueState["PrepFlee", 500, "Cap at or below threshold (${Config.CapFleeThreshold}%)"]
				This:QueueState["Flee", 500, FALSE]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.ShieldFlee} && ${MyShip.ShieldPct} <= ${Config.ShieldFleeThreshold}
			{
				This:QueueState["PrepFlee", 500, "Shields at or below threshold (${Config.ShieldFleeThreshold}%)"]
				This:QueueState["Flee", 500, FALSE]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.ArmorFlee} && ${MyShip.ArmorPct} <= ${Config.ArmorFleeThreshold}
			{
				This:QueueState["PrepFlee", 500, "Armor at or below threshold (${Config.ArmorFleeThreshold}%)"]
				This:QueueState["Flee", 500, FALSE]
				Profiling:EndTrack
				return TRUE
			}
		}

		Profiling:StartTrack["GetLocalPilots"]
		EVE:GetLocalPilots[Pilots]
		Profiling:EndTrack
		Pilots:GetIterator[Pilot_Iterator]

		variable int MyAllianceID
		variable int MyCorpID
		if ${Me.Corp.ID} == -1
		{
			MyCorpID:Set[0]
			MyAllianceID:Set[0]
		}
		else
		{
			MyCorpID:Set[${Me.Corp.ID}]
			if  ${Me.AllianceID} == -1
			{
				MyAllianceID:Set[0]
			}
			else
			{
				MyAllianceID:Set[${Me.AllianceID}]
			}
		}
		
		
		if ${Pilot_Iterator:First(exists)}
		do
		{
			if ${MyCorpID} == ${Pilot_Iterator.Value.Corp.ID} && !${Config.CorpFlee}
			{
				continue
			}
			if ${MyAllianceID} == ${Pilot_Iterator.Value.AllianceID} && !${Config.AllianceFlee}
			{
				continue
			}
			if ${Me.Fleet.IsMember[${Pilot_Iterator.Value.CharID}]} && !${Config.FleetFlee}
			{
				continue
			}
		
			if 	${Config.NegativeStanding} &&\
				(${Pilot_Iterator.Value.Standing.MeToPilot} < 0 ||\
				${Pilot_Iterator.Value.Standing.MeToCorp} < 0 ||\
				${Pilot_Iterator.Value.Standing.MeToAlliance} < 0 ||\
				${Pilot_Iterator.Value.Standing.CorpToPilot} < 0 ||\
				${Pilot_Iterator.Value.Standing.CorpToCorp} < 0 ||\
				${Pilot_Iterator.Value.Standing.CorpToAlliance} < 0 ||\
				${Pilot_Iterator.Value.Standing.AllianceToPilot} < 0 ||\
				${Pilot_Iterator.Value.Standing.AllianceToCorp} < 0 ||\
				${Pilot_Iterator.Value.Standing.AllianceToAlliance} < 0)
				
			{
				This:QueueState["PrepFlee", 500, "${Pilot_Iterator.Value.Name} has negative standing"]
				This:QueueState["Flee", 500]
				Profiling:EndTrack
				return TRUE
			}

			if 	${Config.NullStanding} &&\
				${Pilot_Iterator.Value.Standing.MeToPilot} == 0 &&\
				${Pilot_Iterator.Value.Standing.MeToCorp} == 0 &&\
				${Pilot_Iterator.Value.Standing.MeToAlliance} == 0 &&\
				${Pilot_Iterator.Value.Standing.CorpToPilot} == 0 &&\
				${Pilot_Iterator.Value.Standing.CorpToCorp} == 0 &&\
				${Pilot_Iterator.Value.Standing.CorpToAlliance} == 0 &&\
				${Pilot_Iterator.Value.Standing.AllianceToPilot} == 0 &&\
				${Pilot_Iterator.Value.Standing.AllianceToCorp} == 0 &&\
				${Pilot_Iterator.Value.Standing.AllianceToAlliance} == 0
				
			{
				This:QueueState["PrepFlee", 500, "${Pilot_Iterator.Value.Name} has neutral standing"]
				This:QueueState["Flee", 500]
				Profiling:EndTrack
				return TRUE
			}
		}
		while ${Pilot_Iterator:Next(exists)}

		if ${Config.TargetFlee} && ${Client.InSpace}
		{
			variable index:entity Threats
			variable iterator Threat

			Me:GetTargetedBy[Threats]
			Threats:RemoveByQuery[${LavishScript.CreateQuery[IsPC]}, FALSE]
			Threats:Collapse
			Threats:GetIterator[Threat]
			
			if ${Threat:First(exists)}
			do
			{
				if ${MyCorpID} == ${Threat.Value.Corp.ID} && !${Config.CorpFlee}
				{
					continue
				}
				if ${MyAllianceID} == ${Threat.Value.AllianceID} && !${Config.AllianceFlee}
				{
					continue
				}
				if ${Me.Fleet.IsMember[${Threat.Value.CharID}]} && !${Config.FleetFlee}
				{
					continue
				}
				
				This:QueueState["PrepFlee", 500, "${Threat.Value.Name} is targeting me!"]
				This:QueueState["Flee", 500]
				Profiling:EndTrack
				return TRUE
			}
			while ${Threat:Next(exists)}
		}
		

		
		if ${ClearFlee}
		{
			if !${ComBot.Paused}
			{
				ComBot:Resume
			}
			This:QueueState["CheckSafe", 500]
			Profiling:EndTrack
			return TRUE
		}
		Profiling:EndTrack
		return FALSE
	}
	
	member:bool PrepFlee(string Message)
	{
		if ${Client.InSpace} && !${Move.SavedSpotExists}
		{
			Move:SaveSpot
		}
		variable iterator Behaviors
		uplink speak "Flee triggered!  ${Message}"
		UI:Update["Security", "Flee triggered!", "r"]
		UI:Update["Security", "${Message}", "r"]
		Dynamic.Behaviors:GetIterator[Behaviors]
		if ${Behaviors:First(exists)}
		{
			do
			{
				${Behaviors.Value.Name}:Clear
			}
			while ${Behaviors:Next(exists)}
		}
		Move:Clear
		Move.Traveling:Set[FALSE]
		Drones:RecallAll
		return TRUE
	}
	
	member:bool Flee(bool PerformWait=TRUE)
	{
		Profiling:StartTrack["Security_Flee"]

		if !${Me.InStation}
		{
			Move:Bookmark[${Config.FleeTo}]
			This:QueueState["Traveling"]
		}
		
		if !${PerformWait}
		{
			This:QueueState["StationClear"]
		}
		
		if ${Config.FleeWaitTime_Enabled}
		{
			This:QueueState["Log", 100, "Waiting for ${Config.FleeWaitTime} minutes after flee"]
			This:QueueState["Idle", ${Math.Calc[${Config.FleeWaitTime} * 60000]}]
		}

		This:QueueState["CheckSafe", 500, TRUE]
		Profiling:EndTrack
		return TRUE
	}
	
	member:bool StationClear()
	{
		if ${Me.InStation}
		{
			This:Clear
			This:QueueState["CheckSafe", 500, TRUE]
			return TRUE
		}
		elseif ${MyShip.CapacitorPct} <= ${Config.CapFleeThreshold}
		{
			AutoModule.SafetyOveride:Set[TRUE]
		}
		else
		{
			AutoModule.SafetyOveride:Set[FALSE]
			This:Clear
			This:QueueState["CheckSafe", 500, TRUE]
			return TRUE
		}
		return FALSE
	}
	
	member:bool Log(string text)
	{
		UI:Update["Security", "${text.Escape}", "g"]
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
	
	member:bool InPod()
	{
		variable string ShipName = ${MyShip}
		variable int GroupID
		variable int TypeID

		if !${Client.Ready}
		{
			return FALSE
		}
		
		if ${Client.InSpace}
		{
			GroupID:Set[${MyShip.ToEntity.GroupID}]
			TypeID:Set[${MyShip.ToEntity.TypeID}]
		}
		else
		{
			GroupID:Set[${MyShip.ToItem.GroupID}]
			TypeID:Set[${MyShip.ToItem.TypeID}]
		}
		if ${ShipName.Right[10].Equal["'s Capsule"]} || \
			${GroupID} == GROUP_CAPSULE
		{
			return TRUE
		}
		return FALSE
	}	
	

}

objectdef obj_SecurityUI inherits obj_State
{


	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
	}
	
	method Start()
	{
		This:QueueState["UpdateBookmarkLists", 5]
	}
	
	method Stop()
	{
		This:Clear
	}

	member:bool UpdateBookmarkLists()
	{
		variable index:bookmark Bookmarks
		variable iterator BookmarkIterator

		EVE:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		
		UIElement[FleeToList@FleeFrame@SecurityFrame@ComBot_Security]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[FleeTo@FleeFrame@SecurityFrame@ComBot_Security].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Security.Config.FleeTo.Length}].Equal[${Security.Config.FleeTo}]} && ${BookmarkIterator.Value.Label.NotEqual[${Security.Config.FleeTo}]}
						UIElement[FleeToList@FleeFrame@SecurityFrame@ComBot_Security]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[FleeToList@FleeFrame@SecurityFrame@ComBot_Security]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}
			
		return FALSE
	}

}