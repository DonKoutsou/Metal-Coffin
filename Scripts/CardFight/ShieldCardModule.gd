extends DeffenceCardModule

class_name ShieldCardModule

@export var ShieldAmm : int = 10

func GetDesc(Tier : int) -> String:
	if (AOE):
		return "[color=#6be2e9]+{0} Shield[/color] for team".format([GetShieldAmm(Tier)])
	return "[color=#6be2e9]+{0} Shield[/color] for self".format([GetShieldAmm(Tier)])

func GetShieldAmm(Tier : float) -> float:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return ShieldAmm + (TierUpgrade * Tier)
	return ShieldAmm * max((TierUpgrade * Tier), 1)
