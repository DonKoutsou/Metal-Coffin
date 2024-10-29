extends PanelContainer

class_name ItemNotifContainer

@export var ItemC : ItemContainer

func AddIcon(text : Texture) -> void:
	$TextureRect.texture = text
func UpdateIcontColor(Col : Color) -> void:
	$TextureRect.modulate = Col
func UpdateAmm(Amm : int) -> int:
	ItemC.Ammount += Amm
	$PanelContainer/Label.text = var_to_str(ItemC.Ammount)
	return ItemC.Ammount
