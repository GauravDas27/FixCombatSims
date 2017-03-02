class UIInventory_FixCombatSims extends UIInventory;

var XComGameState_Unit Unit;
var array<XComGameState_Item> BadCombatSims;

function Init(XComGameState_Unit Unit, array<XComGameState_Item> BadCombatSims)
{
	self.Unit = Unit;
	self.BadCombatSims = BadCombatSims;
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	m_strTitle = class'UIInventory_Implants'.default.m_strTitle;
	m_strInventoryLabel = "";
	m_strTotalLabel = "";

	super.InitScreen(InitController, InitMovie, InitName);

	`log("FixCombatSims: Unit " $ Unit.GetFullName());

	List.OnItemClicked = OnItemSelected;

	ItemCard.SetPosition(1200, 0);
	SetInventoryLayout();
	PopulateData();
}

simulated function PopulateData()
{
	local XComGameState_Item CombatSim;
	local UIInventory_ListItem ListItem;

	super.PopulateData();

	if (BadCombatSims.Length <= 0)
	{
		CloseScreen();
		return;
	}

	foreach BadCombatSims(CombatSim)
	{
		UIInventory_ListItem(List.CreateItem(class'UIInventory_ListItem')).InitInventoryListItem(CombatSim.GetMyTemplate(), 0, CombatSim.GetReference());
	}

	ListItem = UIInventory_ListItem(List.GetItem(0));
	PopulateItemCard(ListItem.ItemTemplate, ListItem.ItemRef);

	List.SetSelectedIndex(0);
}

simulated function OnItemSelected(UIList ContainerList, int ItemIndex)
{
	local XComGameState_Item CombatSim;
	local XComGameState UpdatedState;
	local XComGameState_Unit UpdatedUnit;
	local XComGameState_HeadquartersXCom UpdatedHq;

	CombatSim = BadCombatSims[ItemIndex];
	UpdatedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Fix Personal Combat Sim");

	UpdatedUnit = XComGameState_Unit(UpdatedState.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));
	UpdatedUnit.RemoveItemFromInventory(CombatSim, UpdatedState);
	UpdatedUnit.UnapplyCombatSimStats(CombatSim);
	UpdatedState.AddStateObject(UpdatedUnit);

	UpdatedHq = class'UIUtilities_Strategy'.static.GetXComHQ();
	UpdatedState.AddStateObject(UpdatedHq);
	UpdatedHq.PutItemInInventory(UpdatedState, CombatSim);

	`GAMERULES.SubmitGameState(UpdatedState);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Strategy_UI_PCS_Equip");

	Unit = UpdatedUnit;
	BadCombatSims.Remove(ItemIndex, 1);
	`log("FixCombatSims: Removed " $ CombatSim.GetMyTemplateName());

	PopulateData();
}

defaultproperties
{
	bHideOnLoseFocus = false;
	InputState = eInputState_Consume; // don't cascade input down into the armory
	DisplayTag = "UIBlueprint_Promotion";
	CameraTag = "UIBlueprint_Promotion";
}
