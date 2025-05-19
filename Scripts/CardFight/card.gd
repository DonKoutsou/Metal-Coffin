extends Control

class_name Card

@export var CardName : Label
@export var CardDesc : RichTextLabel
@export var CardCost : Label
@export var CardTex : TextureRect
@export var Lines : Array[Line2D]

signal OnCardPressed(C : Card)

var CStats : CardStats

var Cost : int

var TargetLocs : Array[Vector2]

var InterpolationValue : float

func _physics_process(delta: float) -> void:
	InterpolationValue = min(InterpolationValue + delta * 2, 1)
	UpdateLine()

func UpdateLine() -> void:
	for g in TargetLocs.size():
		Lines[g].set_point_position(1, lerp(Vector2.ZERO ,$Line2D.to_local(TargetLocs[g]),InterpolationValue))

func CompactCard() -> void:
	$VBoxContainer/CardDesc.visible = false
	$Line2D.position.y -= size.y - 85
	custom_minimum_size.y = 85
	size.y = 85

	set_anchors_preset(Control.PRESET_CENTER)

func KillCard(CustomTime : float = 1.0, Free : bool = true) -> void:
	$Button.disabled = true
	var KillTw = create_tween()
	KillTw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	#var mat = material as ShaderMaterial
	KillTw.tween_method(UpdateShader, 1.0, 0.0,CustomTime)
	#KillTw.tween_property(mat, "dissolve_value", 0, 0.2)
	await KillTw.finished
	if (Free):
		queue_free()

func UpdateShader(Value : float) -> void:
	var mat = material as ShaderMaterial
	mat.set_shader_parameter("dissolve_value", Value)

func _ready() -> void:
	var SoundMan = UISoundMan.GetInstance()
	if (is_instance_valid(SoundMan)):
		SoundMan.AddSelf($Button)
	for g in TargetLocs.size() - 1:
		var NewLine = $Line2D.duplicate()
		add_child(NewLine)
		Lines.append(NewLine)
	set_physics_process(TargetLocs.size() > 0)
	$Line2D.visible = TargetLocs.size() > 0
#func SetCardStats(Stats : CardStats, Options : Array[CardOption], Amm : int = 0) -> void:
func SetCardStats(Stats : CardStats, Amm : int = 0) -> void:
	CStats = Stats
	Cost = Stats.Energy
	var DescText =  "[center] {0}".format([Stats.GetDescription()])

	CardName.text = Stats.CardName
	CardTex.texture = Stats.Icon
	
	$Amm.visible = Amm > 1
	$Amm/Label.text = var_to_str(Amm) + "x"
	
	CardDesc.text = DescText
	
	CardCost.text = var_to_str(Cost)
	
	#if (Stats.OnPerformModule is OffensiveCardModule):
		#CardTex.modulate = Color(1.0, 0.235, 0.132)
	
func SetRealistic() -> void:
	$TextureRect.visible = true
	$Panel.visible = false
	$VBoxContainer/HBoxContainer/CardCost/TextureRect.visible = false
	
	#$VBoxContainer/HBoxContainer/Label.add_theme_font_override("font",load("res://Fonts/DINEngschriftStd.otf"))
	#$VBoxContainer/HBoxContainer/CardCost.add_theme_font_override("font",load("res://Fonts/DINEngschriftStd.otf"))
	#
	#$VBoxContainer/Control/CardDesc.add_theme_font_override("font", load("res://Fonts/DINEngschriftStd.otf"))

func OnButtonPressed() -> void:

	OnCardPressed.emit(self)

func Dissable(MouseFilter : bool = false) -> void:
	$Button.disabled = true
	var SoundMan = UISoundMan.GetInstance()
	if (is_instance_valid(SoundMan)):
		SoundMan.RemoveSelf($Button)
	if (MouseFilter):
		$Button.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)


func GetCost() -> int:
	return Cost

var OriginalRot : float
var TweenHover : Tween
var RotTweenHover : Tween

func _on_button_mouse_entered() -> void:
	z_index = 1
	
	if (TweenHover and TweenHover.is_running()):
		TweenHover.kill()
	
	TweenHover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel(true)
	TweenHover.tween_property(self,"scale", Vector2(1.1, 1.1), 0.55)

func _on_button_mouse_exited() -> void:
	z_index = 0
	if (TweenHover and TweenHover.is_running()):
		TweenHover.kill()

	TweenHover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	TweenHover.tween_property(self,"scale", Vector2.ONE, 0.55)
