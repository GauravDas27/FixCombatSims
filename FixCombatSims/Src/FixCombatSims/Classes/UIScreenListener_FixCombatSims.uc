class UIScreenListener_FixCombatSims extends UIScreenListener config(FixCombatSims);

var config array<name> CombatSims;
var config bool FIX_SILENTLY;

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

	if (Armory == None) return; // called from unknown screen

	Unit = Armory.GetUnit();
	PopulateBadCombatSims();

	if (BadCombatSims.Length <= 0) return; // unit is good

	// TODO : override PCS option on UIArmory_MainMenu screen
	ListItem = UIListItemString(Armory.List.GetItem(2));
	if (ListItem == None || FIX_SILENTLY)
	{
		// if list item is not found or SILENT_FIX is enabled in config; silently fix combat sims and refresh UI
		`log("FixCombatSims: Fixing silently " $ Unit.GetFullName());
		FixBadCombatSims();
		Armory.CycleToSoldier(Armory.UnitReference);
		return;
	}

	ListItem.SetBad(true);
	ListItem.ButtonBG.OnClickedDelegate = OnClick;
}

function OnClick(UIButton Button)
{
	local UIScreenStack ScreenStack;
	local XComHQPresentationLayer PresLayer;
	local UIInventory_FixCombatSims UiFcs;

	ScreenStack = `SCREENSTACK;
	PresLayer = `HQPRES;
	if (ScreenStack.IsNotInStack(class'UIInventory_FixCombatSims'))
	{
		UiFcs = PresLayer.Spawn(class'UIInventory_FixCombatSims', PresLayer);
		UiFcs.Init(Unit, BadCombatSims);
		ScreenStack.Push(UiFcs, PresLayer.Get3DMovie());
	}
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
			`log("FixCombatSims: Found " $ Item.GetMyTemplateName());
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
