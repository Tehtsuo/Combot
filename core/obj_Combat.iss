objectdef obj_Combat inherits obj_State
{
	variable obj_KillTargetList KillTargets
	
	method Initialize()
	{
		This[parent]:Initialize
		UI:Update["obj_Combat", "Initialized", "g"]
		PulseFrequency:Set[2000]
	}
	
	method Start()
	{
		if ${This.IsIdle}
		{
			This:QueueState["WaitForAgro"]
			This:QueueState["KillAgro"]
			This:QueueState["ClearPocket"]
			This:QueueState["ClearTargetAddedList"]
		}
	}
	
	member:bool ClearPocket()
	{
		variable string QueryString="CategoryID = CATEGORYID_ENTITY && IsNPC && !("
		
		;Exclude Groups here
		QueryString:Concat["GroupID = GROUP_CONCORDDRONE ||"]
		QueryString:Concat["GroupID = GROUP_CONVOYDRONE ||"]
		QueryString:Concat["GroupID = GROUP_CONVOY ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLEOBJECT ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESHIP ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESTRUCTURE)"]
		
		return This.KillQueryString(${QueryString})
	}

	member:bool WaitForAgro(int cooldown=15)
	{
		if ${cooldown} == 0
		{
			return TRUE
		}
		cooldown:Dec
		This:SetStateArgs[${cooldown}]
		if ${Me.TargetedByCount} == 0
		{
			return FALSE
		}
		return TRUE
	}
	
	member:bool KillAgro()
	{
		return This.KillQueryString["CategoryID = CATEGORYID_ENTITY && IsNPC && IsTargetingMe"]
	}
	
	member:bool AddTargetByName(string Name, int priority = 0)
	{
		return This.AddQueryString["CategoryID = CATEGORYID_ENTITY && IsNPC && Name =- \"${Name}\"", ${priority}]
	}

	member:bool AddTargetByExactName(string Name, int priority = 0)
	{
		return This.AddQueryString["CategoryID = CATEGORYID_ENTITY && IsNPC && Name == \"${Name}\"", ${priority}]
	}

	member:bool AddQueryString(string QueryString, int priority = 0)
	{
		variable index:entity enemyTargets
		variable iterator enemyIterator
		
		EVE:QueryEntities[enemyTargets, ${QueryString}]
	
		enemyTargets:GetIterator[enemyIterator]
		if ${enemyIterator:First(exists)}
		{
			do
			{
				KillTargets:AddTarget[${enemyIterator.Value.ID}, ${priority}]
			}
			while ${enemyIterator:Next(exists)}
		}
		KillTargets:SetPrimaries
		KillTargets:PulseTargets
		
		return TRUE
	}
	
	member:bool KillCurrentTargets()
	{
		KillTargets:SetPrimaries
		KillTargets:PulseTargets
		if ${KillTargets.KillTargets.Used} == 0
		{
			return TRUE
		}
		return FALSE
	}
	
	member:bool KillQueryString(string QueryString)
	{
		variable index:entity enemyTargets
		variable iterator enemyIterator
		
		EVE:QueryEntities[enemyTargets, ${QueryString}]
	
		enemyTargets:GetIterator[enemyIterator]
		if ${enemyIterator:First(exists)}
		{
			do
			{
				KillTargets:AddTarget[${enemyIterator.Value.ID}]
			}
			while ${enemyIterator:Next(exists)}
		}
		else
		{
			return TRUE
		}
		KillTargets:SetPrimaries
		KillTargets:PulseTargets
		
		return FALSE
	}
	
	member:bool ClearTargetAddedList()
	{
		KillTargets.AlreadyAdded:Clear
		return TRUE
	}
	
	
}

