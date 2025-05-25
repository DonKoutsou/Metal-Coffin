@tool
extends Item

class_name AmmoItem

@export var WType : CardStats.WeaponType

func GetItemDesc() -> String:
	var Desc = "[color=#ffc315]REQUIRES {0}[/color]\n{1}".format([CardStats.WeaponType.keys()[WType].to_upper() ,ItemDesc])
	return Desc
