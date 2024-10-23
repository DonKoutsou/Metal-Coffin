extends PanelContainer

class_name InventoryTrade
var InventoryBoxes : Array[Inventory_Box] = []
var DropBoxes : Array[Inventory_Box] = []
@export var InventoryBoxScene : PackedScene

signal TradeFinished(InventoryContents : Array[Item])

func StartTrade(InventoryContents : Array[Item], Drops : Array[Item]) -> void:
	for z in InventoryContents.size():
		var placed = false
		for g in InventoryBoxes.size() :
			var box = InventoryBoxes[g]
			if (box.ItemC.ItemType == InventoryContents[z]):
				if (box.ItemC.ItemType.MaxStackCount == box.ItemC.Ammount):
					continue
				box.UpdateAmm(1)
				placed = true
		if (placed):
			continue
		
		var newbox = InventoryBoxScene.instantiate() as Inventory_Box
		$VBoxContainer/HBoxContainer/VBoxContainer/InvContents.add_child(newbox)
		newbox.RegisterItem(InventoryContents[z])
		newbox.UpdateAmm(1)
		InventoryBoxes.append(newbox)
		
		newbox.connect("ItemUse", ItemMoveInv)
	for z in Drops.size():
		var placed = false
		for g in DropBoxes.size() :
			var box = DropBoxes[g]
			if (box.ItemC.ItemType == Drops[z]):
				box.UpdateAmm(1)
				placed = true
		if (placed):
			continue
		
		var newbox = InventoryBoxScene.instantiate() as Inventory_Box
		$VBoxContainer/HBoxContainer/VBoxContainer2/DropContents.add_child(newbox)
		newbox.RegisterItem(Drops[z])
		newbox.UpdateAmm(1)
		DropBoxes.append(newbox)
		newbox.connect("ItemUse", ItemMoveDrop)
func ItemMoveInv(it : Item) -> void:
	for z in InventoryBoxes.size():
		var box = InventoryBoxes[z]
		if (box.ItemC.ItemType == it):
			box.UpdateAmm(-1)
			break
	var placed = false
	for g in DropBoxes.size() :
		var box = DropBoxes[g]
		if (box.ItemC.ItemType == it):
			box.UpdateAmm(1)
			placed = true
			break
	if (!placed):
		for g in DropBoxes.size() :
			var box = DropBoxes[g]
			if (box.IsEmpty()):
				box.UpdateAmm(1)
				box.RegisterItem(it)
				placed = true
				break
	if (placed):
		return
	
	var newbox = InventoryBoxScene.instantiate() as Inventory_Box
	$VBoxContainer/HBoxContainer/VBoxContainer2/DropContents.add_child(newbox)
	newbox.RegisterItem(it)
	newbox.UpdateAmm(1)
	DropBoxes.append(newbox)
	newbox.connect("ItemUse", ItemMoveDrop)
	
func ItemMoveDrop(it : Item) -> void:
	var placed = false
	for g in InventoryBoxes.size() :
		var box = InventoryBoxes[g]
		if (box.ItemC.ItemType == it):
			if (box.ItemC.ItemType.MaxStackCount == box.ItemC.Ammount):
				continue
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
		if (box.ItemC.ItemType == it):
			box.UpdateAmm(-1)
			break

func _on_button_pressed() -> void:
	var itms : Array[Item]
	for g in InventoryBoxes.size():
		for z in InventoryBoxes[g].ItemC.Ammount:
			itms.append(InventoryBoxes[g].ItemC.ItemType)
	TradeFinished.emit(itms)
	queue_free()
