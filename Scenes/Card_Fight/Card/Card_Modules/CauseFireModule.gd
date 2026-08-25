extends DeffenceCardModule

class_name CauseFireModule

func GetDesc(_Tier : int, _targetOverride : String = "") -> String:
	return "[color=#ff3c22]{0}[/color]".format([TranslationServer.translate("Cause fire")])

func NeedsTargetSelect() -> bool:
	return true

func Handle(Performer : BattleShipStats, Action : CardStats, Targets : Array[BattleShipStats] = []) -> AnimationData:
	if (Action.Burned):
		return DeffensiveAnimationData.new()
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]
	
	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz.ShipIcon)
		Callables.append(g.CauseFire.bind(Performer))
		
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data
