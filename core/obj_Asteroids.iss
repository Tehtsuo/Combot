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

objectdef obj_Asteroids inherits obj_State
{
	variable index:entity AsteroidList
	
	
	variable index:entity AsteroidListBuffer
	variable index:entity OORAsteroidListBuffer
	variable queue:string OreTypeQueue
	
	
	
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[10]
		RandomDelta:Set[0]

		UI:Update["obj_Asteroids", "Initialized", "g"]
	}


	
	member:bool UpdateList()
	{
		variable index:entity asteroid_index
		variable iterator asteroid_iterator

		if !${Client.InSpace}
		{
			return
		}

		if ${OreTypeQueue.Used} == 0
		{
			This:PopulateAsteroidList
			This:PopulateOreTypeQueue
			return
		}
		
		EVE:QueryEntities[asteroid_index, "CategoryID==CATEGORYID_ORE && Name =- \"${OreTypeQueue.Peek}\""]		
		asteroid_index:GetIterator[asteroid_iterator]
		if ${asteroid_iterator:First(exists)}
		{
			do
			{
				if ${asteroid_iterator.Value.Distance} < ${Ship.OptimalMiningRange}
				{
					This.AsteroidListBuffer:Insert[${asteroid_iterator.Value.ID}]
				}
				else
				{
					This.OORAsteroidListBuffer:Insert[${asteroid_iterator.Value.ID}]
				}
			}
			while ${asteroid_iterator:Next(exists)}
		}
		OreTypeQueue:Dequeue
		
		return FALSE
	}
	
	method PopulateOreTypeQueue()
	{
		variable iterator OreTypeIterator
		if ${Config.Miner.IceMining}
		{
			Config.Miner.IceTypesRef:GetSettingIterator[OreTypeIterator]
		}
		else
		{
			Config.Miner.OreTypesRef:GetSettingIterator[OreTypeIterator]
		}

		if ${OreTypeIterator:First(exists)}
		{		
			do
			{
				OreTypeQueue:Queue[${OreTypeIterator.Key}]
			}
			while ${OreTypeIterator:Next(exists)}			
		}
		else
		{
			echo "WARNING: obj_Asteroids: Ore Type list is empty, please check config"
		}
	}
	
	method PopulateAsteroidList()
	{
		variable iterator asteroid_iterator
		This.AsteroidList:Clear
		This.AsteroidListBuffer:GetIterator[asteroid_iterator]
		
		if ${asteroid_iterator:First(exists)}
		{
			do
			{
				This.AsteroidList:Insert[${asteroid_iterator.Value.ID}]
			}
			while ${asteroid_iterator:Next(exists)}
		}
		This.OORAsteroidListBuffer:GetIterator[asteroid_iterator]
		if ${asteroid_iterator:First(exists)}
		{
			do
			{
				This.AsteroidList:Insert[${asteroid_iterator.Value.ID}]
			}
			while ${asteroid_iterator:Next(exists)}
		}		
		This.AsteroidListBuffer:Clear
		This.OORAsteroidListBuffer:Clear
	}
	

}
