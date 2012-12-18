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

	member:settingsetref AgentsTimeoutRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}].FindSet[AgentsTimeout]}
	}
	

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.CommonRef:AddSet[Agents]
		This.CommonRef:AddSet[AgentsTimeout]
		
		This.CommonRef:AddSetting[AvoidLowSec,TRUE]
	}
	
	Setting(bool, AvoidLowSec, SetAvoidLowSec)	

}

objectdef obj_Courier inherits obj_State
{
	variable obj_Configuration_Courier Config
	variable obj_CourierUI LocalUI
	
	variable queue:int64 AgentQueue
	variable collection:time AgentTimeout

	method Initialize()
	{
		This[parent]:Initialize
		DynamicAddBehavior("Courier", "Courier Missions")
	}

	method Start()
	{
		UI:Update["Courier", "Started", "g"]
		This:AssignStateQueueDisplay[DebugStateList@Debug@ComBotTab@ComBot]
		
		if ${This.IsIdle}
		{
			This:QueueState["CheckForWork"]
		}
	}
	
	method Stop()
	{
		This:DeactivateStateQueueDisplay
		This:Clear
	}
	
	member:bool CheckForWork()
	{
		if !${EVEWindow[journal](exists)}
		{
			EVE:Execute[OpenJournal]
			return FALSE
		}
		if !${EVEWindow[addressbook](exists)}
		{
			EVE:Execute[OpenPeopleAndPlaces]
			return FALSE
		}
		
		variable index:agentmission Missions
		variable index:bookmark Bookmarks
		variable iterator m
		variable iterator b
		variable int64 Pickup
		variable int64 Dropoff
		variable int64 Home
		EVE:GetAgentMissions[Missions]
		Missions:GetIterator[m]
		
		if ${m:First(exists)}
			do
			{
				if !${m.Value.Type.Find[Courier]}
				{
					continue
				}
				PickupFound:Set[0]
				DropoffFound:Set[0]
				m.Value:GetBookmarks[Bookmarks]
				Bookmarks:GetIterator[b]
				if ${b:First(exists)}
					do
					{	
						if ${b.Value.Label.Find[Pick Up]}
						{
							Pickup:Set[${b.Value.ItemID}]
						}
						if ${b.Value.Label.Find[Drop Off]}
						{
							Dropoff:Set[${b.Value.ItemID}]
						}
						if ${b.Value.Label.Find[Home]}
						{
							Home:Set[${b.Value.ItemID}]
						}
					}
					while ${b:Next(exists)}
				if ${Pickup} && ${Dropoff}
				{
					break
				}
			}
			while ${m:Next(exists)}

		if (!${Pickup} || !${Dropoff}) || !${m.Value.Type.Find[Courier]}
		{
			if !${AgentQueue.Used}
			{
				This:PopulateAgents
			}
			UI:Update["Courier", "No active missions found", "o"]

			if ${m:First(exists)}
				do
				{
					if ${m.Value.AgentID} == ${Agent[${AgentQueue.Peek}].ID}
					{
						if !${m.Value.Type.Find[Courier]}
						{
							This:PopulateAgentTimeout
							if ${AgentTimeout.Element[${AgentQueue.Peek}].Timestamp} >= ${Time.Timestamp}
							{
								UI:Update["Courier", "${Agent[${AgentQueue.Peek}].Name}\ao is on cooldown, skipping", "o"]
								AgentQueue:Dequeue
								return FALSE
							}
							else
							{
								UI:Update["Courier", "Declining mission from \ao${Agent[${AgentQueue.Peek}].Name}", "g"]
								This:InsertState["CheckForWork"]
								This:InsertState["InteractAgent", 1500, "${AgentQueue.Peek}, DECLINE"]
								return TRUE
							}
						}
						if ${m.Value.State} == 1
						{
							UI:Update["Courier", "Accepting mission from \ao${Agent[${AgentQueue.Peek}].Name}", "g"]
							This:InsertState["CheckForWork"]
							This:InsertState["InteractAgent", 1500, "${AgentQueue.Peek}, ACCEPT"]
							return TRUE
						}
					}
				}
				while ${m:Next(exists)}
			
			
			UI:Update["Courier", "Checking \ao${Agent[${AgentQueue.Peek}].Name}\ag for new mission", "g"]
			This:InsertState["CheckForWork"]
			This:InsertState["InteractAgent", 1500, "${AgentQueue.Peek}, OFFER"]
			return TRUE
			
		}
			
		if !${EVEWindow[AgentBrowser](exists)}
		{
			m.Value:GetDetails
			return FALSE
		}
	
		variable int64 TypeID = ${EVEWindow[AgentBrowser].HTML.Right[-${Math.Calc[${EVEWindow[AgentBrowser].HTML.Find[typeicon:]} + 8]}].Token[1,\"]}
		if ${EVEWindow[AgentBrowser].HTML.Find["(Low Sec Warning!)"]} || ${EVEWindow[AgentBrowser].HTML.Find["(The route generated by current autopilot settings contains low security systems!)"]}
		{
			UI:Update["Courier", "Declining Low-Sec mission", "g"]
			This:InsertState["CheckForWork"]
			This:InsertState["InteractAgent", 1500, "${AgentQueue.Peek}, DECLINE"]
			return TRUE
		}

		if !${Client.Inventory}
		{
			return FALSE
		}
		
		
		if ${Me.InStation}
		{
			Cargo:PopulateCargoList[Personal Hangar]
			Cargo:Filter[TypeID == ${TypeID}]
			
			if ${Cargo.CargoList.Used} && ${Dropoff} == ${Me.StationID}
			{
				UI:Update["Courier", "Cargo \ao${Cargo.CargoList.Get[1].Name}\ag is in dropoff station", "g"]
				This:QueueState["CompleteMission", 1500, "${m.Value.AgentID}, ${Home}, ${m.Value.RemoteCompletable}"]
				This:QueueState["CheckForWork"]
				return TRUE		
			}
		}
		
		Cargo:PopulateCargoList[Ship]
		Cargo:Filter[TypeID == ${TypeID}]
		
		UI:Update["Courier", "Mission in progress: \ao${m.Value.Name}", "g"]
		if ${Cargo.CargoList.Used}
		{
			UI:Update["Courier", "Cargo \ao${Cargo.CargoList.Get[1].Name} \agis already on-board", "g"]
			UI:Update["Courier", "Proceeding to dropoff", "g"]
			Cargo:At[${Dropoff}]:Unload[TypeID == ${TypeID}]
			This:QueueState["Traveling"]
			This:QueueState["CompleteMission", 1500, "${m.Value.AgentID}, ${Home}, ${m.Value.RemoteCompletable}"]
			This:QueueState["CheckForWork"]
		}
		else
		{
			UI:Update["Courier", "Cargo not on-board, proceeding to pickup", "g"]
			Cargo:At[${Pickup}]:Load[TypeID == ${TypeID}]:At[${Dropoff}]:Unload[TypeID == ${TypeID}]
			This:QueueState["Traveling"]
			This:QueueState["CompleteMission", 1500, "${m.Value.AgentID}, ${Home}, ${m.Value.RemoteCompletable}"]
			This:QueueState["CheckForWork"]
		}

		
		return TRUE
	}
	
	member:bool Cleanup()
	{
		if ${EVEWindow[journal](exists)}
		{
			EVEWindow[journal]:Close
			return FALSE
		}
		if ${EVEWindow[addressbook](exists)}
		{
			EVEWindow[addressbook]:Close
			return FALSE
		}
		if ${EVEWindow[byCaption, Agent Conversation](exists)}
		{
			EVEWindow[byCaption, Agent Conversation]:Close
			return FALSE
		}
		return TRUE
	}
	
	member:bool InteractAgent(int64 AgentIndex, string Action)
	{
		variable index:dialogstring DialogStrings
		variable iterator i

		switch ${Action} 
		{
			case OFFER
				echo ${AgentID} -  ${Me.StationID} != ${Agent[${AgentIndex}].StationID}
				if ${Me.StationID} != ${Agent[${AgentIndex}].StationID}
				{
					Move:Bookmark[${Agent[${AgentIndex}].StationID}]
					This:InsertState["InteractAgent", 1500, "${AgentIndex}, ${Action}]
					This:InsertState["Traveling"]
					return TRUE
				}
				if !${EVEWindow[agentinteraction_${Agent[${AgentIndex}].ID}](exists)}
				{
					Agent[${AgentIndex}]:StartConversation
				}
				
				break
			case ACCEPT
				if ${Me.StationID} != ${Agent[${AgentIndex}].StationID}
				{
					Move:Bookmark[${Agent[${AgentIndex}].StationID}]
					This:InsertState["InteractAgent", 1500, "${AgentIndex}, ${Action}]
					This:InsertState["Traveling"]
					return TRUE
				}
				if !${EVEWindow[agentinteraction_${Agent[${AgentIndex}].ID}](exists)}
				{
					Agent[${AgentIndex}]:StartConversation
					return FALSE
				}
				Agent[${AgentIndex}]:GetDialogResponses[DialogStrings]
				if !${DialogStrings.Used}
				{
					return FALSE
				}
				DialogStrings:GetIterator[i]
				
				if ${i:First(exists)}
					do
					{
						if ${i.Value.Text.Find[Accept]}
						{
							i.Value:Say[${Agent[${AgentIndex}].ID}]
							break
						}
					}
					while ${i:Next(exists)}
				
				break
			case DECLINE
				if !${EVEWindow[agentinteraction_${Agent[${AgentIndex}].ID}](exists)}
				{
					Agent[id, ${AgentID}]:StartConversation
					return FALSE
				}
				Agent[${AgentIndex}]:GetDialogResponses[DialogStrings]
				if !${DialogStrings.Used}
				{
					return FALSE
				}
				DialogStrings:GetIterator[i]
				
				Config.AgentsTimeoutRef:AddSetting[${Agent[${AgentIndex}].ID},${Time}]										
				
				if ${i:First(exists)}
					do
					{
						if ${i.Value.Text.Find[Decline]}
						{
							i.Value:Say[${Agent[${AgentIndex}].ID}]
							break
						}
					}
					while ${i:Next(exists)}
				
				break
		}
		This:InsertState["Cleanup"]
		return TRUE
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

	member:bool CompleteMission(int64 AgentID, int64 Home, bool RemoteComplete)
	{
		; if ${Me.StationID} != ${Agent[${AgentIndex}].StationID} && !${RemoteComplete}
		; {
			; UI:Update["Courier", "Need to be at agent station to complete mission", "g"]
			; UI:Update["Courier", "Setting course for \ao${EVE.Station[${Home}].Name}", "g"]
			; Move:Bookmark[${Home}]
			; This:InsertState["CompleteMission", 1500, "${AgentID}, ${Home}, ${AgentIndex}"]
			; This:InsertState["Traveling"]
			; return TRUE
		; }
		
		if !${EVEWindow[agentinteraction_${AgentID}](exists)}
		{
			Agent[id, ${AgentID}]:StartConversation
			return FALSE
		}

		variable index:dialogstring DialogStrings
		variable iterator i
		Agent[id, ${AgentID}]:GetDialogResponses[DialogStrings]
		if !${DialogStrings.Used}
		{
			return FALSE
		}
		DialogStrings:GetIterator[i]
		
		if ${i:First(exists)}
			do
			{
				if ${i.Value.Text.Find[CompleteMission]}
				{
					i.Value:Say[${AgentID}]
					break
				}
			}
			while ${i:Next(exists)}

		This:InsertState["Cleanup"]
		return TRUE
	}
	
	
	method PopulateAgents()
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

	method PopulateAgentTimeout()
	{
		variable iterator i
		Config.AgentsRef:GetSettingIterator[i]

		AgentTimeout:Clear
		if ${i:First(exists)}
		{		
			do
			{
				AgentTimeout:Set[${i.Key},${i.Value}]
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
				if ${UIElement[Agent@AgentFrame@Courier@ComBot_Courier].Text.Length}
				{
					if ${AgentIterator.Value.Name.Find[${UIElement[Agent@AgentFrame@Courier@ComBot_Courier].Text}]}
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