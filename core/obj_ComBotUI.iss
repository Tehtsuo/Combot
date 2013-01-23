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

objectdef obj_ComBotUI
{
	variable int NextPulse
	variable int PulseIntervalInMilliseconds = 60000

	variable int NextMsgBoxPulse
	variable int PulseMsgBoxIntervalInMilliSeconds = 15000
	variable queue:string ConsoleBuffer
	variable bool Reloaded = FALSE
	variable string LogFile
	
	variable string Branch = COMBOT_BRANCH
	variable string Version = COMBOT_VERSION


	method Initialize()
	{
		if ${EVEExtension.Character.Length}
		{
			This.LogFile:Set["./config/logs/${EVEExtension.Character}/${Time.Month}.${Time.Day}.${Time.Year}-${Time.Hour}.${Time.Minute}-${Time.Timestamp}.log"]
			mkdir "./config/logs"
			mkdir "./config/logs/${EVEExtension.Character}"
		}
		else
		{
			This.LogFile:Set["./config/logs/${Me.Name}/${Time.Month}.${Time.Day}.${Time.Year}-${Time.Hour}.${Time.Minute}-${Time.Timestamp}.log"]
			mkdir "./config/logs"
			mkdir "./config/logs/${Me.Name}"
		}
		ui -load interface/ComBotGUI.xml
		This:Update["ComBot", "ComBot  Copyright © 2012  Tehtsuo and Vendan", "o"]
		This:Update["ComBot", "This program comes with ABSOLUTELY NO WARRANTY", "o"]
		This:Update["ComBot", "This is free software and you are welcome to redistribute it", "o"]
		This:Update["ComBot", "under certain conditions.  See gpl.txt for details", "o"]

		
		This:Update["ComBot", "Current Branch: \ay${Branch}", "g"]
		This:Update["ComBot", "Current Version: \ay${Version}", "g"]
		
		if ${ISXEVE.Version} < ${MinimumISXEVE}
		{
			This:Update["ComBot", "You are currently using ISXEVE version \ay${ISXEVE.Version}", "r"]
			This:Update["ComBot", "ComBot requires version \ay${MinimumISXEVE.Precision[4]} \aror higher", "r"]
			This:Update["ComBot", "This may be because ISXEVE will be patched soon and is currently broken", "r"]
		}
		
		This:Update["ComBot", "Initializing modules", "y"]

		Event[ISXEVE_onFrame]:AttachAtom[This:Pulse]
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
				if ${Automate.Config.Downtime}
				{
					Automate:DeltaLogoutNow
				}
			}
			EVE:CloseAllMessageBoxes
			if ${Config.Common.CloseChatInvites}
			{
				EVE:CloseAllChatInvites
			}

    		This.NextMsgBoxPulse:Set[${Math.Calc[${LavishScript.RunningTime} + ${PulseMsgBoxIntervalInMilliSeconds} + ${Math.Rand[500]}]}]
		}

	}

	method Reload()
	{
		ui -reload interface/ComBotGUI.xml
		This:WriteQueueToLog
		This.Reloaded:Set[TRUE]
		UIElement[ComBotTab@ComBot].Tab[${Config.Common.ActiveTab}]:Select
		if ${Config.Common.Hidden}
		{
			UIElement[ComBotTab@ComBot]:Hide
			This:SetText[Show]
		}
		else
		{
			UIElement[ComBotTab@ComBot]:Show
			This:SetText[Hide]
		}
		
	}
	
	method WriteQueueToLog()
	{
		while ${This.ConsoleBuffer.Peek(exists)}
		{
			UIElement[StatusConsole@Status@ComBotTab@ComBot]:Echo[${This.ConsoleBuffer.Peek.Escape}]
			This:Log[${This.ConsoleBuffer.Peek.Escape}]
			This.ConsoleBuffer:Dequeue
		}
	}
	
	
	method Update(string CallingModule, string StatusMessage, string Color="w", bool Censor=FALSE)
	{
		variable string MSG
		variable string MSGRemainder
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

		MSG:Concat["\a${Color}${StatusMessage.Escape}"]
		
		if ${MSG.Length} > 85
		{
			MSGRemainder:Set[${MSG.Right[-85].Escape}]
			MSG:Set[${MSG.Left[85].Escape}]
			if ${This.Reloaded}
			{
				UIElement[StatusConsole@Status@ComBotTab@ComBot]:Echo["${MSG.Escape}"]
				UIElement[StatusConsole@Status@ComBotTab@ComBot]:Echo["-                 \a${Color}${MSGRemainder.Escape}"]
				if !${Censor}
				{
					This:Log["${MSG.Escape}"]
					This:Log["-                 \a${Color}${MSGRemainder.Escape}"]
				}
			}
			else
			{
				if !${Censor}
				{
					This.ConsoleBuffer:Queue["${MSG}"]
					This.ConsoleBuffer:Queue["-                 \a${Color}${MSGRemainder.Escape}"]
				}
			}

		}
		else
		{
			if ${This.Reloaded}
			{
				UIElement[StatusConsole@Status@ComBotTab@ComBot]:Echo["${MSG.Escape}"]
				if !${Censor}
				{
					This:Log["${MSG.Escape}"]
				}
			}
			else
			{
				if !${Censor}
				{
				This.ConsoleBuffer:Queue["${MSG}"]
				}
			}
		}
	}
	
	method Log(string Msg, bool Verbose=FALSE)
	{
		if !${Verbose}
		{
			redirect -append "${This.LogFile}" echo "[${Time.Hour}:${Time.Minute}:${Time.Second}] ${Msg.Escape}"
		}
		else
		{
			if ${Config.Common.Verbose}
			{
				redirect -append "${This.LogFile}" echo "[${Time.Hour}:${Time.Minute}:${Time.Second}] ${Msg.Escape}"
			}
		}
	}
}
