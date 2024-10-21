extends PanelContainer
class_name Inventory_Box

@export var ItemC : ItemContainer

signal ItemUse(it : Item)

func UpdateAmm(Amm : int) -> void:
	ItemC.Ammount += Amm
	$PanelContainer/Label.text = var_to_str(ItemC.Ammount)
	if (ItemC.Ammount == 0):
		queue_free()
func AddIcon(text : Texture) -> void:
	$TextureRect.icon = text

func _on_texture_rect_pressed() -> void:
	#UpdateAmm(-1)
	if (ItemC.Ammount <= 0):
		return
	ItemUse.emit(ItemC.ItemType)
