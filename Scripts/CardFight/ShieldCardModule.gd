extends DeffenceCardModule

class_name ShieldCardModule

@export var ShieldAmm : int = 10

func GetDesc(Tier : int) -> String:
	if (AOE):
		return "[color=#6be2e9]+{0} Shield[/color] for team".format([ShieldAmm * max((TierUpgrade * Tier), 1)])
	return "[color=#6be2e9]+{0} Shield[/color] for self".format([ShieldAmm * max((TierUpgrade * Tier), 1)])

func GetShieldAmm(Tier : float) -> float:
	return ShieldAmm * max((TierUpgrade * Tier), 1)
