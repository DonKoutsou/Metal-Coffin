@tool
extends Resource
class_name Item

@export var ItemIcon : Texture
@export var ItemIconSmol : Texture
@export var ItemName = "ItemName"
@export_multiline var ItemDesc = "ItemDesc"
@export var MaxStackCount = 1
#@export var RandomFindMaxCount = 1
@export var CardProviding : Array[CardStats] = []
@export var CardOptionProviding : CardOption
@export var CanTransfer : bool = true

func GetItemDesc() -> String:
	return ItemDesc
