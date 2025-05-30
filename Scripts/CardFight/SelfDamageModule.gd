extends CardModule
class_name SelfDamageModule

@export var Damage : float

func GetDesc(Tier : int) -> String:
	return "Cause [color=#ffc315]{0}[/color] damage to self".format([Damage * max((TierUpgrade * Tier), 1)]).replace(".0", "")
