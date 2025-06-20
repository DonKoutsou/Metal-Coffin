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
