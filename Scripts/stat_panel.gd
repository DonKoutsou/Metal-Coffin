extends PanelContainer
class_name StatPanel
@export var StatScene : PackedScene
@export var StatsToShow : Array[String] = []
@export var SupportCustomValues : bool = false

var StatPanels : Array[UIStat] = []

signal OnStatsUpdated(StatN : String)
signal OnStatsUpdatedCust(StatN : String, Val : float)
signal OnStatLow(StatN : String)
# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	for g in StatsToShow.size():
		var stat = StatScene.instantiate() as UIStat
		stat.Stat = StatsToShow[g]
		StatPanels.append(stat)
		get_child(0).add_child(stat)
		#if (!StatsToShowOnMap.has(StatsToShow[g])):
			#stat.visible = false
		connect("OnStatLow", stat.AlarmLow)
		if (!SupportCustomValues):
			connect("OnStatsUpdated", stat.UpdateStat)
		else :
			connect("OnStatsUpdatedCust", stat.UpdateStatCust)
func StatsUp(StatN : String):
	OnStatsUpdated.emit(StatN)
func StatsLow(StatN : String):
	OnStatLow.emit(StatN)
func StatsUpCust(StatN : String, Val : float):
	OnStatsUpdatedCust.emit(StatN, Val)
func OnInventoryOpened():
	$GridContainer.columns = 4
	#for g in StatPanels.size():
		#StatPanels[g].visible = true
func OnInventoryClosed():
	$GridContainer.columns = 2
	#for g in StatPanels.size():
		#var nam = StatPanels[g].Stat
		#if (!StatsToShowOnMap.has(nam)):
		#	StatPanels[g].visible = false
