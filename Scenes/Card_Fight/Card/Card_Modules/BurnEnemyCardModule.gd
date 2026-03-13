extends OffensiveCardModule
class_name BurnEnemyCardModule

@export var ammToBurn : int

func NeedsTargetSelect() -> bool:
	return true

func GetDesc(Tier : int) -> String:
	if (AOE):
		return "Burn {0} cards on each enemy ship's deck".format([GetBurnAmmount(Tier)])
	return "Burn {0} cards on target ship's deck".format([GetBurnAmmount(Tier)])

func GetBattleDesc(_User : BattleShipStats, Tier : int) -> String:
	if (AOE):
		return "Burn {0} cards on each enemy ship's deck".format([GetBurnAmmount(Tier)])
	return "Burn {0} cards on target ship's deck".format([GetBurnAmmount(Tier)])
	
func GetBurnAmmount(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(ammToBurn + (TierUpgrade * Tier))
	return roundi(ammToBurn * max((TierUpgrade * Tier), 1))
