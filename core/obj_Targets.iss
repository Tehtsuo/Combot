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

objectdef obj_Targets
{

	method Initialize()
	{
		UI:Update["obj_Targets", "Initialized", "g"]
	}







	member:bool NPC()
	{
		variable index:entity tgtIndex
		variable string QueryString="CategoryID = CATEGORYID_ENTITY && IsNPC && !("
		
		;Exclude Groups here
		QueryString:Concat["GroupID = GROUP_CONCORDDRONE ||"]
		QueryString:Concat["GroupID = GROUP_CONVOYDRONE ||"]
		QueryString:Concat["GroupID = GROUP_CONVOY ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLEOBJECT ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESHIP ||"]
		QueryString:Concat["GroupID = GROUP_SPAWNCONTAINER ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESTRUCTURE)"]

		EVE:QueryEntities[tgtIndex, ${QueryString}]

		if ${tgtIndex.Used} > 0
		{
			variable iterator Tgts
			tgtIndex:GetIterator[Tgts]
			if ${Tgts:First(exists)}
			{
				do
				{
					echo ${Tgts.Value.Name} - ${Tgts.Value.Group} - ${Tgts.Value.GroupID}
				}
				While ${Tgts:Next(exists)}
			}
		
			return TRUE
		}

		return FALSE
	}
	

	member:int LockedAndLockingTargets()
	{
		variable index:entity Targets
		EVE:QueryEntities[Targets, "IsLockedTarget || BeingTargeted"]
		
		return ${Targets.Used}
	}

}