objectdef obj_MissionData
{
	variable string Type
	variable int Frequency
	variable string Args

	method Initialize(string arg_Name, int arg_Frequency, string arg_Args)
	{
		Name:Set[${arg_Name}]
		Frequency:Set[${arg_Frequency}]
		Args:Set["${arg_Args.Escape}"]
	}
	
	method Set(string arg_Name, int arg_Frequency, string arg_Args)
	{
		Name:Set[${arg_Name}]
		Frequency:Set[${arg_Frequency}]
		Args:Set["${arg_Args.Escape}"]
	}
}



objectdef obj_Agents inherits obj_State
{
	method Initialize()
	{
		This[parent]:Initialize
		UI:Update["obj_Agents", "Initialized", "g"]
		This.NonGameTiedPulse:Set[TRUE]
		
		This:QueueState["CheckJournal"]
	}

	member:bool CheckJournal()
	{
		variable index:agentmission missions
		variable iterator mission
		
		EVE:GetAgentMissions[missions]
		missions:GetIterator[mission]
		if ${mission:First(exists)}
			do
			{
				echo ${mission.Value.Name} - ${mission.Value.Type} - ${mission.Value.State} - ${mission.Value.AgentID}
			}
			while ${mission:Next(exists)}
	}
	

}