extends CardModule
class_name StackDamageCardModule

@export var BuffAmmount : float

func GetDesc(Tier : int) -> String:
	return "Card damage + {0}%".format([GetStackDamage(Tier)])

func GetStackDamage(Tier : int) -> float:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(BuffAmmount + (TierUpgrade * Tier) * 100)
	return roundi(BuffAmmount * max((TierUpgrade * Tier), 1) * 100)
