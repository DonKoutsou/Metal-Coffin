extends PanelContainer
class_name StatPanel
@export var StatScene : PackedScene
@export var StatsToShow : Array[String] = []
@export var SupportCustomValues : bool = false

signal OnStatsUpdated(StatN : String)
signal OnStatsUpdatedCust(StatN : String, Val : float)
# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	for g in StatsToShow.size():
		var stat = StatScene.instantiate() as UIStat
		stat.Stat = StatsToShow[g]
		get_child(0).add_child(stat)
		if (!SupportCustomValues):
			connect("OnStatsUpdated", stat.UpdateStat)
		else :
			connect("OnStatsUpdatedCust", stat.UpdateStatCust)
func StatsUp(StatN : String):
	OnStatsUpdated.emit(StatN)
func StatsUpCust(StatN : String, Val : float):
	OnStatsUpdatedCust.emit(StatN, Val)
