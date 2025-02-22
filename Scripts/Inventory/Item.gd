@tool
extends Resource
class_name Item

@export var ItemIcon : Texture
@export var ItemIconSmol : Texture
@export var ItemName = "ItemName"
@export var ItemDesc = "ItemDesc"
@export var MaxStackCount = 1
#@export var RandomFindMaxCount = 1
@export var CardProviding : CardStats
@export var CardOptionProviding : CardOption

func GetItemDesc() -> String:
	return ItemDesc
