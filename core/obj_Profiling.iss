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

variable collection:int TimeSpent
variable queue:int TimeTrack
variable queue:string TimeName
variable int TimeTracked
variable collection:int TimeCalled

objectdef obj_Profiling inherits obj_State
{

	method Initialize()
	{
		
		This[parent]:Initialize
		RandomDelta:Set[0]

		This:QueueState["Update", 10000]
	}
	
	method StartTrack(string name)
	{
		TimeTrack:Queue[${LavishScript.RunningTime}]
		TimeName:Queue[${name}]
	}
	
	method EndTrack()
	{
		variable int TimeTrackedHere = ${Math.Calc[(${LavishScript.RunningTime} - ${TimeTrack.Peek}) - ${TimeTracked}]}
		if !${TimeSpent.Element[${TimeName.Peek}](exists)}
		{
			TimeSpent:Set[${TimeName.Peek}, 0]
			TimeCalled:Set[${TimeName.Peek}, 0]
		}
		TimeSpent.Element[${TimeName.Peek}]:Inc[${TimeTrackedHere}]
		TimeCalled.Element[${TimeName.Peek}]:Inc
		TimeTracked:Inc[${TimeTrackedHere}]
		TimeTrack:Dequeue
		TimeName:Dequeue
		if ${TimeTrack.Used} == 0
		{
			TimeTracked:Set[0]
		}
	}
	
	member:bool Update()
	{
		variable iterator TimeSpentIterator
		variable int count=0
		variable int upperlimit
		variable string InsertString
		variable int conversion
		
		variable collection:string TimeSpentCopy
		
		TimeSpent:GetIterator[TimeSpentIterator]

		if ${TimeSpentIterator:First(exists)}
		{
			do
			{
				InsertString:Set[${TimeSpentIterator.Value}]
				if ${InsertString.Length} < 20
				{
					do
					{
						InsertString:Set[0${InsertString}]
					}
					while ${InsertString.Length} < 20
				}
				
				TimeSpentCopy:Set[${InsertString}, ${TimeSpentIterator.Key}]
			}
			while ${TimeSpentIterator:Next(exists)}
		}
		
		count:Set[0]
		TimeSpentCopy:GetIterator[TimeSpentIterator]
		if ${TimeSpentIterator:Last(exists)}
		{
			upperlimit:Set[${TimeSpentIterator.Key}]
			do
			{
				count:Inc
				if ${count} == 9
				{
					break
				}
				conversion:Set[${TimeSpentIterator.Key}]
				UIElement[obj_ProfilingGauge${count}@Profiling@ComBotTab@ComBot]:SetRange[${upperlimit}]
				UIElement[obj_ProfilingGauge${count}@Profiling@ComBotTab@ComBot]:SetValue[${TimeSpentIterator.Key}]
				UIElement[obj_ProfilingGauge${count}_Text@Profiling@ComBotTab@ComBot]:SetText[${TimeSpentIterator.Value} - ${conversion}ms in ${TimeCalled.Element[${TimeSpentIterator.Value}]} calls]
				
			}
			while ${TimeSpentIterator:Previous(exists)}
		}
		while ${count} < 9
		{
			UIElement[obj_ProfilingGauge${count}@Profiling@ComBotTab@ComBot]:SetValue[0]
			UIElement[obj_ProfilingGauge${count}_Text@Profiling@ComBotTab@ComBot]:SetText[]
			count:Inc
		}
		TimeSpent:Clear
		TimeCalled:Clear
		TimeTrack:Clear
		TimeName:Clear
		
		return FALSE
	}

}