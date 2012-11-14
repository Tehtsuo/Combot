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

		This.CommonRef:AddSetting[Substring,"Anom:"]
		This.CommonRef:AddSetting[SalvagePrefix,"Salvage:"]
		This.CommonRef:AddSetting[RattingSystem,""]
		This.CommonRef:AddSetting[Dropoff,""]
		This.CommonRef:AddSetting[DropoffType,""]
		This.CommonRef:AddSetting[DropoffSubType,""]
		This.CommonRef:AddSetting[DropoffContainer,""]
		This.CommonRef:AddSetting[SpeedTankDistance,5000]
		This.CommonRef:AddSetting[TetherPilot,""]
		
	}
	
	Setting(bool, WarpToAnom, SetWarpToAnom)
	Setting(bool, BeltRat, SetBeltRat)
	Setting(bool, Salvage, SetSalvage)
	Setting(bool, SpeedTank, SetSpeedTank)
	Setting(bool, Tether, SetTether)
	Setting(int, Warp, SetWarp)
	Setting(int, Threshold, SetThreshold)
	Setting(int, SpeedTankDistance, SetSpeedTankDistance)
	Setting(string, RattingSystem, SetRattingSystem)	
	Setting(string, Substring, SetSubstring)
	Setting(string, Dropoff, SetDropoff)
	Setting(string, DropoffType, SetDropoffType)
	Setting(string, DropoffSubType, SetDropoffSubType)
	Setting(string, DropoffContainer, SetDropoffContainer)
	Setting(string, SalvagePrefix, SetSalvagePrefix)
	Setting(string, TetherPilot, SetTetherPilot)
}

