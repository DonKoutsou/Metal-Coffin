extends DeffenceCardModule
class_name HandCardEnergyReduceModule

@export var CardAmm : int = 3
@export var ReduceAmm : int = 1

const StatText = "[color=#ffc315]HULL[/color][p][color=#6be2e9]SHIELD[/color][p][color=#308a4d]SPEED[/color][p][color=#f35033]FPWR[/color]"

func NeedsTargetSelect() -> bool:
	return true

func GetDesc(Tier : int) -> String:
	return "Reduce the energy cost of [color=#ffc315]{0}[/color] cards in hand by [color=#ffc315]{1}[/color]".format([GetCardAmm(Tier), GetReductionAmm(Tier)])

func GetCardAmm(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(CardAmm + (TierUpgrade * Tier))
	return roundi(CardAmm * max((TierUpgrade * Tier), 1))
	
func GetReductionAmm(Tier : int) -> int:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return roundi(ReduceAmm + (TierUpgrade * Tier))
	return ReduceAmm * max((TierUpgrade * Tier), 1)

func Handle(Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		var hand = g.deck.Hand.duplicate()
		hand.shuffle()
		for i in GetCardAmm(Action.Tier):
			var c = hand.pop_back()
			if (c == null):
				continue
			c.EnergyReduction += GetReductionAmm(Action.Tier)
			
	Performer.CardsBuffed.emit()
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data
