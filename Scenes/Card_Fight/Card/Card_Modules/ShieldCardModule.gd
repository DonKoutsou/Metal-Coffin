extends DeffenceCardModule

class_name ShieldCardModule

@export var ShieldAmm : int = 10

func GetDesc(Tier : int, targetOverride : String = "") -> String:
	var targetString : String = ""
	if (targetOverride != ""):
		targetString = targetOverride
	else:
		if (AOE):
			targetString = "team"
		else:
			targetString =  "self"
			
	return "[color=#6be2e9]+{0} Shield[/color] for {1}".format([GetShieldAmm(Tier), targetString]).replace(".0", "")

func GetShieldAmm(Tier : float) -> float:
	if (TierUpgradeMethod == DamageInfo.CalcuationMethod.ADD):
		return ShieldAmm + (TierUpgrade * Tier)
	return ShieldAmm * max((TierUpgrade * Tier), 1)

func NeedsTargetSelect() -> bool:
	return true

func Handle(_Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz.ShipIcon)
		Callables.append(g.ShieldShip.bind(GetShieldAmm(Action.Tier)))
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data
