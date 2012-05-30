
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
		QueryString:Concat["GroupID = GROUP_CONCORDDRONE &&"]
		QueryString:Concat["GroupID = GROUP_CONVOYDRONE &&"]
		QueryString:Concat["GroupID = GROUP_CONVOY &&"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLEOBJECT &&"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESHIP &&"]
		QueryString:Concat["GroupID = GROUP_LARGECOLLIDABLESTRUCTURE)"]

		EVE:QueryEntities[tgtIndex, ${QueryString}]

		if ${tgtIndex.Used} > 0
		{
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