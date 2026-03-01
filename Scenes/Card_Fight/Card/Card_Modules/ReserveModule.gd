extends DeffenceCardModule
class_name ReserveModule

@export var ReserveAmmount : int = 5

func GetDesc(Tier : int) -> String:
	if (AOE):
		return "Adds [color=#ffc315]{0}[/color] Energy Reserve to team".format([GetEnergy(Tier)])
	return "Adds [color=#ffc315]{0}[/color] Energy Reserve to self".format([GetEnergy(Tier)])

func GetEnergy(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(ReserveAmmount + (Tier * TierUpgrade))
	return roundi(ReserveAmmount * max((Tier * TierUpgrade), 1))
