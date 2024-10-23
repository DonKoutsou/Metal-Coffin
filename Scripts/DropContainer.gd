extends PanelContainer
class_name DropContainer

@export var ItemC : ItemContainer

func AddIcon(text : Texture) -> void:
	$TextureRect.texture = text
