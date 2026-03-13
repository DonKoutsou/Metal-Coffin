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

func Handle(_Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var TargetViz : Array[Control]
	
	#var Callables : Array[Callable]
	var burnAmm : int = GetBurnAmmount(Action.Tier)
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		if (g.deck.DeckPile.is_empty()):
			continue
		for toBurn in burnAmm:
			g.deck.DeckPile.pick_random().Burned = true

	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	#Data.Callables = Callables
	return Data
