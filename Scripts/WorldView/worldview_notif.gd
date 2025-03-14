extends PanelContainer

class_name WorldviewNotif

@export var Negativebar : ProgressBar
@export var Possetivebar : ProgressBar
@export var DamageFloaterScene : PackedScene

var NotifStat : WorldView.WorldViews
var AdjustedAmm : int = -1

func _ready() -> void:
	#var Statvalue = WorldView.GetStatValue(NotifStat)
	var Statvalue = -20
	Negativebar.value = Statvalue * -1
	Possetivebar.value = Statvalue
	var DamageFloater = DamageFloaterScene.instantiate() as Floater
	DamageFloater.text = var_to_str(AdjustedAmm)
	DamageFloater.EndTimer.wait_time = 2
	add_child(DamageFloater)
	await  DamageFloater.Ended
	queue_free()
