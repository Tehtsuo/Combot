objectdef obj_HangerSale inherits obj_State
{
	variable index:item HangerItems
	variable iterator HangerIterator
	variable collection:float Prices
	variable collection:string MineralNames
	
	variable float ProfitOverReprocess=0
	
	method Initialize()
	{
		This[parent]:Initialize
		This:AssignStateQueueDisplay[obj_HangerSaleStateList@Hangar_Sale@ComBotTab@ComBot]
		PulseFrequency:Set[1000]
		UI:Update["obj_HangerSale", "Initialized", "g"]
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
			This:QueueState["OpenMarket"]
			This:QueueState["FetchPrice", 1000, "34"]
			This:QueueState["FetchPrice", 1000, "35"]
			This:QueueState["FetchPrice", 1000, "36"]
			This:QueueState["FetchPrice", 1000, "37"]
			This:QueueState["FetchPrice", 1000, "38"]
			This:QueueState["FetchPrice", 1000, "39"]
			This:QueueState["FetchPrice", 1000, "40"]
			
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
			This:QueueState["GetMarket", 1000, ${HangerIterator.Value.TypeID}]
			This:QueueState["SellIfAboveValue", 2000]
			This:QueueState["CheckItem"]
		}
		return TRUE
	}
	
	member:bool CheckItem()
	{
		if ${HangerIterator:Next(exists)}
		{
			This:QueueState["GetMarket", 1000, ${HangerIterator.Value.TypeID}]
			This:QueueState["SellIfAboveValue", 1000]
			This:QueueState["CheckItem", 1000]
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
		
		EVE:GetMarketOrders[orders, ${HangerIterator.Value.TypeID}, "buy"]
		orders:GetIterator[orderIterator]
		
		itemValue:Set[${This.GetItemValue[${HangerIterator.Value.TypeID}, ${HangerIterator.Value.PortionSize}]}]
		remainingQuantity:Set[${HangerIterator.Value.Quantity}]
		
		UI:Update["obj_HangerSale", "Raw Value for ${HangerIterator.Value.Name} is ${itemValue}", "g"]
		
		if ${orderIterator:First(exists)}
		{
			do
			{
				if ${orderIterator.Value.Price} < ${itemValue}
				{
					UI:Update["obj_HangerSale", "None left above raw value", "g"]
					UIElement[obj_HangerSaleList@Hangar_Sale@ComBotTab@ComBot].ItemByText["${orderIterator.Value.Name}"]:Remove
					return TRUE
				}
				if ${orderIterator.Value.Jumps} <= ${orderIterator.Value.Range}
				{
					if ${orderIterator.Value.MinQuantityToBuy} <= ${remainingQuantity}
					{
						UI:Update["obj_HangerSale", "Better then Value - ${orderIterator.Value.Price}", "g"]
						if ${orderIterator.Value.QuantityRemaining} >= ${remainingQuantity}
						{
							This:InsertState["PlaceSellOrder", 1000, "${orderIterator.Value.Price}, ${remainingQuantity}"]
							UI:Update["obj_HangerSale", "None left above raw value", "g"]
							ProfitOverReprocess:Inc[${Math.Calc[${remainingQuantity} * (${orderIterator.Value.Price} - ${itemValue})]}]
							UIElement[obj_HangerSaleList@Hangar_Sale@ComBotTab@ComBot].ItemByText["${orderIterator.Value.Name}"]:Remove
							return TRUE
						}
						else
						{
							remainingQuantity:Dec[${orderIterator.Value.QuantityRemaining}]
							This:InsertState["PlaceSellOrder", 1000, "${orderIterator.Value.Price}, ${orderIterator.Value.QuantityRemaining}"]
							ProfitOverReprocess:Inc[${Math.Calc[${orderIterator.Value.QuantityRemaining} * (${orderIterator.Value.Price} - ${itemValue})]}]
						}
					}
				}
			}
			while ${orderIterator:Next(exists)}
		}
		UI:Update["obj_HangerSale", "None left above raw value", "g"]
		UIElement[obj_HangerSaleList@Hangar_Sale@ComBotTab@ComBot].ItemByText["${orderIterator.Value.Name}"]:Remove
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