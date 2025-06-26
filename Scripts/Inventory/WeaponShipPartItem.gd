@tool
extends ShipPart

class_name WeaponShipPart

@export var WType : CardStats.WeaponType

func GetItemDesc() -> String:
	var Desc = "WEAPON TYPE : [color=#ffc315]{0}[/color]\n[color=#ffc315]-------------[/color]\n".format([CardStats.WeaponType.keys()[WType]])
	Desc += super()

	return Desc

func GetWorkshopItemDesc() -> String:
	return "WEAPON TYPE : [color=#ffc315]{0}[/color]\n".format([CardStats.WeaponType.keys()[WType]]) + super()


#enum WeaponType{
	#MISSILE_POD,
	#MACHINE_GUN,
#}
