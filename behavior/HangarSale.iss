/*

ComBot  Copyright © 2012  Tehtsuo and Vendan

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

objectdef obj_Configuration_HangarSale
{
	variable string SetName = "HangarSale"

	method Initialize()
	{
		if !${BaseConfig.BaseRef.FindSet[${This.SetName}](exists)}
		{
			UI:Update["Configuration", " ${This.SetName} settings missing - initializing", "o"]
			This:Set_Default_Values[]
		}
		UI:Update["Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	member:settingsetref CommonRef()
	{
		return ${BaseConfig.BaseRef.FindSet[${This.SetName}]}
	}

	method Set_Default_Values()
	{
		BaseConfig.BaseRef:AddSet[${This.SetName}]

		This.CommonRef:AddSetting[PriceMode,Undercut Lowest]
		This.CommonRef:AddSetting[UndercutPercent,1]
		This.CommonRef:AddSetting[UndercutValue,1000]
		This.CommonRef:AddSetting[Duration,1]
	}
	
	Setting(string, SellSystem, SetSellSystem)
	Setting(string, PriceMode, SetPriceMode)
	Setting(int, UndercutPercent, SetUndercutPercent)
	Setting(int, UndercutValue, SetUndercutValue)
	Setting(int, Duration, SetDuration)
	Setting(bool, RePrice, SetRePrice)
	Setting(bool, Sell, SetSell)
	Setting(bool, MoveRefine, SetMoveRefine)
	Setting(bool, Logout, SetLogout)
	Setting(int64, MoveRefinesTarget, SetMoveRefinesTarget)
}

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

objectdef obj_HangarSale inherits obj_State
{
	variable obj_Configuration_HangarSale Config
	variable obj_HangarSaleUI LocalUI

	variable index:item HangarItems
	variable iterator HangarIterator
	variable collection:string MineralNames
	variable float LatestPrice
	variable float LowestSellPrice
	variable bool PriceGot = FALSE
	variable collection:float SellItems
	variable int CurrentSellOrders = 0
	variable string XMLString = ""
	variable index:myorder MyOrderIndex
	variable iterator MyOrderIterator
	variable int RemainingToProcess
	variable set MoveRefines
	
	variable float ToSellLowestTotal
	variable float ToSellAverageTotal
	variable float ToSellBuyoutTotal
	variable float ToRefineTotal
	
	
	variable collection:obj_ItemInformation BuyPrices
	variable collection:obj_ItemInformation SellPrices
	
	variable string CombinedXMLInput=""
	
	variable float ProfitOverReprocess=0
	
	variable string LogFile="./config/logs/${Me.Name}.log"

	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[1000]
		Event[isxGames_onHTTPResponse]:AttachAtom[This:ParsePrice]
		DynamicAddBehavior("HangarSale", "HangarSale")
	}
	
	method Start()
	{
		UI:Update["obj_HangarSale", "Started", "g"]
		Security:Stop
		This:AssignStateQueueDisplay[DebugStateList@Debug@ComBotTab@ComBot]
		if ${This.IsIdle}
		{
			RemainingToProcess:Set[7]
			MineralNames:Clear
			MineralNames:Set[34, "Tritanium"]
			MineralNames:Set[35, "Pyerite"]
			MineralNames:Set[36, "Mexallon"]
			MineralNames:Set[37, "Isogen"]
			MineralNames:Set[38, "Nocxium"]
			MineralNames:Set[39, "Zydrine"]
			MineralNames:Set[40, "Megacyte"]
			RefineData:Load
			UI:Update["obj_HangarSale", "Retrieving Mineral prices from EVE-Central API", "g"]
			This:QueueState["FetchPrice", 100, "34, 35"]
			This:QueueState["FetchPrice", 100, "36, 37"]
			This:QueueState["FetchPrice", 100, "38, 39"]
			This:QueueState["FetchPrice", 100, "40"]
			
			This:QueueState["UpdateCurrentOrderCount"]
			This:QueueState["CheckOrders"]
			This:QueueState["OpenHangar"]
			This:QueueState["CheckHangar"]
		}
	}
	
	method Stop()
	{
		This:DeactivateStateQueueDisplay
		This:Clear
	}	
	
	member:bool OpenHangar()
	{
		if !${Client.Inventory}
		{
			return FALSE
		}
		if !${EVEWindow[Inventory].ActiveChild.Name.Equal[StationItems]}
		{
			EVEWindow[Inventory].ChildWindow[${Me.Station.ID}, StationItems]:MakeActive
		}
		return TRUE
	}
	
;	Jita = 30000142
	
	member:bool FetchPrice(... TypeIDs)
	{
		variable iterator TypeIterator
		variable string TypeIDQuery = ""
		variable string Seperator = ""
		variable int TypeCount = 1
		variable int64 SystemID = 30000142
		
		TypeIDs:GetIterator[TypeIterator]

		for(${TypeCount}<=${TypeIDs.Used}; TypeCount:Inc)
		{
			TypeIDQuery:Concat["${Seperator}typeid=${TypeIDs[${TypeCount}]}"]
			Seperator:Set["&"]
		}
		
		if ${EVE.Bookmark[${Config.SellSystem}](exists)}
		{
			SystemID:Set[${EVE.Bookmark[${Config.SellSystem}].SolarSystemID}]
		}
		
		UI:Log["GetURL http://api.eve-central.com/api/marketstat?${TypeIDQuery}"]
		echo GetURL http://api.eve-central.com/api/marketstat?${TypeIDQuery}&usesystem=${SystemID}
		GetURL http://api.eve-central.com/api/marketstat?${TypeIDQuery}&usesystem=${SystemID}
		This:InsertState["WaitForPrice", 100]
		return TRUE
	}
	
	method ParsePrice(int Size, string URL, string IPAddress, int ResponseCode, float TransferTime, string ResponseText, string ParsedBody)
	{
		if ${ResponseCode} >= 400
		{
			if ${This.States.Peek.Name.Equal[ProcessSell]}
			{
				This:Clear
				This:QueueState["CheckItem", 0]
				UI:Update["obj_HangarSale", "No response from EVE-Central API - Skipping item", "o"]
			}
			elseif ${This.States.Peek.Name.Equal[UpdateOrders]}
			{
				This:Clear
				This:QueueState["UpdateOrders", 0]
				UI:Update["obj_HangarSale", "No response from EVE-Central API - Skipping item", "o"]
			}
		}
		else
		{
			CombinedXMLInput:Concat[${ResponseText.Escape}]
			if ${ResponseText.Find[</evec_api>](exists)}
			{
				PriceGot:Set[TRUE]
			}
		}
	}
	
	member:bool WaitForPrice()
	{
		if ${PriceGot}
		{
			;redirect -append "${This.LogFile}" Echo ${CombinedXMLInput}
		
			This:GetPrices[${CombinedXMLInput}]
			CombinedXMLInput:Set[""]
			PriceGot:Set[FALSE]
			return TRUE
		}

		return FALSE
	}
	
	member:bool CheckHangar()
	{
		variable int TimeToNextRun
		UI:Update["obj_HangarSale", "Beginning to list sell orders", "g"]
		HangarItems:Clear
		Me:GetHangarItems[HangarItems]
		HangarItems:GetIterator[HangarIterator]

		if ${HangarIterator:First(exists)} && ${Config.Sell}
		{
			This.RandomDelta:Set[100]

			This:QueueState["FetchPrice", 100, "${HangarIterator.Value.TypeID}"]
			This:QueueState["ProcessSell", 100]

		}
		
		return TRUE
	}
		
	member:bool CheckItem()
	{
		echo CheckItem
		variable int ItemCount = 0
		variable string TypeIDs = ""
		variable string Seperator = ""
		variable int TimeToNextRun
		if ${HangarIterator:Next(exists)}
		{
			if  ${HangarIterator.Value.GroupID} == GROUP_SECURECARGOCONTAINER || \
				${HangarIterator.Value.GroupID} == GROUP_AUDITLOGSECURECONTAINER
			{
				return FALSE
			}

			This:QueueState["FetchPrice", 100, "${HangarIterator.Value.TypeID}"]
			This:QueueState["ProcessSell", 100]
		}
		else
		{
			if ${Config.Logout}
			{
				This:Clear
				AutoLogout:StationaryLogoutNow
			}
		
			TimeToNextRun:Set[${Math.Calc[60000 * ${Math.Rand[11]} + 1800000]}]
			UI:Update["obj_HangarSale", "Operations complete - Beginning again in ${Math.Calc[${TimeToNextRun} / 60000]} minutes", "o"]
			MineralNames:Clear
			MineralNames:Set[34, "Tritanium"]
			MineralNames:Set[35, "Pyerite"]
			MineralNames:Set[36, "Mexallon"]
			MineralNames:Set[37, "Isogen"]
			MineralNames:Set[38, "Nocxium"]
			MineralNames:Set[39, "Zydrine"]
			MineralNames:Set[40, "Megacyte"]
			This:QueueState["Idle", ${TimeToNextRun}]
			
			This:QueueState["UpdateCurrentOrderCount"]
			This:QueueState["CheckOrders"]
			This:QueueState["OpenHangar"]
			This:QueueState["CheckHangar"]
		}
		return TRUE
	}
	
	member:bool ProcessSell()
	{
		variable float sellBuyoutPrice
		variable float sellLowestPrice
		variable float sellAveragePrice
		variable float discount

		if !${BuyPrices[${HangarIterator.Value.TypeID}](exists)} || !${SellPrices[${HangarIterator.Value.TypeID}](exists)}
		{
			UI:Update["obj_HangarSale", "No market data for ${HangarIterator.Value.Name}", "r"]
			UI:Update["obj_HangarSale", "Skipping to next item", "r"]
			This:QueueState["CheckItem", 0]
			return TRUE
		}		
		
		discount:Set[${Math.Calc[${SellPrices[${HangarIterator.Value.TypeID}].Min}*(${Config.UndercutPercent} * .01)]}]
		if ${discount} > ${Config.UndercutValue}
		{
			discount:Set[${Config.UndercutValue}]
		}
		sellLowestPrice:Set[${Math.Calc[${SellPrices[${HangarIterator.Value.TypeID}].Min} - ${discount}]}]
		if ${This.GetItemValue[${HangarIterator.Value.TypeID}, ${HangarIterator.Value.PortionSize}]} < ${sellLowestPrice}
		{
			if ${Config.PriceMode.Equal["Undercut Lowest"]} 
			{
				UI:Update["obj_HangarSale", "${HangarIterator.Value.Name}", "y"]
				if ${CurrentSellOrders} >= ${This.MaxOrders}
				{
					UI:Update["obj_HangarSale", "No sell orders available - Skipping", "o"]
					This:QueueState["UpdateCurrentOrderCount"]
					This:QueueState["CheckItem", 0]
				}
				else
				{
					UI:Update["obj_HangarSale", "Selling \ar${HangarIterator.Value.Quantity}\ag at \ao${ComBot.ISK_To_Str[${sellLowestPrice}]}", "g"]
					HangarIterator.Value:PlaceSellOrder[${sellLowestPrice}, ${HangarIterator.Value.Quantity}, ${Config.Duration}]
					This:QueueState["UpdateCurrentOrderCount"]
					This:QueueState["CheckItem", 10000]
				}
				return TRUE
			}
		}

		sellBuyoutPrice:Set[${BuyPrices[${HangarIterator.Value.TypeID}].Max}]
		if ${This.GetItemValue[${HangarIterator.Value.TypeID}, ${HangarIterator.Value.PortionSize}]} < ${sellBuyoutPrice}
		{
			if ${Config.PriceMode.Equal["Match Highest Buyout"]} 
			{
				UI:Update["obj_HangarSale", "${HangarIterator.Value.Name}", "y"]
				if ${CurrentSellOrders} >= ${This.MaxOrders}
				{
					UI:Update["obj_HangarSale", "No sell orders available - Skipping", "o"]
					This:QueueState["UpdateCurrentOrderCount"]
					This:QueueState["CheckItem", 0]
				}
				else
				{
					UI:Update["obj_HangarSale", "Selling \ar${HangarIterator.Value.Quantity}\ag at \ao${ComBot.ISK_To_Str[${sellBuyoutPrice}]}", "g"]
					HangarIterator.Value:PlaceSellOrder[${sellBuyoutPrice}, ${HangarIterator.Value.Quantity}, ${Config.Duration}]
					This:QueueState["UpdateCurrentOrderCount"]
					This:QueueState["CheckItem", 10000]
				}
				return TRUE
			}
		}

		discount:Set[${Math.Calc[${SellPrices[${HangarIterator.Value.TypeID}].Average}*(${Config.UndercutPercent} * .01)]}]
		if ${discount} > ${Config.UndercutValue}
		{
			discount:Set[${Config.UndercutValue}]
		}
		sellAveragePrice:Set[${Math.Calc[${SellPrices[${HangarIterator.Value.TypeID}].Average} - ${discount}]}]
		if ${This.GetItemValue[${HangarIterator.Value.TypeID}, ${HangarIterator.Value.PortionSize}]} < ${sellAveragePrice}
		{
			if ${Config.PriceMode.Equal["Undercut Average"]} 
			{
				UI:Update["obj_HangarSale", "${HangarIterator.Value.Name}", "y"]
				if ${CurrentSellOrders} >= ${This.MaxOrders}
				{
					UI:Update["obj_HangarSale", "No sell orders available - Skipping", "o"]
					This:QueueState["UpdateCurrentOrderCount"]
					This:QueueState["CheckItem", 0]
				}
				else
				{
					UI:Update["obj_HangarSale", "Selling \ar${HangarIterator.Value.Quantity}\ag at \ao${ComBot.ISK_To_Str[${sellAveragePrice}]}", "g"]
					HangarIterator.Value:PlaceSellOrder[${sellAveragePrice}, ${HangarIterator.Value.Quantity}, ${Config.Duration}]
					This:QueueState["UpdateCurrentOrderCount"]
					This:QueueState["CheckItem", 10000]
				}
				return TRUE
			}
		}
		
		if ${Config.MoveRefine}
		{
			UI:Update["obj_HangarSale", "${HangarIterator.Value.Name}", "y"]
			UI:Update["obj_HangarSale", "Item is worth more if recycled into minerals, moving to ship", "g"]
			HangarIterator.Value:MoveTo[MyShip,CargoHold]
			This:QueueState["CheckItem", 5000]
		}
		else
		{
			UI:Update["obj_HangarSale", "${HangarIterator.Value.Name}", "y"]
			UI:Update["obj_HangarSale", "Item is worth more if recycled into minerals, skipping", "o"]
			This:QueueState["CheckItem", 0]
		}
		return TRUE
	}	

	
	
	member:bool AcceptRepackage()
	{
		EVEWindow[ByName, modal]:ClickButtonYes
		return TRUE
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
		if ${Me:GetMyOrders[MyOrderIndex]}
		{
			CurrentSellOrders:Set[${MyOrderIndex.Used}]
			return TRUE
		}
		return FALSE
	}
	
	member:bool CheckOrders()
	{
			UI:Update["obj_HangarSale", "${CurrentSellOrders} current sell orders out of ${This.MaxOrders}", "g"]
			MyOrderIndex:GetIterator[MyOrderIterator]
			if ${MyOrderIterator:First(exists)} && ${Config.RePrice}
			{
				This.RandomDelta:Set[100]
				This:InsertState["UpdateOrders", 100]
				This:InsertState["FetchPrice", 100, "${MyOrderIterator.Value.TypeID}"]
			}
			return TRUE
	}
	
	member:bool UpdateOrders()
	{
		variable float discount
		variable float sellPrice
		variable int delay = 0
		
		echo UpdateOrders
		
		if !${BuyPrices[${MyOrderIterator.Value.TypeID}](exists)} || !${SellPrices[${MyOrderIterator.Value.TypeID}](exists)}
		{
			UI:Update["obj_HangarSale", "No market data for ${MyOrderIterator.Value.Name}", "r"]
			UI:Update["obj_HangarSale", "Skipping to next item", "r"]
			if ${MyOrderIterator:Next(exists)}
			{
				This:InsertState["UpdateOrders"]
				This:InsertState["FetchPrice", 100, "${MyOrderIterator.Value.TypeID}"]
				return TRUE
			}
			else
			{
				return TRUE
			}
		}
		
		if !${MyOrderIterator.Value.IsSellOrder}
		{
			UI:Update["obj_HangarSale", "Skipping buy order - ${MyOrderIterator.Value.Name}", "o"]
			if ${MyOrderIterator:Next(exists)}
			{
				This:InsertState["UpdateOrders"]
				This:InsertState["FetchPrice", 100, "${MyOrderIterator.Value.TypeID}"]
				return TRUE
			}
			else
			{
				return TRUE
			}
			
		}
		
		if ${Config.PriceMode.Equal["Undercut Lowest"]} 
		{
			discount:Set[${Math.Calc[${SellPrices[${MyOrderIterator.Value.TypeID}].Min}*(${Config.UndercutPercent} * .01)]}]
			if ${discount} > ${Config.UndercutValue}
			{
				discount:Set[${Config.UndercutValue}]
			}
			sellPrice:Set[${Math.Calc[${SellPrices[${MyOrderIterator.Value.TypeID}].Min} - ${discount}]}]
			UI:Update["obj_HangarSale", "${MyOrderIterator.Value.Name}", "y"]
			if ${Math.Calc[${MyOrderIterator.Value.Price}-5]} > ${SellPrices[${MyOrderIterator.Value.TypeID}].Min}
			{
				UI:Update["obj_HangarSale", "Repricing from \ar${ComBot.ISK_To_Str[${MyOrderIterator.Value.Price}]} \ayto \ag${ComBot.ISK_To_Str[${sellPrice}]}", "y"]
				MyOrderIterator.Value:Modify[${sellPrice}]
				delay:Set[10000]
			}
			else
			{
				UI:Update["obj_HangarSale", "Repricing unneccessary", "y"]
			}
		}
		if ${Config.PriceMode.Equal["Match Highest Buyout"]} 
		{
			sellPrice:Set[${BuyPrices[${MyOrderIterator.Value.TypeID}].Max}]
			UI:Update["obj_HangarSale", "${MyOrderIterator.Value.Name}", "y"]
			if ${MyOrderIterator.Value.Price} > ${sellPrice}
			{
				UI:Update["obj_HangarSale", "Repricing from \ar${ComBot.ISK_To_Str[${MyOrderIterator.Value.Price}]} \ayto \ag${ComBot.ISK_To_Str[${sellPrice}]}", "y"]
				MyOrderIterator.Value:Modify[${sellPrice}]
				delay:Set[10000]
			}
			else
			{
				UI:Update["obj_HangarSale", "Repricing unneccessary", "y"]
			}
		}
		if ${Config.PriceMode.Equal["Undercut Average"]} 
		{
			discount:Set[${Math.Calc[${SellPrices[${MyOrderIterator.Value.TypeID}].avg}*(${Config.UndercutPercent} * .01)]}]
			if ${discount} > ${Config.UndercutValue}
			{
				discount:Set[${Config.UndercutValue}]
			}
			sellPrice:Set[${Math.Calc[${SellPrices[${MyOrderIterator.Value.TypeID}].avg} - ${discount}]}]
			UI:Update["obj_HangarSale", "${MyOrderIterator.Value.Name}", "y"]
			if ${Math.Calc[${MyOrderIterator.Value.Price}-5]} > ${SellPrices[${MyOrderIterator.Value.TypeID}].avg}
			{
				UI:Update["obj_HangarSale", "Repricing from \ar${ComBot.ISK_To_Str[${MyOrderIterator.Value.Price}]} \ayto \ag${ComBot.ISK_To_Str[${sellPrice}]}", "y"]
				MyOrderIterator.Value:Modify[${sellPrice}]
				delay:Set[10000]
			}
			else
			{
				UI:Update["obj_HangarSale", "Repricing unneccessary", "y"]
			}
		}
		
		
		if ${MyOrderIterator:Next(exists)}
		{
			This:InsertState["UpdateOrders", ${delay}]
			This:InsertState["FetchPrice", 100, "${MyOrderIterator.Value.TypeID}"]
			return TRUE
		}
		return TRUE
	}
	
	member:float GetItemValue(int TypeID, int PortionSize)
	{
		variable float ItemValue=0
		
		ItemValue:Inc[${Math.Calc[${RefineData.Tritanium[${TypeID}]} * ${This.GetRefineLoss} * ${BuyPrices["34"].Average}]}]
		ItemValue:Inc[${Math.Calc[${RefineData.Pyerite[${TypeID}]} * ${This.GetRefineLoss} * ${BuyPrices["35"].Average}]}]
		ItemValue:Inc[${Math.Calc[${RefineData.Mexallon[${TypeID}]} * ${This.GetRefineLoss} * ${BuyPrices["36"].Average}]}]
		ItemValue:Inc[${Math.Calc[${RefineData.Isogen[${TypeID}]} * ${This.GetRefineLoss} * ${BuyPrices["37"].Average}]}]
		ItemValue:Inc[${Math.Calc[${RefineData.Nocxium[${TypeID}]} * ${This.GetRefineLoss} * ${BuyPrices["38"].Average}]}]
		ItemValue:Inc[${Math.Calc[${RefineData.Zydrine[${TypeID}]} * ${This.GetRefineLoss} * ${BuyPrices["39"].Average}]}]
		ItemValue:Inc[${Math.Calc[${RefineData.Megacyte[${TypeID}]} * ${This.GetRefineLoss} * ${BuyPrices["40"].Average}]}]
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
		BuyPrices:Erase[${typeID}]
		SellPrices:Erase[${typeID}]
		
		if ${XMLString.Find[<type id=](exists)}
		{
			do
			{
				XMLString:Set[${XMLString.Right[${Math.Calc[-9-${XMLString.Find[<type id=]}]}].Escape}]
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

				
				BuyPrices:Set[${typeID}, ${avg}, ${max}, ${min}, ${stddev}, ${median}, ${percentile}]

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

				SellPrices:Set[${typeID}, ${avg}, ${max}, ${min}, ${stddev}, ${median}, ${percentile}]

			}
			while ${XMLString.Find[<type id=](exists)}	
		}
		else
		{
			echo Nothing in XMLString for GetPrices
		}
	}
}

objectdef obj_HangarSaleUI inherits obj_State
{


	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
	}
	
	method Start()
	{
		This:QueueState["UpdateBookmarkLists", 5]
	}
	
	method Stop()
	{
		This:Clear
	}

	member:bool UpdateBookmarkLists()
	{
		variable index:bookmark Bookmarks
		variable iterator BookmarkIterator

		EVE:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		

		UIElement[SellSystemList@SellingFrame@ComBot_HangarSale_Frame@ComBot_HangarSale]:ClearItems
		if ${BookmarkIterator:First(exists)}
			do
			{	
				if ${UIElement[SellSystem@SellingFrame@ComBot_HangarSale_Frame@ComBot_HangarSale].Text.Length}
				{
					if ${BookmarkIterator.Value.Label.Left[${HangarSale.Config.SellSystem.Length}].Equal[${HangarSale.Config.SellSystem}]}
						UIElement[SellSystemList@SellingFrame@ComBot_HangarSale_Frame@ComBot_HangarSale]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
				else
				{
					UIElement[SellSystemList@SellingFrame@ComBot_HangarSale_Frame@ComBot_HangarSale]:AddItem[${BookmarkIterator.Value.Label.Escape}]
				}
			}
			while ${BookmarkIterator:Next(exists)}

			
		return FALSE
	}

}