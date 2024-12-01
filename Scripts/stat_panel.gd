extends PanelContainer
class_name StatPanel
@export var StatScene : PackedScene
@export var StatsToShow : Array[String] = []
@export var SupportCustomValues : bool = false

var StatPanels : Array[UIStat] = []

signal STPAN_OnStatsUpdated(StatN : String)
signal STPAN_OnStatsUpdatedCust(StatN : String, Val : float)
signal STPAN_OnStatLow(StatN : String)
# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	$GridContainer.columns = StatsToShow.size()
	for g in StatsToShow.size():
		var stat = StatScene.instantiate() as UIStat
		stat.Stat = StatsToShow[g]
		StatPanels.append(stat)
		get_child(0).add_child(stat)
		#if (!StatsToShowOnMap.has(StatsToShow[g])):
			#stat.visible = false
		connect("STPAN_OnStatLow", stat.AlarmLow)
		if (!SupportCustomValues):
			connect("STPAN_OnStatsUpdated", stat.UpdateStat)
		else :
			connect("STPAN_OnStatsUpdatedCust", stat.UpdateStatCust)
func StatsUp(StatN : String):
	STPAN_OnStatsUpdated.emit(StatN)
func StatsLow(StatN : String):
	STPAN_OnStatLow.emit(StatN)
func StatsUpCust(StatN : String, Val : float):
	STPAN_OnStatsUpdatedCust.emit(StatN, Val)
func StatAutoRefil(statn : String) -> bool:
	var stat : UIStat
	for g in StatPanels:
		if (g.Stat == statn):
			stat = g
	if (stat == null):
		return false
	return stat.AutoRefill
#func OnInventoryOpened():
	#pass
	#$GridContainer.columns = 4
	#for g in StatPanels.size():
		#StatPanels[g].visible = true
#func OnInventoryClosed():
	#pass
	#$GridContainer.columns = 2
	#for g in StatPanels.size():
		#var nam = StatPanels[g].Stat
		#if (!StatsToShowOnMap.has(nam)):
		#	StatPanels[g].visible = false
