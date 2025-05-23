extends PanelContainer
class_name ItemNotif

@export var InventoryBoxScene : PackedScene
var InventoryContents : Array[ItemNotifContainer] = []

var alph = 4

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
		var newbox = InventoryBoxScene.instantiate() as ItemNotifContainer
		$VBoxContainer/HBoxContainer.add_child(newbox)
		var newcont = ItemContainer.new()
		newcont.ItemType = It[z]
		newbox.AddIcon(newcont.ItemType.ItemIcon)
		if (newcont.ItemType is UsableItem):
			newbox.UpdateIcontColor(newcont.ItemType.ItecColor)
		newbox.ItemC = newcont
		newbox.UpdateAmm(1)
		InventoryContents.append(newbox)
	alph = 4

func _on_button_pressed() -> void:
	queue_free()
func _physics_process(_delta: float) -> void:
	if (alph <= 0):
		queue_free()
	alph -= 0.05
	modulate.a = min(1, alph)
	pass
