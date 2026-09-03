extends PanelContainer

class_name StatComperator

@export var ContainerBefore : CaptainStatContainer
@export var ContainerAfter : CaptainStatContainer

signal TradeFinished(T : bool)

func SetCaptainsToCompare(CapBefore : Captain, CapAfter : Captain) -> void:
	ContainerBefore.SetCaptain(CapBefore)
	ContainerAfter.SetCaptain(CapAfter)
	ContainerBefore.ShowStats()
	ContainerAfter.ShowStats()
	
	call_deferred("ShowDif", CapBefore, CapAfter)

func ShowDif(CapBefore : Captain, CapAfter : Captain) -> void:
	var difstats : Array[STAT_CONST.STATS] = []
	for g in CapBefore.CaptainStats:
		var beforeStat = g.GetFinalValue()
		var afterStat = CapAfter.GetStatFinalValue(g.StatName)
		if (beforeStat != afterStat):
			difstats.append(g.StatName)
	
	var wBefore = CapBefore.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	var wAfter = CapAfter.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	var SpeedBefore = roundi((CapBefore.GetStatFinalValue(STAT_CONST.STATS.THRUST) * 1000) / CapBefore.GetStatFinalValue(STAT_CONST.STATS.WEIGHT))
	var SpeedAfter = roundi((CapAfter.GetStatFinalValue(STAT_CONST.STATS.THRUST) * 1000) / CapAfter.GetStatFinalValue(STAT_CONST.STATS.WEIGHT))
	if (SpeedBefore != SpeedAfter):
		difstats.append(STAT_CONST.STATS.SPEED)
	
	if (CapAfter.GetValue() != CapBefore.GetValue()):
		difstats.append(STAT_CONST.STATS.VALUE)
	
	
	var fuel_Eff_Before = (CapBefore.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) / pow(wBefore, 0.5)) * 10
	var fuel_Cap_Before = CapBefore.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
	var ShipRange_Before = roundi(fuel_Cap_Before * fuel_Eff_Before)
	
	var fuel_Eff_After = (CapAfter.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) / pow(wAfter, 0.5)) * 10
	var fuel_Cap_After = CapAfter.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
	var ShipRange_After = roundi(fuel_Cap_After * fuel_Eff_After)
	if (ShipRange_After != ShipRange_Before):
		difstats.append(STAT_CONST.STATS.RANGE)
	
	if (CapBefore.GetShipThrust() != CapAfter.GetShipThrust()):
		difstats.append(STAT_CONST.STATS.SOUND_SIGNATURE)
	
	ContainerBefore.ShowOnlyStats(difstats)
	ContainerAfter.ShowOnlyStats(difstats)


func _on_show_stats_pressed() -> void:
	ContainerBefore.ShowStats()
	ContainerAfter.ShowStats()

func _on_show_deck_pressed() -> void:
	ContainerBefore.ShowDeck()
	ContainerAfter.ShowDeck()

func _on_show_cargo_pressed() -> void:
	ContainerBefore.ShowInvetory()
	ContainerAfter.ShowInvetory()

func _on_accept_pressed() -> void:
	TradeFinished.emit(true)

func _on_decline_pressed() -> void:
	TradeFinished.emit(false)


func _on_show_disposition_pressed() -> void:
	ContainerBefore.ShowDisposition()
	ContainerAfter.ShowDisposition()
