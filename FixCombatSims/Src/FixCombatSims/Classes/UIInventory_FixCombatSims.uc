class UIInventory_FixCombatSims extends UIInventory;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	List.OnItemClicked = OnItemSelected;

	ItemCard.SetPosition(1200, 0);
	SetInventoryLayout();
	PopulateData();
}

simulated function PopulateData()
{
	
}

simulated function OnItemSelected(UIList ContainerList, int ItemIndex)
{
}
