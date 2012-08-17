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

objectdef obj_EVEExtension
{
	variable bool Ready=FALSE
	
	function Initialize()
	{
		do
		{
			if ${ISXEVE(exists)}
			{
				break
			}
			extension ISXEVE
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
		
		;This:QueueState["LoadExtension"]
	}

	member:bool LoadExtension()
	{

	}
	

	
}