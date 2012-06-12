
objectdef obj_Asteroids inherits obj_State
{
	variable index:entity AsteroidList
	
	
	variable index:entity AsteroidListBuffer
	variable index:entity OORAsteroidListBuffer
	variable queue:string OreTypeQueue
	
	
	
	
	method Initialize()
	{
		This[parent]:Initialize
		PulseFrequency:Set[5]

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
		
		echo EVE:QueryEntities[asteroid_index, "CategoryID==CATEGORYID_ORE && Name =- \"${OreTypeQueue.Peek}\""]		
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
					echo Inserting OOR ${asteroid_iterator.Value.ID}
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
