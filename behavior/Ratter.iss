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

objectdef obj_Configuration_Ratter
{
	variable string SetName = "Ratter"

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

		This.CommonRef:AddSetting[RattingSystem,""]
		This.CommonRef:AddSetting[Dropoff,""]
		
	}
	
	Setting(string, RattingSystem, SetRattingSystem)	
	Setting(string, Dropoff, SetDropoff)	

}

objectdef obj_Ratter inherits obj_State
{
	variable obj_Configuration_Ratter Config
	
	variable obj_TargetList Rats
	variable index:entity Belts

	method Initialize()
	{
		This[parent]:Initialize
		LavishScript:RegisterEvent[ComBot_Orca_InBelt]
		PulseFrequency:Set[500]
		Rats.LockOutOfRange:Set[FALSE]
		Dynamic:AddBehavior["Ratter", "Belt Ratter", FALSE]
	}

	method Shutdown()
	{
	}	
	
	method Start()
	{
		This:PopulateTargetList
		Drones:StayDeployed
		Drones:Aggressive
		UI:Update["obj_Ratter", "Started", "g"]
		This:AssignStateQueueDisplay[DebugStateList@Debug@ComBotTab@ComBot]
		if ${This.IsIdle}
		{
			This:QueueState["Rat"]
		}
	}
	
	method Stop()
	{
		This:DeactivateStateQueueDisplay
		This:Clear
	}
	
	method PopulateTargetList()
	{
		Rats:ClearQueryString
		variable string QueryString="CategoryID = CATEGORYID_ENTITY && IsNPC && !IsMoribund && Bounty > 100000 && !("
		
		;Exclude Groups here
		QueryString:Concat["GroupID = GROUP_CONCORDDRONE ||"]
		QueryString:Concat["GroupID = GROUP_CONVOYDRONE ||"]
		QueryString:Concat["GroupID = GROUP_CONVOY ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLEOBJECT ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESHIP ||"]
		QueryString:Concat["GroupID = GROUP_SPAWNCONTAINER ||"]
		QueryString:Concat["GroupID = CATEGORYID_ORE ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESTRUCTURE)"]
		
		Rats:AddQueryString["${QueryString.Escape}"]
	}
	
	
	member:bool Traveling()
	{
		if ${Move.Traveling} || ${Me.ToEntity.Mode} == 3
		{
			return FALSE
		}
		return TRUE
	}
	
	
	member:bool MoveToBelt()
	{
			variable int curBelt
			variable int TryCount

			if ${Belts.Used} == 0
			{
				EVE:QueryEntities[Belts, "GroupID = GROUP_ASTEROIDBELT"]
			}

			Move:Object[${Entity[${Belts[1].ID}]}]
			Belts:Remove[1]
			Belts:Collapse
			return TRUE
	}

	member:bool Undock()
	{
		Move:Undock
		return TRUE
	}
	member:bool InitialUpdate()
	{
		Rats:RequestUpdate
		return TRUE
	}
	
	member:bool Updated()
	{
		return ${Rats.Updated}
	}
	member:bool Rat()
	{
		if !${Client.InSpace}
		{
			This:QueueState["Undock"]
			This:QueueState["MoveToBelt"]
			This:QueueState["Traveling"]
			This:QueueState["InitialUpdate"]
			This:QueueState["Updated"]
			This:QueueState["Rat"]
			return TRUE
		}
		
		if !${Rats.TargetList.Used} && !${Drones.DronesInSpace} && !${Drones.DroneTargets.TargetList.Used}
		{
			echo ${Drones.DroneTargets.TargetList.Used} drone targets
			This:QueueState["MoveToBelt"]
			This:QueueState["Traveling"]
			This:QueueState["InitialUpdate"]
			This:QueueState["Updated"]
			This:QueueState["Rat"]
			return TRUE
		}
		
		return FALSE
	}
	

}	






objectdef obj_RatterUI inherits obj_State
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
		
		UIElement[MiningSystemList@Miner_Frame@ComBot_Miner]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[MiningSystem@Miner_Frame@ComBot_Miner].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Miner.Config.MiningSystem.Length}].Equal[${Miner.Config.MiningSystem}]}
						UIElement[MiningSystemList@Miner_Frame@ComBot_Miner]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[MiningSystemList@Miner_Frame@ComBot_Miner]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}

		UIElement[DropoffList@Miner_Frame@ComBot_Miner]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[Dropoff@Miner_Frame@ComBot_Miner].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Miner.Config.Dropoff.Length}].Equal[${Miner.Config.Dropoff}]}
						UIElement[DropoffList@Miner_Frame@ComBot_Miner]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[DropoffList@Miner_Frame@ComBot_Miner]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}
			
		return FALSE
	}

}
