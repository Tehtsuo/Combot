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

objectdef obj_Targets inherits obj_State
{
	variable index:entity Locked
	variable index:entity Asteroids

	method Initialize()
	{
		
		This[parent]:Initialize
		RandomDelta:Set[0]

		This:QueueState["Update", 20]
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
	

	
	member:bool Update()
	{
		Profiling:StartTrack["Targets_Update"]
		if !${Client.InSpace}
		{
			Profiling:EndTrack
			return FALSE
		}
		EVE:QueryEntities[Locked, "IsLockedTarget || BeingTargeted"]
		EVE:QueryEntities[Asteroids, "IsLockedTarget || BeingTargeted && CategoryID == CATEGORYID_ORE"]
		Profiling:EndTrack
		return FALSE
	}

	member:int TargetsByQuery(string QueryString)
	{
		variable index:entity Targets
		EVE:QueryEntities[Targets, "(IsLockedTarget || BeingTargeted) && (${QueryString})"]
		
		return ${Targets.Used}
	}

	member:int TargetingMe()
	{
		return ${This.TargetsByQuery[IsTargetingMe]}
	}
	
	member:bool AsteroidIsInRangeOfOthers(int64 id)
	{
		variable iterator Target
		Asteroids:GetIterator[Target]
		
		if ${Target:First(exists)}
		do
		{
			if ${Entity[${Target.Value}].DistanceTo[${id}]} > ${Math.Calc[${Ship.Module_MiningLaser_Range} * 1.9]}
			{
				return FALSE
			}
		}
		while ${Target:Next(exists)}
		return TRUE		
	}
}