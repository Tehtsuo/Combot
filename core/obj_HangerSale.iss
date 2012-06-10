objectdef obj_HangerSale inherits obj_State
{
	variable index:item HangerItems
	variable iterator HangerIterator
	variable collection:float MineralPrices
	variable collection:string MineralNames
	variable float LatestPrice
	variable bool PriceGot = FALSE
	
	variable float ProfitOverReprocess=0
	
	method Initialize()
	{
		This[parent]:Initialize
		This:AssignStateQueueDisplay[obj_HangerSaleStateList@Hangar_Sale@ComBotTab@ComBot]
		PulseFrequency:Set[1000]
		UI:Update["obj_HangerSale", "Initialized", "g"]
		Event[isxGames_onHTTPResponse]:AttachAtom[This:ParsePrice]
	}
	
	method Start()
	{
		UI:Update["obj_HangerSale", "Started", "g"]
		if ${This.IsIdle}
		{
			MineralNames:Clear
			MineralNames:Set[34, "Tritanium"]
			MineralNames:Set[35, "Pyerite"]
			MineralNames:Set[36, "Mexallon"]
			MineralNames:Set[37, "Isogen"]
			MineralNames:Set[38, "Nocxium"]
			MineralNames:Set[39, "Zydrine"]
			MineralNames:Set[40, "Megacyte"]
			RefineData:Load
			This:QueueState["OpenHanger"]
			This:QueueState["FetchPrice", 100, "34"]
			This:QueueState["SavePrice", 100, "34"]
			This:QueueState["FetchPrice", 100, "35"]
			This:QueueState["SavePrice", 100, "35"]
			This:QueueState["FetchPrice", 100, "36"]
			This:QueueState["SavePrice", 100, "36"]
			This:QueueState["FetchPrice", 100, "37"]
			This:QueueState["SavePrice", 100, "37"]
			This:QueueState["FetchPrice", 100, "38"]
			This:QueueState["SavePrice", 100, "38"]
			This:QueueState["FetchPrice", 100, "39"]
			This:QueueState["SavePrice", 100, "39"]
			This:QueueState["FetchPrice", 100, "40"]
			This:QueueState["SavePrice", 100, "40"]
			This:QueueState["CheckHanger"]
		}
	}
	
	member:bool OpenHanger()
	{
		if !${EVEWindow[ByName, "Inventory"](exists)}
		{
			UI:Update["obj_HangerSale", "Making sure inventory is open", "g"]
			MyShip:OpenCargo
			return FALSE
		}
		if !${EVEWindow[byCaption, "Item Hangar"](exists)}
		{
			EVEWindow[byName,"Inventory"]:MakeChildActive[StationItems]
		}
		return TRUE
	}
	
;	Jita = 30000142
	
	member:bool FetchPrice(int TypeID)
	{
		GetURL http://api.eve-central.com/api/marketstat?typeid=${TypeID}&usesystem=30000142
		This:InsertState["WaitForPrice", 100]
		return TRUE
	}
	
	method ParsePrice(int Size, string URL, string IPAddress, int ResponseCode, float TransferTime, string ResponseText, string ParsedBody)
	{
		LatestPrice:Set[${ResponseText.Token[9,">"].Token[1,"<"]}]
		PriceGot:Set[TRUE]
	}
	
	member:bool WaitForPrice()
	{
		if ${PriceGot}
		{
			PriceGot:Set[FALSE]
			return TRUE
		}
		return FALSE
	}
	
	member:bool SavePrice(int TypeID)
	{
		MineralPrices:Set[${TypeID}, ${LatestPrice}]
		UI:Update["obj_HangerSale", "Good price for ${MineralNames[${TypeID}]} is ${LatestPrice}", "g"]
		return TRUE
	}
	
	member:bool CheckHanger()
	{
		variable index:item ListIndex
		variable iterator ListIterator
		Me:GetHangarItems[ListIndex]
		ListIndex:GetIterator[ListIterator]
		if ${ListIterator:First(exists)}
		do
		{
				UIElement[obj_HangerSaleList@Hangar_Sale@ComBotTab@ComBot]:AddItem[${ListIterator.Value.Name}]
		}
		while ${ListIterator:Next(exists)}
			
		
	
		HangerItems:Clear
		Me:GetHangarItems[HangerItems]
		HangerItems:GetIterator[HangerIterator]
		if ${HangerIterator:First(exists)}
		{
			This:QueueState["FetchPrice", 100, ${HangerIterator.Value.TypeID}]
			This:QueueState["SellIfAboveValue", 100]
			This:QueueState["CheckItem", 100]
		}
		return TRUE
	}
	
	member:bool CheckItem()
	{
		if ${HangerIterator:Next(exists)}
		{
			This:QueueState["FetchPrice", 100, ${HangerIterator.Value.TypeID}]
			This:QueueState["SellIfAboveValue", 100]
			This:QueueState["CheckItem", 100]
		}
		else
		{
			UI:Update["obj_HangerSale", "Selling Done, Profit over Reprocessing is ${ProfitOverReprocess}", "g"]
		}
		return TRUE
	}
	
	member:bool SellIfAboveValue()
	{
		variable index:marketorder orders
		variable iterator orderIterator
		variable int remainingQuantity
		variable float itemValue
		
		if ${This.GetItemValue[${HangerIterator.Value.TypeID}, ${HangerIterator.Value.PortionSize}]} < ${LatestPrice}
		{
			UI:Update["obj_HangerSale", "Sell ${HangerIterator.Value.Name} - RAW ${This.GetItemValue[${HangerIterator.Value.TypeID}, ${HangerIterator.Value.PortionSize}]} - MARKET ${LatestPrice}", "g"]
		}
		else
		{
			UI:Update["obj_HangerSale", "Don't Sell ${HangerIterator.Value.Name} - RAW ${This.GetItemValue[${HangerIterator.Value.TypeID}, ${HangerIterator.Value.PortionSize}]} - MARKET ${LatestPrice}", "g"]
		}
		
		return TRUE
		
	}
	
	member:float GetItemValue(int TypeID, int PortionSize)
	{
		variable float ItemValue=0
		
		ItemValue:Inc[${Math.Calc[${RefineData.Tritanium[${TypeID}]} * ${This.GetRefineLoss} * ${MineralPrices["34"]}]}]
		ItemValue:Inc[${Math.Calc[${RefineData.Pyerite[${TypeID}]} * ${This.GetRefineLoss} * ${MineralPrices["35"]}]}]
		ItemValue:Inc[${Math.Calc[${RefineData.Mexallon[${TypeID}]} * ${This.GetRefineLoss} * ${MineralPrices["36"]}]}]
		ItemValue:Inc[${Math.Calc[${RefineData.Isogen[${TypeID}]} * ${This.GetRefineLoss} * ${MineralPrices["37"]}]}]
		ItemValue:Inc[${Math.Calc[${RefineData.Nocxium[${TypeID}]} * ${This.GetRefineLoss} * ${MineralPrices["38"]}]}]
		ItemValue:Inc[${Math.Calc[${RefineData.Zydrine[${TypeID}]} * ${This.GetRefineLoss} * ${MineralPrices["39"]}]}]
		ItemValue:Inc[${Math.Calc[${RefineData.Megacyte[${TypeID}]} * ${This.GetRefineLoss} * ${MineralPrices["40"]}]}]
		echo ${ItemValue}
		return ${Math.Calc[${ItemValue} / ${PortionSize}]}
	}
	
	member:float GetRefineLoss()
	{
		return 0.995
		
	}
	
}