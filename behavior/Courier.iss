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

objectdef obj_Configuration_Courier
{
	variable string SetName = "Courier"

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
	
	member:settingsetref AgentsRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[Agents]}
	}
	

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.CommonRef:AddSet[Agents]
	}
	

}

objectdef obj_Courier inherits obj_State
{
	variable obj_Configuration_Courier Config
	variable obj_CourierUI LocalUI
	
	variable queue:int64 AgentQueue

	method Initialize()
	{
		This[parent]:Initialize
		DynamicAddBehavior("Courier", "Courier Missions")
	}

	method Start()
	{
		UI:Update["Courier", "Started", "g"]
		This:AssignStateQueueDisplay[DebugStateList@Debug@ComBotTab@ComBot]
	}
	
	method Stop()
	{
		This:DeactivateStateQueueDisplay
		This:Clear
	}
	
	member:bool CheckForWork()
	{
		return TRUE
	}
	
	member:bool GetMission()
	{
	}
	
	member:bool Courier()
	{
	}
	
	member:bool Traveling()
	{
		Profiling:StartTrack["Miner: Traveling"]
		if ${Cargo.Processing} || ${Move.Traveling} || ${Me.ToEntity.Mode} == 3
		{
			Profiling:EndTrack
			return FALSE
		}
		Profiling:EndTrack
		return TRUE
	}

	member:bool CompleteMission()
	{
	}
	
	member:bool PopulateAgents()
	{
		variable iterator i
		Config.AgentsRef:GetSettingIterator[i]

		if ${i:First(exists)}
		{		
			do
			{
				AgentQueue:Queue[${i.Value}]
			}
			while ${i:Next(exists)}
		}
	}
	
}

objectdef obj_CourierUI inherits obj_State
{
	variable index:being Agents

	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
	}
	
	method Start()
	{
		if ${This.IsIdle}
		{
			This:QueueState["Update", 5]
		}
	}
	
	method Stop()
	{
		This:Clear
	}
	
	method BuildAgentList()
	{
		EVE:GetAgents[Agents]
	}
	
	method BuildAgentsList()
	{
		variable iterator i
		Courier.Config.AgentsRef:GetSettingIterator[i]

		UIElement[Agents@AgentFrame@Courier@ComBot_Courier]:ClearItems
		if ${i:First(exists)}
		{		
			do
			{
				UIElement[Agents@AgentFrame@Courier@ComBot_Courier]:AddItem[${i.Key}]
			}
			while ${i:Next(exists)}
		}	
	}
	
	method UpdateAgentList()
	{
		variable iterator AgentIterator
		Agents:GetIterator[AgentIterator]
		
		UIElement[AgentList@AgentFrame@Courier@ComBot_Courier]:ClearItems
		if ${AgentIterator:First(exists)}
			do
			{	
				if ${UIElement[Agent@AgentFrame@Courier@ComBot_Courier@ComBot_Courier].Text.Length}
				{
					if ${AgentIterator.Value.Name.Find[${UIElement[Agent@AgentFrame@Courier@ComBot_Courier@ComBot_Courier].Text}]}
						UIElement[AgentList@AgentFrame@Courier@ComBot_Courier]:AddItem[${AgentIterator.Value.Name}]
				}
				else
				{
					UIElement[AgentList@AgentFrame@Courier@ComBot_Courier]:AddItem[${AgentIterator.Value.Name}]
				}
			}
			while ${AgentIterator:Next(exists)}
	}
	
	member:bool Update()
	{

	}

}