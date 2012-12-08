function main()
{
	variable index:evewindow Windows
	variable iterator Window
	EVE:GetEVEWindows[Windows]
	Windows:GetIterator[Window]

	if ${Window:First(exists)}
		do
		{
			echo ------------------------------------
			echo Name:         ${Window.Value.Name}
			echo Caption:      ${Window.Value.Caption}
			echo Text:         ${Window.Value.Text}
			echo Minimized:    ${Window.Value.Minimized}
			echo Capacity:     ${Window.Value.Capacity}
			echo UsedCapacity: ${Window.Value.UsedCapacity}
			echo HTML:         ${Window.Value.HTML}
		}
		while ${Window:Next(exists)}

	variable index:string Names
	variable index:int64 IDs
	variable iterator Name
		
		
	EVEWindow[ByCaption, Inventory]:GetChildren[Names, IDs]
	Names:GetIterator[Name]
	if ${Name:First(exists)}
		do
		{
			echo ------------------------------------
			echo Name:         ${Name.Value}
		}
		while ${Name:Next(exists)}
	

}