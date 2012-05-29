
objectdef obj_ComBotUI
{
	variable int NextPulse
	variable int PulseIntervalInMilliseconds = 60000

	variable int NextMsgBoxPulse
	variable int PulseMsgBoxIntervalInMilliSeconds = 15000


	method Initialize()
	{
		ui -load interface/ComBotGUI.xml
		This:Update["Combot", "Initializing modules", "y"]

		Event[ISXEVE_onFrame]:AttachAtom[This:Pulse]
		This:Update["obj_ComBotUI", "Initialized", "g"]
	}

	method Reload()
	{
		ui -reload interface/ComBotGUI.xml
	}

	method Shutdown()
	{
		Event[ISXEVE_onFrame]:DetachAtom[This:Pulse]
		ui -unload interface/ComBotGUI.xml
	}

	method Pulse()
	{
	    if ${LavishScript.RunningTime} >= ${This.NextPulse}
		{

    		This.NextPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${PulseIntervalInMilliseconds} + ${Math.Rand[500]}]}]
		}

		if ${ComBot.Paused}
		{
			return
		}

	    if ${LavishScript.RunningTime} >= ${This.NextMsgBoxPulse}
		{
			if ${EVEWindow[ByName,modal].Text.Find["The daily downtime will begin in"](exists)}
			{
				EVEWindow[ByName,modal]:ClickButtonOK
			}
			EVE:CloseAllMessageBoxes
			EVE:CloseAllChatInvites

    		This.NextMsgBoxPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${PulseMsgBoxIntervalInMilliSeconds} + ${Math.Rand[500]}]}]
		}

	}

	method Update(string CallingModule, string StatusMessage, string Color="w")
	{
		variable string MSG
		MSG:Set["\aw["]
		if ${CallingModule.Length} > 15
		{
			MSG:Concat[${CallingModule.Left[15]}]
		}
		else
		{
			MSG:Concat[${CallingModule}]
		}
		MSG:Concat["]"]
		
		while ${MSG.Length} < 20
		{
			MSG:Concat[" "]
		}	

		MSG:Concat["\a${Color}${StatusMessage}"]
		
		UIElement[StatusConsole@Status@ComBotTab@ComBot]:Echo["${MSG}"]
		
		switch ${CallingModule}
		{
			case obj_Salvage
				UIElement[obj_SalvageConsole@Salvager@ComBotTab@ComBot]:Echo["\a${Color}${StatusMessage}"]
				break
		}
	}


}
