extends PanelContainer

class_name WorldviewStatUI

@export var Negativebar : ProgressBar
@export var Possetivebar : ProgressBar

var St : WorldView.WorldViews

func _ready() -> void:
	WorldView.GetInstance().StatsChanged.connect(Update)

func Set(NotifStat : WorldView.WorldViews) -> void:
	St = NotifStat
	var Statvalue = WorldView.GetStatValue(NotifStat)
	#var Statvalue = -10
	Negativebar.value = (Statvalue * -1)
	Possetivebar.value = Statvalue

	var Stat = WorldView.WorldViews.keys()[NotifStat].split("_")
	$VBoxContainer/HBoxContainer2/Label.text = Stat[0]
	$VBoxContainer/HBoxContainer2/Label2.text = Stat[1]

func Update() -> void:
	var Statvalue = WorldView.GetStatValue(St)
	Negativebar.value = (Statvalue * -1)
	Possetivebar.value = Statvalue

	var Stat = WorldView.WorldViews.keys()[St].split("_")
	$VBoxContainer/HBoxContainer2/Label.text = Stat[0]
	$VBoxContainer/HBoxContainer2/Label2.text = Stat[1]
