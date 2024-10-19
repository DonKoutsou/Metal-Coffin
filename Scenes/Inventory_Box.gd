extends PanelContainer
class_name Inventory_Box

@export var ItemC : ItemContainer

func UpdateAmm(Amm : int) -> void:
	ItemC.Ammount += Amm
	$PanelContainer/Label.text = var_to_str(ItemC.Ammount)
func AddIcon(text : Texture) -> void:
	$TextureRect.texture = text
