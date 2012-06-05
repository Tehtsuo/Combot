objectdef obj_HangerSale inherits obj_State
{
	variable index:item HangerItems
	variable iterator HangerIterator
	variable collection:float MineralPrices
	variable collection:string MineralNames
	
	method Initialize()
	{
		This[parent]:Initialize
		;This:AssignStateQueueDisplay[obj_SalvageStateList@Salvager@ComBotTab@ComBot]
		PulseFrequency:Set[2000]
		UI:Update["obj_HangerSale", "Initialized", "g"]
	}
	
	method Start()
	{
		UI:Update["obj_HangerSale", "Started", "g"]
		if ${This.IsIdle}
		{
			MineralNames:Clear
			MineralNames:Set[34, "Tritanium"]
			MineralNames:Set[34, "Tritanium"]
			MineralNames:Set[35, "Pyerite"]
			MineralNames:Set[36, "Mexallon"]
			MineralNames:Set[37, "Isogen"]
			MineralNames:Set[38, "Nocxium"]
			MineralNames:Set[39, "Zydrine"]
			MineralNames:Set[40, "Megacyte"]
			RefineData:Load
			This:QueueState["OpenHanger"]
			This:QueueState["OpenMarket"]
			This:QueueState["GetMarket", 5000, "34"]
			This:QueueState["GetPrice", 5000, "34"]
			This:QueueState["GetMarket", 5000, "35"]
			This:QueueState["GetPrice", 5000, "35"]
			This:QueueState["GetMarket", 5000, "36"]
			This:QueueState["GetPrice", 5000, "36"]
			This:QueueState["GetMarket", 5000, "37"]
			This:QueueState["GetPrice", 5000, "37"]
			This:QueueState["GetMarket", 5000, "38"]
			This:QueueState["GetPrice", 5000, "38"]
			This:QueueState["GetMarket", 5000, "39"]
			This:QueueState["GetPrice", 5000, "39"]
			This:QueueState["GetMarket", 5000, "40"]
			This:QueueState["GetPrice", 5000, "40"]
			This:QueueState["CheckHanger"]
		}
	}
	
	member:bool OpenHanger()
	{
		if !${EVEWindow[ByName, "Item Hanger"](exists)}
		{
			UI:Update["obj_HangerSale", "Opening Item Hanger", "g"]
			EVE:Execute[OpenHangarFloor]
		}
		return TRUE
	}
	
	member:bool OpenMarket()
	{
		EVE:Execute[OpenMarket]
		return TRUE
	}
	
	member:bool GetMarket(int TypeID)
	{
		EVE:FetchMarketOrders[${TypeID}]
		return TRUE
	}
	
	member:bool GetPrice(int TypeID)
	{
		variable index:marketorder orders
		variable iterator orderIterator
		EVE:GetMarketOrders[orders, ${TypeID}, "buy"]
		orders:GetIterator[orderIterator]
		if ${orderIterator:First(exists)}
		{
			do
			{
				echo ${orderIterator.Value.Jumps}
				if ${orderIterator.Value.Jumps} <= ${orderIterator.Value.Range}
				{
					MineralPrices:Set[${TypeID}, ${orderIterator.Value.Price}]
					;echo ${orderIterator.Value.Jumps}
					;UI:Update["obj_HangerSale", "Best price for ${MineralNames[${TypeID}]} is ${orderIterator.Value.Price}", "g"]
					;return TRUE
				}
			}
			while ${orderIterator:Next(exists)}
		}
		return TRUE
	}
	
	member:bool CheckHanger()
	{
		HangerItems:Clear
		Me:GetHangarItems[HangerItems]
		HangerItems:GetIterator[HangerIterator]
		if ${HangerIterator:First(exists)}
		{
			This:QueueState["CheckItem"]
		}
		return TRUE
	}
	
	member:bool CheckItem()
	{
		echo ${HangerIterator.Value.Name}
		
		
		
		
		if ${HangerIterator:Next(exists)}
		{
			return FALSE
		}
		return TRUE
	}
	
}