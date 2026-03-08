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
	ContainerBefore.ShowOnlyStats(difstats)
	ContainerAfter.ShowOnlyStats(difstats)


func _on_show_stats_pressed() -> void:
	ContainerBefore.ShowStats()
	ContainerAfter.ShowStats()

func _on_show_deck_pressed() -> void:
	ContainerBefore.ShowDeck()
	ContainerAfter.ShowDeck()


func _on_accept_pressed() -> void:
	TradeFinished.emit(true)

func _on_decline_pressed() -> void:
	TradeFinished.emit(false)
