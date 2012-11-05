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

		This.CommonRef:AddSetting[Prefix,"Anom:"]
		This.CommonRef:AddSetting[RattingSystem,""]
		This.CommonRef:AddSetting[Dropoff,""]
		This.CommonRef:AddSetting[DropoffType,""]
		This.CommonRef:AddSetting[DropoffSubType,""]
		This.CommonRef:AddSetting[DropoffContainer,""]
		
	}
	
	Setting(string, RattingSystem, SetRattingSystem)	
	Setting(string, Prefix, SetPrefix)
	Setting(string, Dropoff, SetDropoff)
	Setting(string, DropoffType, SetDropoffType)
	Setting(string, DropoffSubType, SetDropoffSubType)
	Setting(string, DropoffContainer, SetDropoffContainer)
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
			This:QueueState["MoveToBelt"]
			This:QueueState["Traveling"]
			This:QueueState["Log", 10, "Waiting for rats to spawn, g"]
			This:QueueState["Idle", 5000]
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
	
	
	member:bool MoveToBelt()
	{
		if 1==1
		{
			variable string prefix
			prefix:Set[${Config.BeltPrefix}]
			
			if ${Bookmarks.Used} == 0
			{
				EVE:GetBookmarks[Bookmarks]
				Bookmarks:RemoveByQuery[${LavishScript.CreateQuery[SolarSystemID == ${Me.SolarSystemID}]}, FALSE]
				Bookmarks:RemoveByQuery[${LavishScript.CreateQuery[Label =- "${prefix}"]}, FALSE]
				Bookmarks:Collapse
				
			}
			else
			{
				Bookmarks.Get[1]:Remove
				Bookmarks:Remove[1]
				Bookmarks:Collapse
			}
		
			Move:Bookmark[${Bookmarks.Get[1].Label}]
			Bookmarks:Remove[1]
			Bookmarks:Collapse
			return TRUE
		}
		else
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

			Move:Object[${Entity[${Belts[1].ID}]}, 150000]
			Belts:Remove[1]
			Belts:Collapse
			return TRUE
		}
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
		if !${Drones.DronesInSpace} && !${Drones.DroneTargets.TargetList.Used}
		{
			echo ${Drones.DroneTargets.TargetList.Used} drone targets
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold"]
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
