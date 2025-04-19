@tool
extends ShipPart

class_name WeaponShipPart

@export var WType : WeaponType

func GetItemDesc() -> String:
	var Desc = "WEAPON TYPE : [color=#ffc315]{0}[/color]\n".format([WeaponType.keys()[WType]])
	Desc += super()

	return Desc

enum WeaponType{
	MISSILE_POD,
	MACHINE_GUN,
}
