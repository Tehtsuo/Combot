/*

ComBot  Copyright ? 2012  Tehtsuo and Vendan

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

objectdef obj_NPCData
{
	variable string SetName = "NPCData"

	variable filepath CONFIG_PATH = "${Script.CurrentDirectory}/data"
	variable string CONFIG_FILE = "NPCData.xml"
	variable settingsetref BaseRef

	method Initialize()
	{
		LavishSettings[NPCData]:Clear
		LavishSettings:AddSet[NPCData]

		if ${CONFIG_PATH.FileExists["${CONFIG_FILE}"]}
		{
			LavishSettings[NPCData]:Import["${CONFIG_PATH}/${CONFIG_FILE}"]
		}
		BaseRef:Set[${LavishSettings[NPCData].FindSet[NPCTypes]}]

		UI:Update["Configuration", " ${This.SetName}: Initialized", "-g"]
	}

	method Shutdown()
	{
		LavishSettings[NPCData]:Clear
	}
	
	member:string NPCType(int GroupID)
	{
		variable iterator NPCTypes
		BaseRef:GetSetIterator[NPCTypes]
		if ${NPCTypes:First(exists)}
		{
			do
			{
				if ${NPCTypes.Value.FindSetting[${GroupID}](exists)}
				{
					return ${NPCTypes.Key}
				}
			}
			while ${NPCTypes:Next(exists)}
		}
	}
}
