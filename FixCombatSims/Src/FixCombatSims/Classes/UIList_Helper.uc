class UIListHelper extends Object;

simulated function MoveItemToIndex(UIList List, UIPanel Item, int NewIndex)
{
	local int StartingIndex, ItemIndex;

	if (NewIndex < 0)
	{
		NewIndex = List.ItemCount;
	}
	else if (NewIndex >= List.ItemCount)
	{
		NewIndex = List.ItemCount - 1;
	}

	StartingIndex = List.GetItemIndex(Item);

	if(StartingIndex != INDEX_NONE)
	{
		if(List.SelectedIndex > INDEX_NONE && List.SelectedIndex < List.ItemCount)
			List.GetSelectedItem().OnLoseFocus();

		ItemIndex = StartingIndex;
		while(ItemIndex > NewIndex)
		{
			List.ItemContainer.SwapChildren(ItemIndex, ItemIndex - 1);
			ItemIndex--;
		}

		ItemIndex = StartingIndex;
		while(ItemIndex < NewIndex)
		{
			List.ItemContainer.SwapChildren(ItemIndex, ItemIndex + 1);
			ItemIndex++;
		}

		List.RealizeItems();

		if(List.SelectedIndex > INDEX_NONE && List.SelectedIndex < List.ItemCount)
			List.GetSelectedItem().OnReceiveFocus();
	}

	//if we move the currently selected item to the top, change the selection to the item that got moved into that location
	if(StartingIndex == List.SelectedIndex && List.OnSelectionChanged != none)
		List.OnSelectionChanged(List, List.SelectedIndex);
}
