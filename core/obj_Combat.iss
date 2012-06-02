objectdef obj_Combat inherits obj_State
{
	variable int64 PrimaryTarget = -1
	
	method Initialize()
	{
		This[parent]:Initialize
		UI:Update["obj_Combat", "Initialized", "g"]
		PulseFrequency:Set[1000]
	}
	
	member:bool ClearPocket()
	{
		variable index:entity enemyTargets
		variable int MaxTarget = ${MyShip.MaxLockedTargets}
		variable iterator enemyIterator
		variable string QueryString="CategoryID = CATEGORYID_ENTITY && IsNPC && !("
		
		;Exclude Groups here
		QueryString:Concat["GroupID = GROUP_CONCORDDRONE ||"]
		QueryString:Concat["GroupID = GROUP_CONVOYDRONE ||"]
		QueryString:Concat["GroupID = GROUP_CONVOY ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLEOBJECT ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESHIP ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESTRUCTURE)"]

		EVE:QueryEntities[enemyTargets, ${QueryString}]
		
		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			MaxTarget:Set[${Me.MaxLockedTargets}]
		}
		
		enemyTargets:getIterator[enemyIterator]
		if !${Entity[${PrimaryTarget}](exists)}
		{
			PrimaryTarget:Set[-1]
		}
		if ${enemyIterator:First(exists)}
		{
			do
			{
				if !${TargetIterator.Value.BeingTargeted} && \
					!${TargetIterator.Value.IsLockedTarget} && \
					${Targets.LockedAndLockingTargets} < ${MaxTarget} && \
					${TargetIterator.Value.Distance} < ${MyShip.MaxTargetRange
				{
					TargetIterator.Value:LockTarget
					return FALSE
				}
				if ${PrimaryTarget} == -1 && ${TargetIterator.Value.IsLockedTarget}
				{
					PrimaryTarget:Set[${TargetIterator.Value.ID}]
					TargetIterator.Value:Orbit[${Ship.ModuleList_Weapons.Range}]
				}
				if ${PrimaryTarget} == ${TargetIterator.Value.ID}
				{
					Ship.ModuleList_Weapons:ActivateCount[2, ${PrimaryTarget}]
					return false
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		else
		{
			return TRUE
		}
		return FALSE
	}
	
	
	
}