class UIScreenListener_FixCombatSims extends UIScreenListener config(FixCombatSims);

var config array<name> CombatSims;
var config bool FIX_SILENTLY;

var localized string m_strFixCombatSims;

var UIArmory_MainMenu Armory;
var XComGameState_Unit Unit;
var array<XComGameState_Item> BadCombatSims;

event OnInit(UIScreen Screen)
{
	Armory = UIArmory_MainMenu(Screen);
	PopulateData(Armory);
}

event OnReceiveFocus(UIScreen Screen)
{
	PopulateData(Armory);
}

function PopulateData(UIArmory_MainMenu Armory)
{
	local UIListItemString ListItem;
	local UIPanel PcsItem;
	local int Index;

	if (Armory == None) return; // called from unknown screen

	Unit = Armory.GetUnit();
	PopulateBadCombatSims();

	if (BadCombatSims.Length <= 0) return; // unit is good

	if (FIX_SILENTLY)
	{
		// silently fix combat sims and refresh UI
		`log("FixCombatSims: Fixing silently " $ Unit.GetFullName());
		FixBadCombatSims();
		Armory.CycleToSoldier(Armory.UnitReference);
		return;
	}

	ListItem = Armory.Spawn(class'UIListItemString', Armory.List.ItemContainer).InitListItem(m_strFixCombatSims); 
	ListItem.MCName = 'ArmoryMainMenu_FixCombatSimsButton';
	ListItem.SetBad(true);
	ListItem.NeedsAttention(true);
	ListItem.SetDisabled(Unit.GetStatus() == eStatus_OnMission);
	ListItem.ButtonBG.OnClickedDelegate = OnClick;

	PcsItem = Armory.List.GetChildByName('ArmoryMainMenu_PCSButton', false);
	Index = PcsItem == None ? INDEX_NONE : Armory.List.GetItemIndex(PcsItem);
	if (Index != INDEX_NONE)
	{
		class'UIList_Helper'.static.MoveItemToIndex(Armory.List, ListItem, Index + 1);
	}
}

function OnClick(UIButton Button)
{
	local UIListItemString Parent;
	local UIScreenStack ScreenStack;
	local XComHQPresentationLayer PresLayer;
	local UIInventory_FixCombatSims UiFcs;

	Parent = UIListItemString(Button.ParentPanel);
	if (Parent != None && Parent.bDisabled)
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuClickNegative");
		return;
	}

	ScreenStack = `SCREENSTACK;
	PresLayer = `HQPRES;
	if (ScreenStack.IsNotInStack(class'UIInventory_FixCombatSims'))
	{
		UiFcs = PresLayer.Spawn(class'UIInventory_FixCombatSims', PresLayer);
		UiFcs.Init(Unit, BadCombatSims);
		ScreenStack.Push(UiFcs, PresLayer.Get3DMovie());
	}
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}

function PopulateBadCombatSims()
{
	local array<XComGameState_Item> UnitItems;
	local XComGameState_Item Item;
	local int Index;

	BadCombatSims.Length = 0;
	UnitItems = Unit.GetAllInventoryItems();
	foreach UnitItems(Item)
	{
		if (Item.InventorySlot != eInvSlot_Unknown) continue; // bad combat sims are present in Unknown inventory slot

		Index = CombatSims.Find(Item.GetMyTemplateName());
		if (Index != INDEX_NONE)
		{
			// found bad combat sim
			BadCombatSims.AddItem(Item);
		}
	}
}

function FixBadCombatSims()
{
	local XComGameState_Item CombatSim;
	local XComGameState UpdatedState;
	local XComGameState_Unit UpdatedUnit;
	local XComGameState_HeadquartersXCom UpdatedHq;

	UpdatedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Fix Personal Combat Sims");
	UpdatedUnit = Unit;
	UpdatedHq = class'UIUtilities_Strategy'.static.GetXComHQ();

	foreach BadCombatSims(CombatSim)
	{
		UpdatedUnit = XComGameState_Unit(UpdatedState.CreateStateObject(class'XComGameState_Unit', UpdatedUnit.ObjectID));
		UpdatedUnit.RemoveItemFromInventory(CombatSim, UpdatedState);
		UpdatedUnit.UnapplyCombatSimStats(CombatSim);
		UpdatedState.AddStateObject(UpdatedUnit);

		UpdatedHq = XComGameState_HeadquartersXCom(UpdatedState.CreateStateObject(class'XComGameState_HeadquartersXCom', UpdatedHq.ObjectID));
		UpdatedState.AddStateObject(UpdatedHq);
		UpdatedHq.PutItemInInventory(UpdatedState, CombatSim);
	}

	`GAMERULES.SubmitGameState(UpdatedState);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Strategy_UI_PCS_Equip");

	Unit = UpdatedUnit;
	`log("FixCombatSims: Fixed unit " $ Unit.GetFullName());
}

defaultproperties
{
	ScreenClass = UIArmory_MainMenu;
}