objectdef obj_KillTargetList
{
	variable collection:obj_KillTarget KillTargets
	variable set AlreadyAdded
	variable int MaxPrimaries = 1
	
	method AddTarget(int64 NewTarget)
	{
		if !${AlreadyAdded.Contains[${NewTarget}]}
		{
			AlreadyAdded:Add[${NewTarget}]
			KillTargets:Set[${NewTarget}, ${NewTarget}]
		}
	}
	
	method PulseTargets()
	{
		variable iterator KillTargetIterator
		KillTargets:GetIterator[KillTargetIterator]
		if ${KillTargetIterator:First(exists)}
		{
			do
			{
				KillTargetIterator.Value.ActionTaken:Set[FALSE]
				KillTargetIterator.Value:Pulse
				if ${KillTargetIterator.Value.ActionTaken}
				{
					return
				}
			}
			while ${KillTargetIterator:Next(exists)}
		}
	}
	
	method SetPrimaries()
	{
		variable iterator PrimaryIterator
		variable int PrimaryCount = 0
		KillTargets:GetIterator[PrimaryIterator]
		
		if ${PrimaryIterator:First(exists)}
		{
			do
			{
				if !${PrimaryIterator.Value.IsPrimary}
				{
					PrimaryCount:Inc
				}
			}
			while ${PrimaryIterator:Next(exists)}
		}
		
		if ${PrimaryTargets.Used} < ${MaxPrimaries}
		{
			KillTargets.Element[${This.GetClosest[TRUE, FALSE]}].IsPrimary:Set[TRUE]
		}
	}
	
	member:int64 GetClosest(bool NonPrimary = FALSE, bool NonReady = TRUE, bool ByPriority = FALSE)
	{
		variable float curDistance = 999999999999
		variable int64 Closest = -1
		variable int BestPriority = -999999
		variable iterator KillTargetIterator
		KillTargets:GetIterator[KillTargetIterator]
		if ${KillTargetIterator:First(exists)}
		{
			do
			{
				if !${NonPrimary} || !${Entity[${KillTargetIterator.Value.Target}].IsPrimary}
				{
					if ${NonReady} || ${Entity[${KillTargetIterator.Value.Target}].ReadyTarget}
					{
						if (${Entity[${KillTargetIterator.Value.Target}].Distance} < ${curDistance}) || (${ByPriority} && (${KillTargetIterator.Value.Priority} > ${BestPriority}))
						{
							curDistance:Set[${Entity[${KillTargetIterator.Value.Target}].Distance}]
							Closest:Set[${KillTargetIterator.Value.Target}]
						}
					}
				}
			}
			while ${KillTargetIterator:Next(exists)}
		}
		return ${Closest}
	}
}

objectdef obj_KillTarget inherits obj_State
{
	variable int64 Target = -1
	variable bool ActionTaken = FALSE
	variable bool TargetReady = FALSE
	variable bool IsPrimary = FALSE
	variable int Priority = 0
	
	method Initialize(int64 TargetID, int MyPriority = 0)
	{
		This[parent]:Initialize
		UI:Update["obj_KillTarget", "Initialized on ${Entity[${TargetID}].Name}", "g"]
		Target:Set[${TargetID}]
		This:IndependentPulse
		This:QueueState["LockTarget"]
		This:QueueState["WaitForLock"]
		This.Priority:Set[${MyPriority}]
	}
	
	member:bool LockTarget()
	{
		if ${Entity[${Target}].IsLockedTarget} || ${Entity[${Target}].BeingTargeted}
		{
			return TRUE
		}
		TargetReady:Set[FALSE]
		variable int MaxTarget = ${MyShip.MaxLockedTargets}
		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			MaxTarget:Set[${Me.MaxLockedTargets}]
		}
		echo ${MaxTarget} - ${Targets.LockedAndLockingTargets}
		if ${Targets.LockedAndLockingTargets} < ${MaxTarget} && \
			${Entity[${Target}].Distance} < ${MyShip.MaxTargetRange}
		{
			Entity[${Target}]:LockTarget
			ActionTaken:Set[TRUE]
			return TRUE
		}
		return FALSE
	}
	
	member:bool WaitForLock()
	{
		if ${Entity[${Target}].IsLockedTarget}
		{
			This:QueueState["WaitForRange"]
			This:QueueState["RequestPrimary"]
			This:QueueState["WaitForPrimary"]
			This:QueueState["KillTarget"]
			This:QueueState["Done"]
			return TRUE
		}
		TargetReady:Set[FALSE]
		IsPrimary:Set[FALSE]
		if !${Entity[${Target}].BeingTargeted}
		{
			This:QueueState["LockTarget"]
			This:QueueState["WaitForLock"]
			return TRUE
		}
		return FALSE
	}
	
	member:bool WaitForRange()
	{
		TargetReady:Set[FALSE]
		if ${Entity[${Target}].Distance} < ${Ship.ModuleList_Weapon.Range}
		{
			return TRUE
		}
		return FALSE
	}
	
	member:bool RequestPrimary()
	{
		TargetReady:Set[TRUE]
		return TRUE
	}
	
	member:bool WaitForPrimary()
	{
		if ${IsPrimary}
		{
			return TRUE
		}
		return FALSE
	}
	
	member:bool KillTarget()
	{
		if !${Entity[${Target}](exists)}
		{
			return TRUE
		}
		if !${Entity[${Target}].IsLockedTarget}
		{
			This:Clear
			This:QueueState["LockTarget"]
			This:QueueState["WaitForTarget"]
			return TRUE
		}
		if ${Ship.ModuleList_Weapon.InactiveCount} > 0
		{
			Ship.ModuleList_Weapon:Activate[${Target}]
			ActionTaken:Set[TRUE]
		}
		return FALSE
	}
	
	member:bool Done()
	{
		Combat.KillTargets:Erase[${Target}]
	}
}