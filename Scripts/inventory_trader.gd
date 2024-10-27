extends PanelContainer

class_name InventoryTrade
var InventoryBoxes : Array[Inventory_Box] = []
var DropBoxes : Array[Inventory_Box] = []
@export var InventoryBoxScene : PackedScene

signal TradeFinished(InventoryContents : Array[Item])

func StartTrade(InventoryContents : Array[Item], Drops : Array[Item]) -> void:
	for g in ShipData.GetInstance().GetStat("INVENTORY_CAPACITY").GetStat():
		var newbox = InventoryBoxScene.instantiate() as Inventory_Box
		$VBoxContainer/HBoxContainer/VBoxContainer/InvContents.add_child(newbox)
		InventoryBoxes.append(newbox)
		newbox.connect("ItemUse", ItemMoveInv)
	for z in InventoryContents.size():
		var placed = false
		for g in InventoryBoxes.size() :
			var box = InventoryBoxes[g]
			if (box.ItemC.ItemType == InventoryContents[z]):
				if (!box.HasSpace()):
					continue
				box.UpdateAmm(1)
				placed = true
				break
		if (!placed):
			for g in InventoryBoxes.size() :
				var box = InventoryBoxes[g]
				if (box.IsEmpty()):
					box.UpdateAmm(1)
					box.RegisterItem(InventoryContents[z])
					placed = true
					break
		#if (placed):
			#continue
		
		#var newbox = InventoryBoxScene.instantiate() as Inventory_Box
		#$VBoxContainer/HBoxContainer/VBoxContainer/InvContents.add_child(newbox)
		#newbox.RegisterItem(InventoryContents[z])
		#newbox.UpdateAmm(1)
		#InventoryBoxes.append(newbox)
		
	for z in Drops.size():
		var placed = false
		for g in DropBoxes.size() :
			var box = DropBoxes[g]
			if (box.ItemC.ItemType == Drops[z]):
				box.UpdateAmm(1)
				placed = true
				break
		if (placed):
			continue
		
		var newbox = InventoryBoxScene.instantiate() as Inventory_Box
		$VBoxContainer/HBoxContainer/VBoxContainer2/DropContents.add_child(newbox)
		newbox.RegisterItem(Drops[z])
		newbox.UpdateAmm(1)
		DropBoxes.append(newbox)
		newbox.connect("ItemUse", ItemMoveDrop)
func ItemMoveInv(ItCo : ItemContainer) -> void:
	var it = ItCo.ItemType as Item
	for z in InventoryBoxes.size():
		var box = InventoryBoxes[z]
		if (box.ItemC == ItCo):
			box.UpdateAmm(-1)
			break
			
	
		
	for g in DropBoxes.size() :
		var box = DropBoxes[g]
		if (box.ItemC.ItemType == it):
			box.UpdateAmm(1)
			return
			
	for g in DropBoxes.size() :
		var box = DropBoxes[g]
		if (box.IsEmpty()):
			box.UpdateAmm(1)
			box.RegisterItem(it)
			return
	
	var newbox = InventoryBoxScene.instantiate() as Inventory_Box
	$VBoxContainer/HBoxContainer/VBoxContainer2/DropContents.add_child(newbox)
	newbox.RegisterItem(it)
	newbox.UpdateAmm(1)
	DropBoxes.append(newbox)
	newbox.connect("ItemUse", ItemMoveDrop)
	
func ItemMoveDrop(ItCo : ItemContainer) -> void:
	var it = ItCo.ItemType
	var placed = false
	for g in InventoryBoxes.size() :
		var box = InventoryBoxes[g]
		if (box.ItemC.ItemType == it and box.HasSpace()):
			box.UpdateAmm(1)
			placed = true
			break
	if (!placed):
		for g in InventoryBoxes.size() :
			var box = InventoryBoxes[g]
			if (box.IsEmpty()):
				box.UpdateAmm(1)
				box.RegisterItem(it)
				placed = true
				break	
	if (!placed):
		return
	for z in DropBoxes.size():
		var box = DropBoxes[z]
		if (box.ItemC == ItCo):
			box.UpdateAmm(-1)
			break

func _on_button_pressed() -> void:
	var itms : Array[Item]
	for g in InventoryBoxes.size():
		for z in InventoryBoxes[g].ItemC.Ammount:
			itms.append(InventoryBoxes[g].ItemC.ItemType)
	TradeFinished.emit(itms)
	queue_free()
