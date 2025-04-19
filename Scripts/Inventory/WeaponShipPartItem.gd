@tool
extends ShipPart

class_name WeaponShipPartItem

@export var WType : WeaponType

func GetItemDesc() -> String:
	var Desc = "Weapon type : {0}\n".format([WeaponType.keys()[WType]])
	Desc += super()

	return Desc

enum WeaponType{
	MISSILE_POD,
	MACHINE_GUN,
}
