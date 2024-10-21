extends PanelContainer
class_name ItemNotif

@export var InventoryBoxScene : PackedScene
var InventoryContents : Array[Inventory_Box] = []

func AddItems(It : Array[Item]) -> void:
	for z in It.size():
		var placed = false
		for g in InventoryContents.size() :
			var box = InventoryContents[g]
			if (box.ItemC.ItemType == It[z]):
				box.UpdateAmm(1)
				placed = true
		if (placed):
			continue
		var newbox = InventoryBoxScene.instantiate() as Inventory_Box
		$VBoxContainer/HBoxContainer.add_child(newbox)
		var newcont = ItemContainer.new()
		newcont.ItemType = It[z]
		newbox.AddIcon(newcont.ItemType.ItemIcon)
		newbox.ItemC = newcont
		newbox.UpdateAmm(1)
		InventoryContents.append(newbox)


func _on_button_pressed() -> void:
	queue_free()
