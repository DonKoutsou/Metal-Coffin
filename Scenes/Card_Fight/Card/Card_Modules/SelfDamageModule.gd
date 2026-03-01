extends CardModule
class_name SelfDamageModule

@export var Damage : float

func GetDesc(Tier : int) -> String:
	return "Cause [color=#ffc315]{0}[/color] damage to self".format([GetFinalDamage(Tier)]).replace(".0", "")

func GetFinalDamage(Tier : int) -> float:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return Damage + (TierUpgrade * Tier)
	return Damage * max((TierUpgrade * Tier), 1)
