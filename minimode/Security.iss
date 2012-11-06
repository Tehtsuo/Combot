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
		
		This.CommonRef:AddSetting[FleeTo,""]
	}

	Setting(bool, MeToPilot, SetMeToPilot)	
	Setting(bool, MeToCorp, SetMeToCorp)	
	Setting(bool, MeToAlliance, SetMeToAlliance)	
	Setting(bool, CorpToPilot, SetCorpToPilot)	
	Setting(bool, CorpToCorp, SetCorpToCorp)	
	Setting(bool, CorpToAlliance, SetCorpToAlliance)	
	Setting(bool, AllianceToPilot, SetAllianceToPilot)	
	Setting(bool, AllianceToCorp, SetAllianceToCorp)	
	Setting(bool, AllianceToAlliance, SetAllianceToAlliance)	
	Setting(int, MeToPilot_Value, SetMeToPilot_Value)	
	Setting(int, MeToCorp_Value, SetMeToCorp_Value)	
	Setting(int, MeToAlliance_Value, SetMeToAlliance_Value)	
	Setting(int, CorpToPilot_Value, SetCorpToPilot_Value)	
	Setting(int, CorpToCorp_Value, SetCorpToCorp_Value)	
	Setting(int, CorpToAlliance_Value, SetCorpToAlliance_Value)	
	Setting(int, AllianceToPilot_Value, SetAllianceToPilot_Value)	
	Setting(int, AllianceToCorp_Value, SetAllianceToCorp_Value)	
	Setting(int, AllianceToAlliance_Value, SetAllianceToAlliance_Value)	
	Setting(bool, FleeWaitTime_Enabled, SetFleeWaitTime_Enabled)	
	Setting(int, FleeWaitTime, SetFleeWaitTime)	
	Setting(bool, Break_Enabled, SetBreak_Enabled)	
	Setting(int, Break_Duration, SetBreak_Duration)	
	Setting(int, Break_Interval, SetBreak_Interval)	
	Setting(string, FleeTo, SetFleeTo)	
	Setting(bool, TargetFlee, SetTargetFlee)	
	Setting(bool, CorpFlee, SetCorpFlee)
	Setting(bool, AllianceFlee, SetAllianceFlee)
	Setting(bool, FleetFlee, SetFleetFlee)
	
}	

