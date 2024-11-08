extends PanelContainer
class_name UIStat

var AutoRefill = true

var Stat : String

func UpdateStat(StatN : String):
	if (Stat != StatN):
		return
	var dat = ShipData.GetInstance()
	var CurStat = roundi(dat.GetStat(Stat).GetCurrentValue())
	var MaxValue = dat.GetStat(Stat).GetStat()

	#var MyTween = create_tween()
	#MyTween.set_trans(Tween.TRANS_EXPO)
	#MyTween.tween_property($HBoxContainer/Bar, "value", CurStat, 0.1)
	#$HBoxContainer/Bar.max_value = MaxValue
	#$HBoxContainer/Bar.value = CurStat
	$Control/TextureRect/Label.text = var_to_str(roundi(CurStat)) + "/" + var_to_str((roundi(MaxValue)))
	#if (CurStat > MaxValue * 0.2):
		#if ($AnimationPlayer.is_playing()):
			#$AnimationPlayer.stop()
		#$HBoxContainer/Bar/HBoxContainer/TextureRect2.visible = false
		#$HBoxContainer/Bar/HBoxContainer/TextureRect3.visible = false
	#if (CurStat < 20):
		#$AnimationPlayer.play("StatLow")
# Called when the node enters the scene tree for the first time.
func AlarmLow(StatN : String):
	if (Stat != StatN):
		return
	#$AnimationPlayer.play("StatLow")
func UpdateStatCust(StatN : String, Val : float):
	if (Stat != StatN):
		return
	var dat = ShipData.GetInstance()
	var MaxValue = dat.GetStat(Stat).GetStat()
	#MaxValue.set_trans(Tween.TRANS_EXPO)
	#var tw = create_tween()
	#tw.tween_property($HBoxContainer/Bar, "value", Val, 0.1)
	#tw.play()
	#$HBoxContainer/Bar.max_value = MaxValue
	#$HBoxContainer/Bar.value = CurStat
	$HBoxContainer/Bar/HBoxContainer/Label.text = var_to_str(roundi(Val)) + "/" + var_to_str((roundi(MaxValue)))
func _enter_tree() -> void:
	if (Stat == "HP"):
		$Control/TextureRect.texture = load("res://Assets/UIPiecies/healthdiplay.png")
		#($HBoxContainer/Bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.229, 0.48, 0.376)
	if (Stat == "OXYGEN"):
		$Control/TextureRect.texture = load("res://Assets/UIPiecies/OXYGENdiplay.png")
		#($HBoxContainer/Bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.371, 0.411, 0.64)
	if (Stat == "HULL"):
		$Control/TextureRect.texture = load("res://Assets/UIPiecies/Displayhull.png")
		#($HBoxContainer/Bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.218, 0.419, 0.576)
	if (Stat == "FUEL"):
		$Control/TextureRect.texture = load("res://Assets/UIPiecies/Display.png")
		#($HBoxContainer/Bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.635, 0.592, 0.323)
	UpdateStat(Stat)
	#$HBoxContainer/Bar/HBoxContainer/Label2.text = Stat

func _on_auto_refill_toggled(toggled_on: bool) -> void:
	AutoRefill = toggled_on
