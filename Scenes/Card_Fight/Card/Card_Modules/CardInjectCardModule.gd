extends OffensiveCardModule
class_name CardInjectCardModule

@export var CardToInject : CardStats
@export var amm : int

func NeedsTargetSelect() -> bool:
	return true

func GetDesc(Tier : int) -> String:
	if (AOE):
		return "Add {0} {1} on each enemy ship's deck".format([GetCardAmmount(Tier), CardToInject.GetCardName()])
	return "Add {0} {1} on target ship's deck".format([GetCardAmmount(Tier), CardToInject.GetCardName()])

func GetBattleDesc(_User : BattleShipStats, Tier : int) -> String:
	if (AOE):
		return "Add {0} {1} on each enemy ship's deck".format([GetCardAmmount(Tier), CardToInject.GetCardName()])
	return "Add {0} {1} on target ship's deck".format([GetCardAmmount(Tier), CardToInject.GetCardName()])
	
func GetCardAmmount(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(amm + (TierUpgrade * Tier))
	return roundi(amm * max((TierUpgrade * Tier), 1))
