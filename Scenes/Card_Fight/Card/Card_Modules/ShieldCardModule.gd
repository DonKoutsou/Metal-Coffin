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

func NeedsTargetSelect() -> bool:
	return true

func HandleShield(Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> DeffensiveAnimationData:
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		Callables.append(g.ShieldShip.bind(GetShieldAmm(Action.Tier)))
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data
