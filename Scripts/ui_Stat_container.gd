extends PanelContainer
class_name UIStat

var Stat : String

func UpdateStat(StatN : String):
	if (Stat != StatN):
		return
	var dat = ShipData.GetInstance()
	var CurStat = dat.GetStat(Stat).GetCurrentValue()
	var MaxValue = dat.GetStat(Stat).GetStat()
	var tw = create_tween()
	tw.tween_property($HBoxContainer/Bar, "value", CurStat, 1)
	tw.play()
	$HBoxContainer/Bar.max_value = MaxValue
	#$HBoxContainer/Bar.value = CurStat
	$HBoxContainer/Bar/Label.text = var_to_str(roundi(CurStat)) + "/" + var_to_str((roundi(MaxValue)))
# Called when the node enters the scene tree for the first time.
func UpdateStatCust(StatN : String, Val : float):
	if (Stat != StatN):
		return
	var dat = ShipData.GetInstance()
	var MaxValue = dat.GetStat(Stat).GetStat()
	var tw = create_tween()
	tw.tween_property($HBoxContainer/Bar, "value", Val, 1)
	tw.play()
	$HBoxContainer/Bar.max_value = MaxValue
	#$HBoxContainer/Bar.value = CurStat
	$HBoxContainer/Bar/Label.text = var_to_str(roundi(Val)) + "/" + var_to_str((roundi(MaxValue)))
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
	$HBoxContainer/Label2.text = Stat
