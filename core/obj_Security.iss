
objectdef obj_Security inherits obj_State
{
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		UI:Update["obj_Security", "Initialized", "g"]
		
		This:QueueState["CheckSafe", 500]
	}

	
	member:bool CheckSafe()
	{
		variable index:pilot Pilots
		variable iterator Pilot_Iterator

		EVE:GetLocalPilots[Pilots]
		Pilots:GetIterator[Pilot_Iterator]
		
		if ${Pilot_Iterator:First(exists)}
		do
		{
		
			if ${Config.Security.MeToPilot} && ${Pilot_Iterator.Value.Standing.MeToPilot} < ${Config.Security.MeToPilot_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Name}(pilot) is ${Pilot_Iterator.Value.Standing.MeToPilot} standing to you"]
				return TRUE
			}
			if ${Config.Security.MeToCorp} && ${Pilot_Iterator.Value.Standing.MeToCorp} < ${Config.Security.MeToCorp_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Corp.Name}(corp) is ${Pilot_Iterator.Value.Standing.MeToCorp} standing to you"]
				return TRUE
			}
			if ${Config.Security.MeToAlliance} && ${Pilot_Iterator.Value.Standing.MeToAlliance} < ${Config.Security.MeToAlliance_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Alliance.Name}(alliance) is ${Pilot_Iterator.Value.Standing.MeToAlliance} standing to you"]
				return TRUE
			}
			if ${Config.Security.CorpToPilot} && ${Pilot_Iterator.Value.Standing.CorpToPilot} < ${Config.Security.CorpToPilot_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Name}(pilot) is ${Pilot_Iterator.Value.Standing.CorpToPilot} standing to your corporation"]
				return TRUE
			}
			if ${Config.Security.CorpToCorp} && ${Pilot_Iterator.Value.Standing.CorpToCorp} < ${Config.Security.CorpToCorp_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Corp.Name}(corp) is ${Pilot_Iterator.Value.Standing.CorpToCorp} standing to your corporation"]
				return TRUE
			}
			if ${Config.Security.CorpToAlliance} && ${Pilot_Iterator.Value.Standing.CorpToAlliance} < ${Config.Security.CorpToAlliance_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Alliance.Name}(alliance) is ${Pilot_Iterator.Value.Standing.CorpToAlliance} standing to your corporation"]
				return TRUE
			}
			if ${Config.Security.AllianceToPilot} && ${Pilot_Iterator.Value.Standing.AllianceToPilot} < ${Config.Security.AllianceToPilot_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Name}(pilot) is ${Pilot_Iterator.Value.Standing.AllianceToPilot} standing to your alliance"]
				return TRUE
			}
			if ${Config.Security.AllianceToCorp} && ${Pilot_Iterator.Value.Standing.AllianceToCorp} < ${Config.Security.AllianceToCorp_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Corp.Name}(corp) is ${Pilot_Iterator.Value.Standing.AllianceToCorp} standing to your alliance"]
				return TRUE
			}
			if ${Config.Security.AllianceToAlliance} && ${Pilot_Iterator.Value.Standing.AllianceToAlliance} < ${Config.Security.AllianceToAlliance_Value}
			{
				This:QueueState["Flee", 500, "${Pilot_Iterator.Value.Alliance.Name}(alliance) is ${Pilot_Iterator.Value.Standing.AllianceToAlliance} standing to your alliance"]
				return TRUE
			}
			
		}
		while ${Pilot_Iterator:Next(exists)}
		
		return FALSE
	}
	
	member:bool Flee(string Message)
	{
		UI:Update["obj_Security", "Flee triggered!", "r"]
		UI:Update["obj_Security", "${Message}", "r"]

		if ${Config.Security.OverrideFleeBookmark_Enabled}
		{
			Move:Bookmark[${Config.Security.OverrideFleeBookmark}]
			This:QueueState["Traveling"]
		}
		else
		{
			switch ${Config.Common.ComBot_Mode}
			{
				case Dedicated Salvager
					Move:Bookmark[${Config.Salvager.Salvager_Dropoff}]
					This:QueueState["Traveling"]
					break
				case Miner
					Move:Bookmark[${Config.Miner.Miner_Dropoff}]
					This:QueueState["Traveling"]
					break
			}
		}

		if ${Config.Security.FleeWaitTime_Enabled}
		{
			This:QueueState["Log", "Waiting for ${Config.Security.FleeWaitTime} minutes after flee"]
			This:QueueState["Idle", ${Math.Calc[${Config.Security.FleeWaitTime} * 60000]}]
		}

		This:QueueState["CheckSafe", 500]
		return TRUE
	}
	
	member:bool Log(string text)
	{
		UI:Update["obj_Security", "${text}", "g"]
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
	
}
