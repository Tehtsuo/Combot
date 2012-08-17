/*

ComBot  Copyright � 2012  Tehtsuo and Vendan

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

objectdef obj_EVEExtension
{
	variable bool Ready=FALSE
	variable string Character=""
	
	function Initialize()
	{
		do
		{
			if ${ISXEVE(exists)}
			{
				break
			}
			extension ISXEVE
			wait 10
		}
		while !${ISXEVE(exists)} || !${ISXEVE.IsReady}
		Ready:Set[TRUE]
	}
}


objectdef obj_Login inherits obj_State
{
	
	
	method Initialize()
	{
		This[parent]:Initialize
		This.NonGameTiedPulse:Set[TRUE]
		
		if ${Me(exists)} && ${MyShip(exists)} && (${Me.InSpace} || ${Me.InStation})
		{
			return
		}
		
		if ${EVEExtension.Character.Length}
		{
			UI:Update["obj_Login", "Beginning auto-login for character \ao${EVEExtension.Character}", "y"]		
		}
		else
		{
			UI:Update["obj_Login", "Autologin character not specified.  Specify a character in your command line.", "r"]
			return
		}
		
		
		This:QueueState["Login"]
		This:QueueState["SelectCharacter"]
	}

	member:bool Login()
	{
		if ${CharSelect(exists)}
		{
			return TRUE
		}
		
		if ${EVEWindow[ByName,modal](exists)}
		{
			if ${EVEWindow[ByName,modal].Text.Find["There is a new build available"](exists)}
			{
				EVEWindow[ByName,modal]:ClickButtonYes
				return FALSE
			}
			elseif 	${EVEWindow[ByName,modal].Text.Find["A client update is available"](exists)} || \
					${EVEWindow[ByName,modal].Text.Find["The client update has been installed."](exists)} || \
					${EVEWindow[ByName,modal].Text.Find["The update has been downloaded."](exists)} || \
					${EVEWindow[ByName,modal].Text.Find["The daily downtime will begin in"](exists)} || \
					${EVEWindow[ByName,modal].Text.Find["The connection to the server was closed"](exists)} || \
					${EVEWindow[ByName,modal].Text.Find["At any time you can log in to the account management page"](exists)}
			{
				EVEWindow[ByName,modal]:ClickButtonOK
				return FALSE
			}
		}
		
		if !${Login.ServerStatus.Find["OK"](exists)}
		{
			UI:Update["obj_Login", "Server not up.  Beginning 5 minute wait.", "-o"]		
			This:InsertState["Idle", 300000]
			This:QueueState["Login"]
			return TRUE
		}
		
		if 	${EVEWindow[ByCaption,LOGIN DATA INCORRECT](exists)} || \
			${EVEWindow[ByName,modal].Text.Find["Account subscription expired"](exists)} || \
			${EVEWindow[ByName,modal].Text.Find["has been disabled"](exists)}
		{
			UI:Update["obj_Login", "Login failed, stopping script.", "r"]
			This:Clear
			Display.Window:Flash
			return TRUE
		}
		
		if 	${EVEWindow[ByCaption,Connection in Progress](exists)} || \
			${EVEWindow[ByCaption,CONNECTION IN PROGRESS](exists)} || \
			${EVEWindow[ByCaption,Connection Not Allowed](exists)} || \
			${EVEWindow[ByCaption,CONNECTION FAILED](exists)}
		{
			UI:Update["obj_Login", "Server is cranky, trying again in 10 seconds", "g"]
			Press Esc
			This:InsertState["Idle", 10000]
			This:QueueState["Login"]
			return TRUE
			
		}
		
		Login:SetUsername[${Config.Common.Account}]
		Login:SetPassword[${Config.Common.Password}]
		Login:Connect
		UI:Update["obj_Login", "Login command sent", "g"]
		This:InsertState["Idle", 20000]
		This:QueueState["Login"]
		return TRUE
	}
	
	member:bool SelectCharacter()
	{
		if ${Me(exists)} && ${MyShip(exists)} && (${Me.InSpace} || ${Me.InStation})
		{
			return TRUE
		}
		
		if ${EVE.IsProgressWindowOpen}
		{
			return FALSE
		}
		
		if ${EVEWindow[ByName,MessageBox](exists)} || ${EVEWindow[ByCaption,System Congested](exists)}
		{
			UI:Update["obj_Login", "System may be congested, waiting 10 seconds", "g"]
			Press Esc
			This:InsertState["Idle", 10000]
			This:QueueState["SelectCharacter"]
			return TRUE
		}
		
		if  ${EVEWindow[ByName,modal].Text.Find["The daily downtime will begin in"](exists)} || \
			${EVEWindow[ByName,modal].Text.Find["local session information is corrupt"](exists)}
		{
			EVEWindow[ByName,modal]:ClickButtonOK
			return FALSE
		}
		
		if ${EVEWindow[ByName,modal].Text.Find["has been flagged for recustomization"](exists)}
		{
			EVEWindow[ByName,modal]:ClickButtonNo
			return FALSE
		}
		if !${CharSelect.CharExists[${Config.Common.CharID}]}
		{
			return FALSE
		}

		CharSelect:ClickCharacter[${Config.Common.CharID}]
		UI:Update["obj_Login", "Character select command sent", "g"]
		This:InsertState["Idle", 20000]
		This:QueueState["SelectCharacter"]
		return TRUE
	}
}