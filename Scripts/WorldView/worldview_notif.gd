extends PanelContainer

class_name WorldviewNotif

@export var Negativebar : ProgressBar
@export var Possetivebar : ProgressBar
@export var DamageFloaterScene : PackedScene

var NotifStat : WorldView.WorldViews
var AdjustedAmm : int = -1

func _ready() -> void:
	var Statvalue = WorldView.GetInstance().GetStatValue(NotifStat)
	#var Statvalue = -10
	Negativebar.value = (Statvalue * -1) + AdjustedAmm
	Possetivebar.value = Statvalue - AdjustedAmm
	var DamageFloater = DamageFloaterScene.instantiate() as Floater
	DamageFloater.text = var_to_str(AdjustedAmm)
	DamageFloater.EndTimer.wait_time = 2
	var Stat = WorldView.WorldViews.keys()[NotifStat].split("_")
	$VBoxContainer/HBoxContainer2/Label.text = Stat[0]
	$VBoxContainer/HBoxContainer2/Label2.text = Stat[1]
	
	var tw = create_tween()
	tw.tween_property(Negativebar, "value", Statvalue * -1, 1)
	var tw2 = create_tween()
	tw2.tween_property(Possetivebar, "value", Statvalue, 1)
	
	add_child(DamageFloater)
	await  DamageFloater.Ended
	queue_free()
