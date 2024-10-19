extends HBoxContainer
class_name Inventory

@export var InventoryBoxScene : PackedScene
var InventoryContents : Array[Inventory_Box] = []

signal OnItemAdded(It : Item)
# Called when the node enters the scene tree for the first time.

func AddItem(It : Item) -> void:
	OnItemAdded.emit(It)
	for g in InventoryContents.size() :
		var box = InventoryContents[g]
		if (box.ItemC.ItemType == It):
			box.UpdateAmm(1)
			return
	var newbox = InventoryBoxScene.instantiate() as Inventory_Box
	add_child(newbox)
	var newcont = ItemContainer.new()
	newcont.ItemType = It
	newbox.AddIcon(newcont.ItemType.ItemIcon)
	newbox.ItemC = newcont
	newbox.UpdateAmm(1)
	InventoryContents.insert(InventoryContents.size(),newbox)
