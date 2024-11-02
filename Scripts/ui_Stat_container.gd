extends PanelContainer
class_name UIStat

var Stat : String
func UpdateStat(StatN : String):
	if (Stat != StatN):
		return
	var dat = ShipData.GetInstance()
	var CurStat = roundi(dat.GetStat(Stat).GetCurrentValue())
	var MaxValue = dat.GetStat(Stat).GetStat()

	var MyTween = create_tween()
	MyTween.tween_property($HBoxContainer/Bar, "value", CurStat, 0.1)
	$HBoxContainer/Bar.max_value = MaxValue
	#$HBoxContainer/Bar.value = CurStat
	$HBoxContainer/Bar/HBoxContainer/Label.text = var_to_str(roundi(CurStat)) + "/" + var_to_str((roundi(MaxValue)))
	if ($AnimationPlayer.is_playing()):
		$AnimationPlayer.stop()
		$HBoxContainer/Bar/HBoxContainer/TextureRect2.visible = CurStat < MaxValue * 0.2
		$HBoxContainer/Bar/HBoxContainer/TextureRect3.visible = CurStat < MaxValue * 0.2
	#if (CurStat < 20):
		#$AnimationPlayer.play("StatLow")
# Called when the node enters the scene tree for the first time.
func AlarmLow(StatN : String):
	if (Stat != StatN):
		return
	$AnimationPlayer.play("StatLow")
func UpdateStatCust(StatN : String, Val : float):
	if (Stat != StatN):
		return
	var dat = ShipData.GetInstance()
	var MaxValue = dat.GetStat(Stat).GetStat()
	var tw = create_tween()
	tw.tween_property($HBoxContainer/Bar, "value", Val, 0.1)
	tw.play()
	$HBoxContainer/Bar.max_value = MaxValue
	#$HBoxContainer/Bar.value = CurStat
	$HBoxContainer/Bar/HBoxContainer/Label.text = var_to_str(roundi(Val)) + "/" + var_to_str((roundi(MaxValue)))
func _enter_tree() -> void:
	if (Stat == "HP"):
		($HBoxContainer/Bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.051, 0.533, 0.09)
	if (Stat == "OXYGEN"):
		($HBoxContainer/Bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.317, 0.353, 0.75)
	if (Stat == "HULL"):
		($HBoxContainer/Bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.169, 0.428, 0.621)
	if (Stat == "FUEL"):
		($HBoxContainer/Bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.781, 0.651, 0)
	UpdateStat(Stat)
	$HBoxContainer/Bar/HBoxContainer/Label2.text = Stat
