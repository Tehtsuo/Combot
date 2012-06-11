objectdef obj_ItemInformation
{
	variable float Average
	variable float Max
	variable float Min
	variable float StdDev
	variable float Median
	variable float Percentile

	method Initialize(float arg_Average, float arg_Max, float arg_Min, float arg_StdDev, float arg_Median, float arg_Percentile)
	{
		Average:Set[${arg_Average}]
		Max:Set[${arg_Max}]
		Min:Set[${arg_Min}]
		StdDev:Set[${arg_StdDev}]
		Median:Set[${arg_Median}]
		Percentile:Set[${arg_Percentile}]
	
	}
	method Set(float arg_Average, float arg_Max, float arg_Min, float arg_StdDev, float arg_Median, float arg_Percentile)
	{
		Average:Set[${arg_Average}]
		Max:Set[${arg_Max}]
		Min:Set[${arg_Min}]
		StdDev:Set[${arg_StdDev}]
		Median:Set[${arg_Median}]
		Percentile:Set[${arg_Percentile}]
	
	}
}

objectdef obj_HangerSale inherits obj_State
{
	variable index:item HangerItems
	variable iterator HangerIterator
	variable collection:float MineralPrices
	variable collection:string MineralNames
	variable float LatestPrice
	variable float LowestSellPrice
	variable bool PriceGot = FALSE
	variable collection:float SellItems
	variable int CurrentSellOrders = 0
	
	variable collection:obj_ItemInformation Prices
	
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
		echo Fetching ${TypeID}
		This:InsertState["WaitForPrice", 100]
		return TRUE
	}
	
	method ParsePrice(int Size, string URL, string IPAddress, int ResponseCode, float TransferTime, string ResponseText, string ParsedBody)
	{
		if ${ResponseCode} >= 400
		{
			GetURL ${URL}
		}
		else
		{
			LatestPrice:Set[${ResponseText.Token[9,">"].Token[1,"<"]}]
			LowestSellPrice:Set[${ResponseText.Token[29,">"].Token[1,"<"]}]
			PriceGot:Set[TRUE]
		}
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
			This:QueueState["AddToSellIfAboveValue", 100]
			This:QueueState["CheckItem", 100]
		}
		return TRUE
	}
	
	member:bool CheckItem()
	{
		if ${HangerIterator:Next(exists)}
		{
			This:QueueState["FetchPrice", 100, ${HangerIterator.Value.TypeID}]
			This:QueueState["AddToSellIfAboveValue", 100]
			This:QueueState["CheckItem", 100]
		}
		else
		{
			This:QueueState["UpdateCurrentOrderCount"]
			This:QueueState["ProcessSells", 10000]
			UI:Update["obj_HangerSale", "Ready to sell ${SellItems.Used} item(s)", "g"]
		}
		return TRUE
	}
	
	member:bool AddToSellIfAboveValue()
	{
		variable index:marketorder orders
		variable iterator orderIterator
		variable int remainingQuantity
		variable float sellPrice
		variable float discount
		
		discount:Set[${Math.Calc[${LowestSellPrice}*0.01]}]
		if ${discount} > 1000
		{
			discount:Set[1000]
		}
		sellPrice:Set[${Math.Calc[${LowestSellPrice} - ${discount}]}]
		if ${This.GetItemValue[${HangerIterator.Value.TypeID}, ${HangerIterator.Value.PortionSize}]} < ${sellPrice}
		{
			SellItems:Set[${HangerIterator.Value.TypeID}, ${sellPrice}]
			UI:Update["obj_HangerSale", "Selling ${HangerIterator.Value.Name} for ${sellPrice}", "g"]
		}
		else
		{
			UI:Update["obj_HangerSale", "Not Selling ${HangerIterator.Value.Name}", "g"]
		}
		return TRUE
	}
	
	member:bool ProcessSells()
	{
		variable index:item ItemList
		variable iterator ItemIterator
		variable int SellItem
		echo ${CurrentSellOrders} >= ${This.MaxOrders}
		
		if ${CurrentSellOrders} >= ${This.MaxOrders}
		{
			return TRUE
		}
		
		SellItem:Set[${This.GetHighestSell}]
		
		UI:Update["obj_HangerSale", "Trying to sell ${SellItem} for ${SellItems.Element[${SellItem}]}", "g"]
		Me:GetHangarItems[ItemList]
		ItemList:GetIterator[ItemIterator]
		if ${ItemIterator:First(exists)}
		{
			do
			{
				if ${ItemIterator.Value.TypeID} == ${SellItem}
				{
					ItemIterator.Value:PlaceSellOrder[${SellItems.Element[${SellItem}]}, ${ItemIterator.Value.Quantity}, 1]
					CurrentSellOrders:Inc
					SellItems:Erase[${SellItem}]
					return FALSE
				}
			}
			while ${ItemIterator:Next(exists)}
		}
		return TRUE
	}
	
	member:int GetHighestSell()
	{
		variable iterator SellIterator
		variable float HighestPrice = 0
		variable int HighestKey = -1
		
		SellItems:GetIterator[SellIterator]
		
		if ${SellIterator:First(exists)}
		{
			do
			{
				if ${SellIterator.Value} > ${HighestPrice}
				{
					HighestPrice:Set[${SellIterator.Value}]
					HighestKey:Set[${SellIterator.Key}]
				}
			}
			while ${SellIterator:Next(exists)}
		}
		return ${HighestKey}
	}
	
	member:int MaxOrders()
	{
		variable int OrderMax = 5
		OrderMax:Inc[${Math.Calc[${Me.Skill[Trade].Level}*4]}]
		OrderMax:Inc[${Math.Calc[${Me.Skill[Retail].Level}*8]}]
		OrderMax:Inc[${Math.Calc[${Me.Skill[Wholesale].Level}*16]}]
		OrderMax:Inc[${Math.Calc[${Me.Skill[Tycoon].Level}*32]}]
		
		return ${OrderMax}
	}
	
	member:bool UpdateCurrentOrderCount()
	{
		Me:UpdateMyOrders
		This:InsertState["FetchCurrentOrderCount"]
		return TRUE
	}
	
	member:bool FetchCurrentOrderCount()
	{
		variable index:myorder OrderIndex
		if ${Me:GetMyOrders[OrderIndex]}
		{
			CurrentSellOrders:Set[${OrderIndex.Used}]
			UI:Update["obj_HangerSale", "${CurrentSellOrders} current sell orders out of ${This.MaxOrders}", "g"]
			return TRUE
		}
		return FALSE
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
	
	method GetPrices(string XMLString)
	{
		variable int typeID
		variable float avg
		variable float max
		variable float min
		variable float stddev
		variable float median
		variable float percentile
		do
		{
			XMLString:Set[${XMLString.Right[${Math.Calc[-${XMLString.Find[<type id=]}-9]}].Escape}]
			typeID:Set[${XMLString.Left[${Math.Calc[${XMLString.Find[\"]}-1]}]}]
			XMLString:Set[${XMLString.Right[${Math.Calc[-${XMLString.Find[<avg>]}-4]}].Escape}]
			avg:Set[${XMLString.Left[${Math.Calc[${XMLString.Find[<]}-1]}]}]
			XMLString:Set[${XMLString.Right[${Math.Calc[-${XMLString.Find[<max>]}-4]}].Escape}]
			max:Set[${XMLString.Left[${Math.Calc[${XMLString.Find[<]}-1]}]}]
			XMLString:Set[${XMLString.Right[${Math.Calc[-${XMLString.Find[<min>]}-4]}].Escape}]
			min:Set[${XMLString.Left[${Math.Calc[${XMLString.Find[<]}-1]}]}]
			XMLString:Set[${XMLString.Right[${Math.Calc[-${XMLString.Find[<stddev>]}-7]}].Escape}]
			stddev:Set[${XMLString.Left[${Math.Calc[${XMLString.Find[<]}-1]}]}]
			XMLString:Set[${XMLString.Right[${Math.Calc[-${XMLString.Find[<median>]}-7]}].Escape}]
			median:Set[${XMLString.Left[${Math.Calc[${XMLString.Find[<]}-1]}]}]
			XMLString:Set[${XMLString.Right[${Math.Calc[-${XMLString.Find[<percentile>]}-11]}].Escape}]
			percentile:Set[${XMLString.Left[${Math.Calc[${XMLString.Find[<]}-1]}]}]

			Prices:Set[${typeID}, ${avg}, ${max}, ${min}, ${stddev}, ${median}, ${percentile}]
		}
		while ${XMLString.Find[<type id=](exists)}
	}
}