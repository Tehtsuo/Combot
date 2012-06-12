
objectdef obj_Bookmarks
{
	variable index:string TemporaryBookMarks
	variable string StoredLocation = ""
		
	method Initialize()
	{
		UI:Update["obj_Bookmarks", "Initialized", "g"]
	}

	method Shutdown()
	{
	}
	
	method StoreLocation()
	{
		UI:Update["obj_Bookmarks", "Storing current location", "y"]
		This.StoredLocation:Set["${Math.Rand[5000]:Inc[1000]}"]
		EVE:CreateBookmark["${This.StoredLocation}"]
	}
	
	member:bool CheckForStoredLocation()
	{
		return ${StoredLocation.Length} != 0
	}
	
	method RemoveStoredLocation()
	{
		if ${This.StoredLocationExists}
		{
			EVE.Bookmark["${This.StoredLocation}"]:Remove
			StoredLocation:Set[""]
		}
	}
	
	member:bool StoredLocationExists()
	{
		if ${This.StoredLocation.Length} > 0
		{
			return ${EVE.Bookmark["${This.StoredLocation}"](exists)}
		}
		return FALSE
	}

}