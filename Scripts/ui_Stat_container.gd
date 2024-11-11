extends PanelContainer
class_name UIStat

@export var FuelTex : Texture
@export var HullTex : Texture
@export var HPTex : Texture
@export var OxygenTex : Texture

var AutoRefill = true

var Stat : String

func UpdateStat(StatN : String):
	if (Stat != StatN):
		return
	var dat = ShipData.GetInstance()
	var stat = dat.GetStat(Stat)
	var CurStat = roundi(stat.GetCurrentValue())
	var MaxValue = stat.GetStat()
	AutoRefill = stat.AllowAutoRefil
	$Control/AutoRefil.visible = stat.AllowAutoRefil
	#var MyTween = create_tween()
	#MyTween.set_trans(Tween.TRANS_EXPO)
	#MyTween.tween_property($HBoxContainer/Bar, "value", CurStat, 0.1)
	#$HBoxContainer/Bar.max_value = MaxValue
	#$HBoxContainer/Bar.value = CurStat
	$Control/TextureRect/Label.text = var_to_str(roundi(CurStat)) + "/" + var_to_str((roundi(MaxValue)))
	if (CurStat > MaxValue * 0.2):
		$Control/Light.Toggle(false)
		#$HBoxContainer/Bar/HBoxContainer/TextureRect2.visible = false
		#$HBoxContainer/Bar/HBoxContainer/TextureRect3.visible = false
	#if (CurStat < 20):
		#$AnimationPlayer.play("StatLow")
# Called when the node enters the scene tree for the first time.
func AlarmLow(StatN : String):
	if (Stat != StatN):
		return
	$Control/Light.Toggle(true)
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
		$Control/TextureRect.texture = HPTex
		#($HBoxContainer/Bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.229, 0.48, 0.376)
	if (Stat == "OXYGEN"):
		$Control/TextureRect.texture = OxygenTex
		#($HBoxContainer/Bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.371, 0.411, 0.64)
	if (Stat == "HULL"):
		$Control/TextureRect.texture = HullTex
		#($HBoxContainer/Bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.218, 0.419, 0.576)
	if (Stat == "FUEL"):
		$Control/TextureRect.texture = FuelTex
		#($HBoxContainer/Bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.635, 0.592, 0.323)
	UpdateStat(Stat)
	$Control/AutoRefil.button_pressed = AutoRefill
	#$HBoxContainer/Bar/HBoxContainer/Label2.text = Stat

func _on_auto_refil_toggled(toggled_on: bool) -> void:
	AutoRefill = toggled_on