objectdef obj_Security inherits obj_State
{
	variable obj_Configuration_Security Config
	variable obj_SecurityUI SecurityUI

	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[FALSE]
		DynamicAddMiniMode("MemoryManager", "MemoryManager")

		if !${Config.FleeTo(exists)} || ${Config.FleeTo.Equal[NULL]} || ${Config.FleeTo.Equal[]}
		{
			UI:Update["obj_Security", "No flee bookmark set.  This is DANGEROUS!", "r"]
			UI:Update["obj_Security", "Specify a flee bookmark in the Security settings!", "r"]
		}
	}
	
	method Start()
	{
		if ${This.IsIdle}
		{
			This:QueueState["CheckSafe", 500]
		}
	}
	
	method Stop()
	{
		This:Clear
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
		
			if ${Config.MeToPilot} && ${Pilot_Iterator.Value.Standing.MeToPilot} < ${Config.MeToPilot_Value}
			{
				This:QueueState["PrepFlee", 500, "${Pilot_Iterator.Value.Name}(pilot) is ${Pilot_Iterator.Value.Standing.MeToPilot} standing to you"]
				This:QueueState["Flee", 500]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.MeToCorp} && ${Pilot_Iterator.Value.Standing.MeToCorp} < ${Config.MeToCorp_Value}
			{
				This:QueueState["PrepFlee", 500, "${Pilot_Iterator.Value.Corp.Name}(corp) is ${Pilot_Iterator.Value.Standing.MeToCorp} standing to you"]
				This:QueueState["Flee", 500]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.MeToAlliance} && ${Pilot_Iterator.Value.Standing.MeToAlliance} < ${Config.MeToAlliance_Value}
			{
				This:QueueState["PrepFlee", 500, "${Pilot_Iterator.Value.Alliance.Name}(alliance) is ${Pilot_Iterator.Value.Standing.MeToAlliance} standing to you"]
				This:QueueState["Flee", 500]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.CorpToPilot} && ${Pilot_Iterator.Value.Standing.CorpToPilot} < ${Config.CorpToPilot_Value}
			{
				This:QueueState["PrepFlee", 500, "${Pilot_Iterator.Value.Name}(pilot) is ${Pilot_Iterator.Value.Standing.CorpToPilot} standing to your corporation"]
				This:QueueState["Flee", 500]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.CorpToCorp} && ${Pilot_Iterator.Value.Standing.CorpToCorp} < ${Config.CorpToCorp_Value}
			{
				This:QueueState["PrepFlee", 500, "${Pilot_Iterator.Value.Corp.Name}(corp) is ${Pilot_Iterator.Value.Standing.CorpToCorp} standing to your corporation"]
				This:QueueState["Flee", 500]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.CorpToAlliance} && ${Pilot_Iterator.Value.Standing.CorpToAlliance} < ${Config.CorpToAlliance_Value}
			{
				This:QueueState["PrepFlee", 500, "${Pilot_Iterator.Value.Alliance.Name}(alliance) is ${Pilot_Iterator.Value.Standing.CorpToAlliance} standing to your corporation"]
				This:QueueState["Flee", 500]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.AllianceToPilot} && ${Pilot_Iterator.Value.Standing.AllianceToPilot} < ${Config.AllianceToPilot_Value}
			{
				This:QueueState["PrepFlee", 500, "${Pilot_Iterator.Value.Name}(pilot) is ${Pilot_Iterator.Value.Standing.AllianceToPilot} standing to your alliance"]
				This:QueueState["Flee", 500]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.AllianceToCorp} && ${Pilot_Iterator.Value.Standing.AllianceToCorp} < ${Config.AllianceToCorp_Value}
			{
				This:QueueState["PrepFlee", 500, "${Pilot_Iterator.Value.Corp.Name}(corp) is ${Pilot_Iterator.Value.Standing.AllianceToCorp} standing to your alliance"]
				This:QueueState["Flee", 500]
				Profiling:EndTrack
				return TRUE
			}
			if ${Config.AllianceToAlliance} && ${Pilot_Iterator.Value.Standing.AllianceToAlliance} < ${Config.AllianceToAlliance_Value}
			{
				This:QueueState["PrepFlee", 500, "${Pilot_Iterator.Value.Alliance.Name}(alliance) is ${Pilot_Iterator.Value.Standing.AllianceToAlliance} standing to your alliance"]
				This:QueueState["Flee", 500]
				Profiling:EndTrack
				return TRUE
			}
			
		}
		while ${Pilot_Iterator:Next(exists)}

		if ${Config.TargetFlee}
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
			ComBot:Resume
			This:QueueState["CheckSafe", 500]
			Profiling:EndTrack
			return TRUE
		}
		Profiling:EndTrack
		return FALSE
	}
	
	member:bool PrepFlee(string Message)
	{
		variable iterator Behaviors
		UI:Update["obj_Security", "Flee triggered!", "r"]
		UI:Update["obj_Security", "${Message}", "r"]
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
		return TRUE
	}
	
	member:bool Flee()
	{
		Profiling:StartTrack["Security_Flee"]

		Move:Bookmark[${Config.FleeTo}]
		
		if !${Me.InStation}
		{
			Profiling:EndTrack
			return FALSE
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
	
	member:bool Log(string text)
	{
		UI:Update["obj_Security", "${text.Escape}", "g"]
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
		
		UIElement[FleeToList@ComBot_Security_Frame@ComBot_Security]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[FleeTo@ComBot_Security_Frame@ComBot_Security].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Config.FleeTo.Length}].Equal[${Config.FleeTo}]} && ${BookmarkIterator.Value.Label.NotEqual[${Config.FleeTo}]}
						UIElement[FleeToList@ComBot_Security_Frame@ComBot_Security]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[FleeToList@ComBot_Security_Frame@ComBot_Security]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}
			
		return FALSE
	}

}