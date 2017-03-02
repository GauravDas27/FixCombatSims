class UIScreenListener_FixCombatSims extends UIScreenListener config(FixCombatSims);

var config array<name> CombatSims;

event OnInit(UIScreen Screen)
{
	CheckUnit(UIArmory(Screen));
}

event OnReceiveFocus(UIScreen Screen)
{
	CheckUnit(UIArmory(Screen));
}

function CheckUnit(UIArmory Armory)
{
	local XComGameState_Unit Unit;
	local array<XComGameState_Item> BadCombatSims;

	Unit = Armory.GetUnit();
	BadCombatSims = GetBadCombatSims(Unit);

	if (BadCombatSims.Length == 0) return;

	FixBadCombatSims(Unit, BadCombatSims);
}

function array<XComGameState_Item> GetBadCombatSims(XComGameState_Unit Unit)
{
	local array<XComGameState_Item> BadCombatSims;
	local array<XComGameState_Item> UnitItems;
	local XComGameState_Item Item;
	local int Index;

	`log("FixCombatSims: Checking unit " $ Unit.GetFullName() $ " " $ Unit.Name);

	UnitItems = Unit.GetAllInventoryItems();
	foreach UnitItems(Item)
	{
		if (Item.InventorySlot != eInvSlot_Unknown) continue; // bad combat sims are present in Unknown inventory slot

		Index = CombatSims.Find(Item.GetMyTemplateName());
		if (Index != INDEX_NONE)
		{
			// found bad combat sim
			`log("FixCombatSims: Found bad combat sim " $ Item.GetMyTemplateName());
			BadCombatSims.AddItem(Item);
		}
	}

	return BadCombatSims;
}

function FixBadCombatSims(XComGameState_Unit Unit, array<XComGameState_Item> BadCombatSims)
{
	local XComGameState UpdatedState;
	local XComGameState_Unit UpdatedUnit;
	local XComGameState_HeadquartersXCom UpdatedHq;
	local XComGameState_Item CombatSim;

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

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Strategy_UI_PCS_Equip");
	`GAMERULES.SubmitGameState(UpdatedState);

	`log("FixCombatSims: Unit fixed");
}

defaultproperties
{
	ScreenClass = UIArmory_MainMenu;
}
