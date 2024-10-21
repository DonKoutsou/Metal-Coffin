extends PanelContainer
class_name DropContainer

@export var ItemC : ItemContainer

signal ItemUse(it : Item)
	
func AddIcon(text : Texture) -> void:
	$TextureRect.texture = text
