objectdef obj_HangerSale inherits obj_State
{
	method Initialize()
	{
		This[parent]:Initialize
		;This:AssignStateQueueDisplay[obj_SalvageStateList@Salvager@ComBotTab@ComBot]
		UI:Update["obj_HangerSale", "Initialized", "g"]
	}
	
	method Start()
	{
		UI:Update["obj_HangerSale", "Started", "g"]
		if ${This.IsIdle}
		{
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold", 5000]
		}
	}
	
	member:bool OpenCargoHold()
	{
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["obj_Miner", "Opening inventory", "g"]
			MyShip:OpenCargo[]
		}
		return TRUE
	}
	
	member:bool CheckCargoHold()
	{
		variable index:item HangerItems
		variable iterator HangerIterator
		Me:GetHangarItems[HangerItems]
		HangerItems:GetIterator[HangerIterator]
		if ${HangerIterator:First(exists)}
		{
			do
			{
				echo ${HangerIterator.Value.Name}
			}
			while ${HangerIterator:Next(exists)}
		}
		return TRUE
	}
	
}