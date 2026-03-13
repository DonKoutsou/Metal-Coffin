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

func HandleCardInject(_Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var TargetViz : Array[Control]
	
	#var Callables : Array[Callable]
	var injectAmm : int = GetCardAmmount(Action.Tier)
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		for injection in injectAmm:
			var c = CardToInject.duplicate()
			var randomIndex = randf_range(0, g.deck.DeckPile.size())
			g.deck.DeckPile.insert(randomIndex ,c)

	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	#Data.Callables = Callables
	return Data
