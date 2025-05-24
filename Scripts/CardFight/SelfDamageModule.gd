extends CardModule
class_name SelfDamageModule

@export var Damage : float

func GetDesc() -> String:
	return "Cause [color=#ffc315]{0}[/color] damage to self".format([Damage]).replace(".0", "")
