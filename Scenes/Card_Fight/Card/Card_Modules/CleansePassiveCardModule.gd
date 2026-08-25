extends DeffenceCardModule
class_name CleansePassiveModule

const StatText = "[color=#ffc315]HULL[/color][p][color=#6be2e9]SHIELD[/color][p][color=#308a4d]SPEED[/color][p][color=#f35033]FPWR[/color]"

func GetDesc(Tier : int, _targetOverride : String = "") -> String:
	if (AOE):
		return "Cleanse all team passives."
	else : if (CanBeUsedOnOther):
		return "Cleanse all of a ship's passives."
	return "Cleanse all passives on self."

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
		Callables.append(g.CleansePassives)
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data
