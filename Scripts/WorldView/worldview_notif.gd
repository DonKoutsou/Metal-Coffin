extends PanelContainer

class_name WorldviewNotif

@export var Negativebar : ProgressBar
@export var Possetivebar : ProgressBar
@export var DamageFloaterScene : PackedScene

var NotifStat : WorldView.WorldViews
var AdjustedAmm : int = -1

func _ready() -> void:
	var IntroTween = create_tween()
	get_child(0).visible = false
	var Sizex = size.x
	size.x = 0
	IntroTween.set_ease(Tween.EASE_OUT)
	IntroTween.set_trans(Tween.TRANS_QUAD)
	IntroTween.tween_property(self, "size", Vector2(Sizex, size.y), 0.25)
	
	await IntroTween.finished
	
	get_child(0).visible = true
	
	var Statvalue = WorldView.GetInstance().GetStatValue(NotifStat)
	#var Statvalue = -10
	Negativebar.value = (Statvalue * -1) + AdjustedAmm
	Possetivebar.value = Statvalue - AdjustedAmm
	var DamageFloater = DamageFloaterScene.instantiate() as Floater
	DamageFloater.text = var_to_str(AdjustedAmm)
	DamageFloater.EndTimer.wait_time = 1
	var Stat = WorldView.WorldViews.keys()[NotifStat].split("_")
	$VBoxContainer/HBoxContainer2/Label.text = Stat[0]
	$VBoxContainer/HBoxContainer2/Label2.text = Stat[1]
	
	var tw = create_tween()
	tw.tween_property(Negativebar, "value", Statvalue * -1, 1)
	var tw2 = create_tween()
	tw2.tween_property(Possetivebar, "value", Statvalue, 1)
	
	add_child(DamageFloater)
	await  DamageFloater.Ended
	
	var OutroTween = create_tween()
	get_child(0).visible = false

	OutroTween.set_ease(Tween.EASE_OUT)
	OutroTween.set_trans(Tween.TRANS_QUAD)
	OutroTween.tween_property(self, "size", Vector2(0, size.y), 0.25)
	
	await OutroTween.finished
	
	queue_free()
