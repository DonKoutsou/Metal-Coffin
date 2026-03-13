extends DeffenceCardModule
class_name LoseBuffSelfModule

@export var StatToStrip : Stat

func GetDesc(_Tier : int) -> String:
	var TextColor : String
	if (StatToStrip == Stat.FIREPOWER):
		TextColor = "color=#f35033"
	else : if (StatToStrip == Stat.SPEED):
		TextColor = "color=#308a4d"
	else : if (StatToStrip == Stat.DEFENCE):
		TextColor = "color=#7bb0b4"
	else : if (StatToStrip == Stat.WEIGHT):
		TextColor = "color=#828dff"
	if (AOE):
		return "Strip enemy team [{1}]{0}[/color] buffs".format([Stat.keys()[StatToStrip], TextColor])
	return "Strip [{1}]{0}[/color] buffs from self".format([Stat.keys()[StatToStrip], TextColor])

func NeedsTargetSelect() -> bool:
	return true

func HandleBuffStrip(Performer : BattleShipStats, Targets : Array[BattleShipStats]) -> DeffensiveAnimationData:
	var TargetViz : Array[Control]
	
	var Callables : Array[Callable]

	for g in Targets:
		if (g == null):
			continue
		TargetViz.append(g.ShipViz)
		Callables.append(g.StripBuffFromShip.bind(StatToStrip))

		
	var Data = DeffensiveAnimationData.new()
	Data.Mod = self
	Data.Targets = TargetViz
	Data.Callables = Callables
	return Data
