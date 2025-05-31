extends CardModule
class_name DrawCardModule

@export var DrawAmmount : int
@export var DiscardAmmount : int

func GetDesc(Tier : int) -> String:
	return "Draw {0}, Discard {1}".format([GetDrawAmmount(Tier), DiscardAmmount])

func GetDrawAmmount(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(DrawAmmount + roundi((TierUpgrade * Tier)))
	return roundi(DrawAmmount * roundi(max((TierUpgrade * Tier), 1)))