objectdef obj_Ratter inherits obj_State
{
	variable obj_Configuration_Ratter Config
	variable obj_RatterUI LocalUI
	
	variable obj_TargetList Rats
	variable index:entity Belts
	variable index:bookmark Bookmarks

	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[500]
		Rats:AddAllNPCs
		DynamicAddBehavior("Ratter", "Ratter")
	}

	method Shutdown()
	{
		This:DeactivateStateQueueDisplay
		This:Clear
	}	
	
	method Start()
	{
		UI:Update["obj_Ratter", "Started", "g"]
		This:AssignStateQueueDisplay[DebugStateList@Debug@ComBotTab@ComBot]
		if ${This.IsIdle}
		{
			DroneControl:Stop
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold"]
		}
	}
	
	method Stop()
	{
		This:DeactivateStateQueueDisplay
		This:Clear
	}
	
	member:bool OpenCargoHold()
	{
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["Ratter", "Opening inventory", "g"]
			MyShip:Open
			return FALSE
		}
		return TRUE
	}
	
	member:bool CheckCargoHold()
	{
		if ${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity} >= ${Config.Threshold} * .01
		{
			UI:Update["Ratter", "Unload trip required", "g"]
			Cargo:At[${Config.Dropoff},${Config.DropoffType},${Config.DropoffSubType}, ${Config.DropoffContainer}]:Unload
			This:QueueState["Traveling"]
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold"]
			return TRUE
		}
		else
		{
			This:QueueState["GoToRattingSystem"]
			This:QueueState["Traveling"]
			This:QueueState["MoveToNewRatLocation"]
			This:QueueState["Traveling"]
			This:QueueState["VerifyRatLocation"]
			This:QueueState["Log", 10, "Waiting for rats to spawn, g"]
			This:QueueState["Idle", 5000]
			This:QueueState["InitialUpdate"]
			This:QueueState["Updated"]
			This:QueueState["Log", 10, "Ratting, g"]
			This:QueueState["Rat"]
			return TRUE
		}
	}
	
	member:bool Log(string text, string color)
	{
		UI:Update["Ratter", "${text}", "${color}"]
		return TRUE
	}
	
	member:bool GoToRattingSystem()
	{
		if !${EVE.Bookmark[${Config.RattingSystem}](exists)}
		{
			UI:Update["Ratter", "No ratting system defined!  Check your settings", "r"]
		}
		if ${EVE.Bookmark[${Config.RattingSystem}].SolarSystemID} != ${Me.SolarSystemID}
		{
			Move:System[${EVE.Bookmark[${Config.RattingSystem}].SolarSystemID}]
		}
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
	
	
	member:bool MoveToNewRatLocation()
	{
		if ${Config.Tether}
		{
			Move:Fleetmember[${Local["${Config.TetherPilot}"].ID}, TRUE]
			return TRUE
		}
		variable int Distance
		Distance:Set[${Math.Calc[${Config.Warp} * 1000]}]

		if ${Bookmarks.Used} == 0 && !${Config.WarpToAnom}
		{
			EVE:GetBookmarks[Bookmarks]
			Bookmarks:RemoveByQuery[${LavishScript.CreateQuery[SolarSystemID == ${Me.SolarSystemID}]}, FALSE]
			Bookmarks:RemoveByQuery[${LavishScript.CreateQuery[Label =- "${Config.Substring}"]}, FALSE]
			Bookmarks:Collapse
			if ${Bookmarks.Used} == 0
			{
				if ${Config.BeltRat}
				{
					if !${Client.InSpace}
					{
						Move:Undock
						return FALSE
					}

					if ${Belts.Used} == 0
					{
						EVE:QueryEntities[Belts, "GroupID = GROUP_ASTEROIDBELT"]
					}

					Move:Object[${Entity[${Belts[1].ID}]}, ${Distance}]
					Belts:Remove[1]
					Belts:Collapse
					return TRUE
				}
				else
				{
					Move:Bookmark[${Config.Dropoff}]
					This:Clear
					This:QueueState["Traveling"]
					This:QueueState["OpenCargoHold"]
					This:QueueState["CheckCargoHold"]
					return TRUE
				}
			}
		}
		elseif !${Config.WarpToAnom}
		{
			UI:Update["Ratter", "Removing ${Bookmarks.Get[1].Label}", "g"]
			Bookmarks.Get[1]:Remove
			Bookmarks:Clear
			return FALSE
		}
	
		if 	${Entity[GroupID==GROUP_WRECK && HaveLootRights](exists)} &&\
			${Config.Salvage} &&\
			!${Entity[CategoryID == CATEGORYID_SHIP && IsPC && !IsFleetMember && OwnerID != ${Me.CharID}]}
		{
			UI:Update["Ratter", "Bookmarking ${Entity[GroupID==GROUP_WRECK && HaveLootRights].Name}", "g"]
			Entity[GroupID==GROUP_WRECK && HaveLootRights]:CreateBookmark["${Config.SalvagePrefix} ${EVETime.Time.Left[-3].Replace[":",""]}","","Corporation Locations"]
		}

		if ${Config.WarpToAnom}
		{
			if !${Client.InSpace}
			{
				Move:Undock
				return FALSE
			}

			dotnet WarpToAnom
			This:InsertState["Traveling"]
			This:InsertState["Idle", 20000]
			return TRUE
		}
		else
		{
			Move:Bookmark[${Bookmarks.Get[1].Label}, TRUE, ${Distance}]
		}
		return TRUE

	}
	
	
	member:bool VerifyRatLocation()
	{
		if ${Entity[CategoryID == CATEGORYID_SHIP && IsPC && !IsFleetMember && OwnerID != ${Me.CharID}]}
		{
			UI:Update["Ratter", "This location is occupied, going to next", "g"]
			This:InsertState["VerifyRatLocation"]
			This:InsertState["Traveling"]
			This:InsertState["MoveToNewRatLocation"]
		}
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
		if !${Busy.IsBusy} && !${Rats.TargetList.Used}
		{
			DroneControl:Stop
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold"]
			return TRUE
		}
		
		DroneControl:Start
		Rats.MaxLockCount:Set[4]
		Rats.AutoLock:Set[TRUE]
		Rats:RequestUpdate
		
		if ${Rats.TargetList.Used}
		{
			if 	${Config.SpeedTank} &&\
				${Me.ToEntity.Mode} != 4
			{
				Rats.TargetList.Get[1]:Orbit[${Math.Calc[${Config.SpeedTankDistance}*1000+1000].Int}]
			}
		}
		
		if ${Rats.LockedTargetList.Used}
		{
			if 	${Ship.ModuleList_Weapon.ActiveCount} < ${Ship.ModuleList_Weapon.Count}
			{
				Ship.ModuleList_Weapon:ActivateCount[${Ship.ModuleList_Weapon.InactiveCount}, ${Rats.LockedTargetList.Get[1].ID}]
				return FALSE
			}
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
			UI:Update["Ratter", "Opening inventory", "g"]
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
		
		UIElement[RattingSystemList@RatterFrame@Frame@ComBot_Ratter]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[RattingSystem@RatterFrame@Frame@ComBot_Ratter].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Ratter.Config.RattingSystem.Length}].Equal[${Ratter.Config.RattingSystem}]}
						UIElement[RattingSystemList@RatterFrame@Frame@ComBot_Ratter]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[RattingSystemList@RatterFrame@Frame@ComBot_Ratter]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}

		UIElement[DropoffList@DropoffFrame@Frame@ComBot_Ratter]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[Dropoff@DropoffFrame@Frame@ComBot_Ratter].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${Ratter.Config.Dropoff.Length}].Equal[${Ratter.Config.Dropoff}]}
						UIElement[DropoffList@DropoffFrame@Frame@ComBot_Ratter]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[DropoffList@DropoffFrame@Frame@ComBot_Ratter]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}
			
		return FALSE
	}

}
