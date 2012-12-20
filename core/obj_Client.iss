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

objectdef obj_Client
{
	variable int PulseIntervalInMilliseconds = 500
	variable int NextPulse
	
	variable bool Ready=TRUE
	variable bool Undock=FALSE
	variable int64 SystemID=${Me.SolarSystemID}
	
	method Initialize()
	{
		Event[ISXEVE_onFrame]:AttachAtom[This:Pulse]
	}

	method Shutdown()
	{
		Event[ISXEVE_onFrame]:DetachAtom[This:Pulse]
		if !${EVE.Is3DDisplayOn}
		{
			EVE:Toggle3DDisplay
		}
		if !${EVE.IsUIDisplayOn}
		{
			EVE:ToggleUIDisplay
		}
		if !${EVE.IsTextureLoadingOn}
		{
			EVE:ToggleTextureLoading
		}		
	}	

	method Pulse()
	{
		if ${LavishScript.RunningTime} >= ${This.NextPulse}
		{
			if ${Me.SolarSystemID} != ${SystemID}
			{
				SystemID:Set[${Me.SolarSystemID}]
				This:Wait[5000]
				return
			}
			
			This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${PulseIntervalInMilliseconds} + ${Math.Rand[500]}]}]

			This:ManageGraphics
			
			if ${This.Undock}
			{
				if ${This.InSpace}
				{
					This:Undock
				}
			}

			if ${ComBot.Paused}
			{
				return
			}			
			
			This.Ready:Set[TRUE]
		}
	}
	
	member:bool InSpace()
	{
		if ${Me.InStation}
		{
			if ${Ship.RetryUpdateModuleList} == 0
			{
				Ship.RetryUpdateModuleList:Set[1]
			}
		}
		if ${Me.InSpace(type).Name.Equal[bool]} && ${EVE.EntitiesCount} > 0
		{
			return ${Me.InSpace}
		}
		return FALSE
	}
	
	method ManageGraphics()
	{
		if ${Config.Common.Disable3D} && ${EVE.Is3DDisplayOn}
		{
			EVE:Toggle3DDisplay
		}
		elseif !${Config.Common.Disable3D} && !${EVE.Is3DDisplayOn}
		{
			EVE:Toggle3DDisplay
		}
		if ${Config.Common.DisableUI} && ${EVE.IsUIDisplayOn}
		{
			EVE:ToggleUIDisplay
		}
		elseif !${Config.Common.DisableUI} && !${EVE.IsUIDisplayOn}
		{
			EVE:ToggleUIDisplay
		}
		if ${Config.Common.DisableTexture} && ${EVE.IsTextureLoadingOn}
		{
			EVE:ToggleTextureLoading
		}
		elseif !${Config.Common.DisableTexture} && !${EVE.IsTextureLoadingOn}
		{
			EVE:ToggleTextureLoading
		}
	}
	
	method Undock()
	{
		variable index:bookmark BookmarkIndex
		variable string suffix
		suffix:Set[${UndockWarp.Config.UndockSuffix}]
		EVE:GetBookmarks[BookmarkIndex]
		BookmarkIndex:RemoveByQuery[${LavishScript.CreateQuery[SolarSystemID == ${Me.SolarSystemID}]}, FALSE]
		BookmarkIndex:RemoveByQuery[${LavishScript.CreateQuery[Label =- "${UndockWarp.Config.substring}"]}, FALSE]
		BookmarkIndex:RemoveByQuery[${LavishScript.CreateQuery[Distance > 150000]}, FALSE]
		BookmarkIndex:RemoveByQuery[${LavishScript.CreateQuery[Distance < 2000000]}, FALSE]
		BookmarkIndex:Collapse
		
		if ${BookmarkIndex.Used}
		{
			UI:Update["Client", "Undock warping to ${BookmarkIndex.Get[1].Label}", "g"]
			BookmarkIndex.Get[1]:WarpTo
			Client:Wait[5000]
		}
		This.Undock:Set[FALSE]
	}

	method Wait(int delay)
	{
		UI:Update["Client", "Initiating ${delay} millisecond wait", "-o"]
		This.Ready:Set[FALSE]
		This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${delay}]}]
	}
	
	member:bool Inventory()
	{
		if !${EVEWindow[Inventory](exists)}
		{
			EVE:Execute[OpenInventory]
			return FALSE
		}
		if 	${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].UsedCapacity} == -1 || \
			${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo].Capacity} <= 0
		{
			UI:Update["Client", "Cargo hold information invalid, activating", "g"]
			EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipCargo]:MakeActive
			return FALSE
		}
		if ${MyShip.HasOreHold}
		{
			if 	${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold].UsedCapacity} == -1 || \
				${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold].Capacity} <= 0
			{
				UI:Update["Client", "Ore hold information invalid, activating", "g"]
				EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipOreHold]:MakeActive
				return FALSE
			}
		}
		if ${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar](exists)}
		{
			if 	${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar].UsedCapacity} == -1 || \
				${EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar].Capacity} <= 0
			{
				UI:Update["Client", "Fleet Hangar information invalid, activating", "g"]
				EVEWindow[Inventory].ChildWindow[${MyShip.ID}, ShipFleetHangar]:MakeActive
				return FALSE
			}
		}
		
		return TRUE
	}
}