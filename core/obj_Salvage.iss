objectdef obj_Salvage inherits obj_State
{

	method Initialize()
	{
    This[parent]:Initialize
		UI:Update["obj_Salvage", "Initialized", "g"]
  }
  
  method SalvageCycle()
  {
    This:QueueState["CheckBookmarks"]
  }
  
  member:bool CheckBookmarks()
  {
    //Scan for corp salvage bookmarks
    //Only return true once one is found
    //This:QueueState["GotoBookmark", 2000, ${Bookmark}]
    //This:QueueState["SalvageWrecks"]
    
    
    //When full
    //This:QueueState["ReturnToStation"]
    //This:QueueState["Offload"]
  }
  
  member:bool GotoBookmark()
  {
    //Goto that bookmark
  }
  
  member:bool SalvageWrecks()
  {
    //Tractor, loot and salvage
    //True when done 
  }
  
  member:bool ReturnToStation()
  {
    //Dock at station
  }
  
  member:bool Offload()
  {
    //Transfer stuff to corp hanger
  }
  
}