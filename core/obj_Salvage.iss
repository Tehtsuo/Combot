objectdef obj_Salvage inherits obj_State
{

	method Initialize()
	{
		This[parent]:Initialize
		UI:Update["obj_Salvage", "Initialized", "g"]
	}

	method Start()
	{
		UI:Update["obj_Salvage", "Started", "g"]
		This:QueueState["CheckBookmarks"]
	}
	
	method Stop()
	{
		UI:Update["obj_Salvage", "Salvage stopped, setting destination to station", "g"]
		This:Clear()
		Move:Bookmark["Station"]
		This:QueueState["Traveling"]
	}

	member:bool CheckBookmarks()
	{
		//Scan for corp salvage bookmarks
		//Only return true once one is found
		variable index:bookmark Bookmarks
		variable iterator BookmarkIterator
		variable string Target
		variable string Time
		variable bool BookmarkFound
		
		if ${Entity["GroupID == GROUP_WARPGATE"](exists)}
		{
			UI:Update["obj_Salvage", "Gate found, activating", "g"]
Move:Gate[${Entity["GroupID == GROUP_WARPGATE"].ID}]
			This.QueueState["Traveling"]
			This.QueueState["SalvageWrecks"]
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold", 5000]
			return true;
		}
		
		
		BookmarkFound:Set[false]
		
		Eve:GetBookmarks[Bookmarks]
		Bookmarks:GetIterator[BookmarkIterator]
		if ${BookmarkIterator:First(exists)}
		do
		{
			if ${BookmarkIterator.Value.Label.Left[8].Upper.Equal["SALVAGE:"]} && ${BookmarkIterator.Value.TimeCreated.Compare[${Time}]} < 0
			{
				Target:Set[${BookmarkIterator.Value.Label}]
				Time:Set[${BookmarkIterator.Value.TimeCreated}]
				BookmarkFound:Set[True]
			}
		}
		while ${BookmarkIterator:Next(exists)}
		
		if ${BookmarkFound}
		{
			UI:Update["obj_Salvage", "Setting course for ${Target}", "g"]
			Move:Bookmark[${Target}]
			This:QueueState["Traveling"]
			This:QueueState["Log", 1000, "Salvaging at ${Target}"]
			This:QueueState["SalvageWrecks"]
			This:QueueState["DeleteBookmark", 1000, ${Target}]
			This:QueueState["OpenCargoHold"]
			This:QueueState["CheckCargoHold", 5000]
			return true
		}

		
		UI:Update["obj_Salvage", "No salvage bookmark found - returning to station", "g"]
		Move:Bookmark["Station"]
		This:QueueState["Traveling"]
		This:QueueState["Offload"]
		This:QueueState["CheckBookmarks"]
		return true
	}

	member:bool Traveling()
	{
		return !${Move.Traveling}
	}
	
	member:bool Log(string text)
	{
		UI:Update["obj_Salvage", "${text}", "g"]
		return TRUE
	}

	member:bool SalvageWrecks()
	{
		variable index:entity Targets
		variable iterator TargetIterator
		variable queue:int LootRangeAndTractored
		variable int Targeted = 0
		variable int Tractored = 0
		variable int MaxTarget = ${MyShip.MaxLockedTargets}
		variable int ModuleIndex = -1
		
		if ${Me.MaxLockedTargets} < ${MyShip.MaxLockedTargets}
		{
			MaxTarget:Set[${Me.MaxLockedTargets}]
		}
		
		Eve:QueryEntities[Targets, "GroupID==${GROUP_WRECK} OR GroupID==${GROUP_CARGOCONTAINER}"]
		if ${TargetIterator:First(exists)}
		{
			do
			{
				if !${TargetIterator.Value.BeingTargeted} && !${TargetIterator.Value.IsLockedTarget}
				{
					UI:Update["obj_Salvage", "Locking - ${TargetIterator.Value.Name}", "g"]
					TargetIterator.Value:LockTarget
					return false
				}
				Targeted:Inc
				if ${TargetIterator.Value.Distance} > ${Ship.Module_TractorBeams_Range} && ${Tractored}+1 == ${Targeted}
				{
					UI:Update["obj_Salvage", "Approaching - ${TargetIterator.Value.Name}", "g"]
					Move:Approach[${TargetIterator.Value}]
					return false
				}
				if !${TargetIterator.Value.IsWreckEmpty} && !${TargetIterator.Value.LootWindow(exists)} && ${TargetIterator.Value.Distance}<LOOT_RANGE
				{
					UI:Update["obj_Salvage", "Opening - ${TargetIterator.Value.Name}", "g"]
					TargetIterator.Value:OpenCargo
					return false
				}
				if !${TargetIterator.Value.IsWreckEmpty} && ${TargetIterator.Value.Distance}<LOOT_RANGE
				{
					UI:Update["obj_Salvage", "Looting - ${TargetIterator.Value.Name}", "g"]
					TargetIterator.Value.LootWindow:LootAll
					return false
				}
				if !${Ship.IsModuleActiveOn[${Ship.ModuleList_TractorBeams}, ${TargetIterator.Value.ID}]} && ${TargetIterator.Value.Distance} < ${Ship.Module_TractorBeams_Range}
				{
					ModuleIndex:Set[${Ship.FindUnactiveModule[${Ship.ModuleList_TractorBeams}}]
					if ${ModuleIndex} >= 0
					{
							UI:Update["obj_Salvage", "Activating tractor beam - ${TargetIterator.Value.Name}", "g"]
							Ship.ModuleList_TractorBeams.Get[${ModuleIndex}]:Activate[${TargetIterator.Value.ID}]
							return false
					}
				}
				if ${Ship.IsModuleActiveOn[${Ship.ModuleList_TractorBeams}, ${TargetIterator.Value.ID}]}
				{
					Tractored:Inc
				}
				if ${Ship.IsModuleActiveOn[${Ship.ModuleList_TractorBeams}, ${TargetIterator.Value.ID}]}  && ${TargetIterator.Value.Distance} < LOOT_RANGE
				{
					LootRangeAndTractored:Queue[${TargetIterator.Value.ID}]
				}
				if !${Ship.IsModuleActiveOn[${Ship.ModuleList_Salvagers}, ${TargetIterator.Value.ID}]} && ${TargetIterator.Value.Distance} < ${Ship.Module_Salvagers_Range}
				{
					ModuleIndex:Set[${Ship.FindUnactiveModule[${Ship.ModuleList_Salvagers}}]
					if ${ModuleIndex} >= 0
					{
						UI:Update["obj_Salvage", "Activating salvager - ${TargetIterator.Value.Name}", "g"]
						Ship.ModuleList_Salvagers.Get[${ModuleIndex}]:Activate[${TargetIterator.Value.ID}]
						return false
					}
				}
			}
			while ${TargetIterator:Next(exists)}
		}
		else
		{
			return true
		}
		return false
	}
	
	member:bool DeleteBookmark(string bookmarkname)
	{
		if !${Entity["GroupID == GROUP_WARPGATE"](exists)}
		{
			UI:Update["obj_Salvage", "Removing bookmark - ${bookmarkname}", "g"]
			Eve.Bookmark[${bookmarkname}]:Remove
		}
		else
		{
			UI:Update["obj_Salvage", "Gate present: Not removing bookmark - ${bookmarkname}", "g"]
		}
		return true
	}
	
	member:bool OpenCargoHold()
	{
		MyShip:OpenCargo[]
		return true
	}
	
	Member:bool CheckCargoHold()
	{
		if (${MyShip.UsedCargoCapacity} / ${MyShip.CargoCapacity}) > 0.75
		{
			Move:Bookmark["Station"]
			This:QueueState["Traveling"]
			This:QueueState["Offload"]
		}
		This:QueueState["CheckBookmarks"]
		return true;
	}

	member:bool Offload()
	{
		//Transfer stuff to corp hanger
		return false
	}
	
}