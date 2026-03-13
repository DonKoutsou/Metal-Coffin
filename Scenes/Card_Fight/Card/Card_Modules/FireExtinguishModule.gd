extends DeffenceCardModule

class_name FireExtinguishModule

func GetDesc(_Tier : int) -> String:
	return "Extinguishes [color=#ff3c22]fires[/color] on ship"

func NeedsTargetSelect() -> bool:
	return true

func HandleFireExtinguish(Performer : BattleShipStats, _Action : CardStats) -> DeffensiveAnimationData:
	
	var Callables : Array[Callable] = [Performer.CombustFire]
	
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets.append(Performer.ShipViz)
	Data.Callables = Callables
	return Data
