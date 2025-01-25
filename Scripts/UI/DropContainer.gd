extends PanelContainer
class_name DropContainer

@export var ItemC : ItemContainer

func AddIcon(text : Texture) -> void:
	$TextureRect.texture = text
func UpdateIcontColor(Col : Color) -> void:
	$TextureRect.modulate = Col
