/*

ComBot  Copyright ? 2012  Tehtsuo and Vendan

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

objectdef obj_Busy
{
	variable set BusyModes
	variable bool IsBusy
	variable queue:string ControlQueue
	variable string CurrentControl
	variable bool IsControlled = FALSE
	
	method SetBusy(string Name)
	{
		BusyModes:Add[${Name}]
		IsBusy:Set[TRUE]
	}
	
	method UnsetBusy(string Name)
	{
		BusyModes:Remove[${Name}]
		if ${BusyModes.Used} == 0
		{
			IsBusy:Set[FALSE]
		}
	}
	
	method RequestControl(string Name)
	{
		ControlQueue:Insert[${Name}]
		if !${IsControlled}
		{
			PopControl[]
		}
	}
	
	method ReleaseControl(string Name)
	{
		if ${Name.Equal[${CurrentControl}]}
		{
			PopControl[]
		}
	}
	
	method PopControl()
	{
		if ${ControlQueue.Used} > 0
		{
			CurrentControl:Set[${ControlQueue.Peek}]
			ControlQueue:Dequeue
			IsControlled:Set[TRUE]
		}
		else
		{
			CurrentControl:Set[""]
			IsControlled:Set[FALSE]
		}
	}
	
}