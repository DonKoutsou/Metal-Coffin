extends CardModule
class_name SelfDamageModule

@export var Damage : float

func GetDesc() -> String:
	return "Cause [color=#c19200]{0}[/color] damage to self".format([Damage]).replace(".0", "")
