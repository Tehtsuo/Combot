function main()
{
	echo Inventory window exists:  ${EVEWindow[Inventory](exists)}

	variable index:string Names
	variable index:int64 IDs
	variable iterator Name
		
		
	EVEWindow[Inventory]:GetChildren[Names, IDs]
	Names:GetIterator[Name]
	if ${Name:First(exists)}
		do
		{
			echo ------------------------------------
			echo Name:         ${Name.Value}
		}
		while ${Name:Next(exists)}
	IDs:GetIterator[Name]
	if ${Name:First(exists)}
		do
		{
			echo ------------------------------------
			echo ID:         ${Name.Value}
		}
		while ${Name:Next(exists)}
	

}