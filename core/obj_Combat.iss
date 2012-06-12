objectdef obj_Combat inherits obj_State
{
	variable obj_KillTargetList KillTargets
	
	method Initialize()
	{
		This[parent]:Initialize
		UI:Update["obj_Combat", "Initialized", "g"]
		PulseFrequency:Set[500]
	}
	
	method Start()
	{
		if ${This.IsIdle}
		{
			UI:Update["obj_Combat", "Started", "g"]
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
		QueryString:Concat["GroupID = GROUP_SPAWNCONTAINER ||"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESTRUCTURE)"]
		
		return ${This.KillQueryString[${QueryString}]}
	}

	member:bool WaitForAgro(int cooldown=15)
	{
		UI:Update["obj_Combat", "Cooldown ${cooldown}", "r"]
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
		echo "KillAgro"
		return ${This.KillQueryString["CategoryID = CATEGORYID_ENTITY && IsNPC && IsTargetingMe"]}
	}
	
	member:bool AddTargetByName(string Name, int priority = 0)
	{
		return ${This.AddQueryString["CategoryID = CATEGORYID_ENTITY && IsNPC && Name =- \"${Name}\"", ${priority}]}
	}

	member:bool AddTargetByExactName(string Name, int priority = 0)
	{
		return ${This.AddQueryString["CategoryID = CATEGORYID_ENTITY && IsNPC && Name == \"${Name}\"", ${priority}]}
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
				echo ${KillTargetIterator.Value.ActionTaken}
				if ${KillTargetIterator.Value.ActionTaken}
				{
					return
				}
				if ${KillTargetIterator.Value.TargetDone}
				{
					KillTargets:Erase[${KillTargetIterator.Key}]
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
				if ${PrimaryIterator.Value.IsPrimary}
				{
					PrimaryCount:Inc
				}
			}
			while ${PrimaryIterator:Next(exists)}
		}
		
		if ${PrimaryCount} < ${MaxPrimaries}
		{
			echo "Getting Primary - ${This.GetClosest[TRUE, FALSE, TRUE]}"
			KillTargets.Element[${This.GetClosest[TRUE, FALSE, TRUE]}].IsPrimary:Set[TRUE]
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
				if !${NonPrimary} || !${KillTargetIterator.Value.IsPrimary}
				{
					if ${NonReady} || ${KillTargetIterator.Value.TargetReady}
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
	variable bool TargetDone = FALSE
	variable int Priority = 0
	variable int ModuleActivation = 0
	
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
			UI:Update["obj_KillTarget", "${Entity[${Target}].Name} In Range", "g"]
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
			UI:Update["obj_KillTarget", "${Entity[${Target}].Name} Is Primary", "g"]
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
			This:QueueState["WaitForLock"]
			return TRUE
		}
		if ${Ship.ModuleList_Weapon.InactiveCount} > 0 && ${ModuleActivation} <= 0
		{
			Ship.ModuleList_Weapon:Activate[${Target}]
			This.ActionTaken:Set[TRUE]
			ModuleActivation:Set[4]
		}
		if ${ModuleActivation} >= 0
		{
			ModuleActivation:Dec
		}
		return FALSE
	}
	
	member:bool Done()
	{
		TargetDone:Set[TRUE]
		TargetReady:Set[FALSE]
		IsPrimary:Set[FALSE]
	}
}