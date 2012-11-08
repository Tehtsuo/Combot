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

objectdef obj_DelayAction
{
	variable string Action
	variable int Delay
	
	method Initialize(string argAction, int argDelay)
	{
		Action:Set[${argAction.Escape}]
		Delay:Set[${argDelay}]
	}
}

objectdef obj_Delay inherits obj_State
{
	variable index:obj_DelayAction Actions 
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[100]
		RandomDelta:Set[0]
	}
	
	method RegisterAction(string argAction, int argDelay, int ActionRandomDelta=500)
	{
		variable int trueDelay = ${Math.Calc[${argDelay} + ${Math.Rand[${ActionRandomDelta}]} + ${LavishScript.RunningTime}]}
		Actions:Insert["${argAction.Escape}", ${trueDelay}]
		if ${CurState.Name.Equal["Idle"]}
		{
			CurState.Name:Set["CheckAction"]
			NextPulse:Set[${trueDelay}]
		}
		else
		{
			if ${trueDelay} < ${NextPulse}
			{
				NextPulse:Set[${trueDelay}]
			}
		}
	}
	
	member:bool CheckAction()
	{
		variable iterator ActionIterator
		Actions:GetIterator[ActionIterator]
		if ${ActionIterator:First(exists)}
		{
			NextPulse:Set[${ActionIterator.Value.Delay}]
			do
			{
				if ${ActionIterator.Value.Delay} < ${LavishScript.RunningTime}
				{
					Execute ${ActionIterator.Value.Action}
					Actions:Remove[${ActionIterator.Key}]
					Actions:Collapse
					NextPulse:Set[${Math.Rand[250]}]
					return FALSE
				}
				if ${ActionIterator.Value.Delay} < ${NextPulse}
				{
					NextPulse:Set[${ActionIterator.Value.Delay}]
				}
			}
			while ${ActionIterator:Next(exists)}
		}
		else
		{
			return TRUE
		}
	}

}