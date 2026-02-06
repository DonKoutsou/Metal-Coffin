extends Control

class_name Card

@export var CardName : Label
@export var CardDesc : RichTextLabel
@export var CardCost : Label
@export var CardTex : TextureRect
@export var But : Button
@export var Lines : Array[Line2D]
@export var CardTypeEmblem : Panel
@export var FrontSide : Control
@export var BackSide : Control
@export var Line : Line2D
@export var AmmountLabel : Label

@export var RealisticFont : Font

signal OnCardPressed(C : Card)

var CStats : CardStats

var Cost : int
var ShownCost : int

var TargetLocs : Array[Vector2]

var InterpolationValue : float

func _physics_process(delta: float) -> void:
	InterpolationValue = min(InterpolationValue + delta * 2, 1)
	UpdateLine()


func UpdateLine() -> void:
	for g in TargetLocs.size():
		Lines[g].set_point_position(1, lerp(Vector2.ZERO ,Line.to_local(TargetLocs[g]),InterpolationValue))


func KillCard(CustomTime : float = 1.0, Free : bool = true) -> void:
	But.disabled = true
	var KillTw = create_tween()
	KillTw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	#var mat = material as ShaderMaterial
	KillTw.tween_method(UpdateBurnShader, 1.0, 0.0,CustomTime)
	#KillTw.tween_property(mat, "dissolve_value", 0, 0.2)
	await KillTw.finished
	if (Free):
		queue_free()


func UpdateBurnShader(Value : float) -> void:
	var mat = FrontSide.material as ShaderMaterial
	mat.set_shader_parameter("dissolve_value", Value)


func ForcePersp(t : bool) -> void:
	var mat = FrontSide.material as ShaderMaterial
	var Value : float
	if (t):
		Value = 25
	else:
		Value = 0
	mat.set_shader_parameter("x_rot", Value)


func TogglePerspective(t : bool, tOverride : float = 0.75) -> void:
	var mat = FrontSide.material as ShaderMaterial
	var Value : float
	if (t):
		Value = 25
	else:
		Value = 0
	
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_method(UpdatePersp, mat.get_shader_parameter("x_rot"), Value, tOverride)


func UpdatePersp(v : float) -> void:
	var mat = $SubViewportContainer.material as ShaderMaterial
	mat.set_shader_parameter("x_rot", v)


func _ready() -> void:
	var SoundMan = UISoundMan.GetInstance()
	if (is_instance_valid(SoundMan)):
		SoundMan.AddSelf(But)
	for g in TargetLocs.size() - 1:
		var NewLine = Line.duplicate()
		add_child(NewLine)
		Lines.append(NewLine)
	set_physics_process(TargetLocs.size() > 0)
	Line.visible = TargetLocs.size() > 0
	

func SetCardStats(Stats : CardStats, Amm : int = 0) -> void:
	CStats = Stats
	Cost = Stats.Energy
	var DescText =  "[center] {0}".format([Stats.GetDescription()])

	CardName.text = Stats.GetCardName()
	CardTex.texture = Stats.Icon
	
	$Amm.visible = Amm > 1
	AmmountLabel.text = "{0}x".format([Amm])
	
	CardDesc.text = DescText
	
	CardCost.text = "{0}".format([Cost])
	
	if (Stats.Type == CardStats.CardType.OFFENSIVE):
		CardTypeEmblem.modulate = Color("ff3c22")
	else : if (Stats.Type == CardStats.CardType.DEFFENSIVE):
		CardTypeEmblem.modulate = Color("6be2e9")
	else:
		CardTypeEmblem.modulate = Color("8db354")
	#if (Stats.OnPerformModule is OffensiveCardModule):
		#CardTex.modulate = Color(1.0, 0.235, 0.132)


func UpdateBattleStats(User : BattleShipStats) -> void:
	var DescText =  "[center] {0}".format([CStats.GetBattleDescription(User)])
	CardDesc.text = DescText
	ShownCost = GetBattleCost(User, CStats)
	CardCost.text = "{0}".format([ShownCost])


func Flip() -> void:
	FrontSide.visible = false
	BackSide.visible = true
	$Amm.visible = false


func SetCardBattleStats(User : BattleShipStats, Stats : CardStats, Amm : int = 0) -> void:
	CStats = Stats

	Cost = Stats.Energy
	ShownCost = GetBattleCost(User, Stats)
	var DescText =  "[center] {0}".format([Stats.GetBattleDescription(User)])

	CardName.text = Stats.GetCardName()
	CardTex.texture = Stats.Icon
	
	$Amm.visible = Amm > 1
	AmmountLabel.text = "{0}x".format([Amm])
	
	CardDesc.text = DescText
	
	CardCost.text = "{0}".format([ShownCost])
	
	if (Stats.Type == CardStats.CardType.OFFENSIVE):
		CardTypeEmblem.modulate = Color("ff3c22")
	else : if (Stats.Type == CardStats.CardType.DEFFENSIVE):
		CardTypeEmblem.modulate = Color("6be2e9")
	else:
		CardTypeEmblem.modulate = Color("8db354")


func GetBattleCost(User : BattleShipStats, Stats : CardStats) -> int:
	var CCost : int = 0
	if (Stats.OnPerformModule is EnergyOffensiveCardModule):
		if (Stats.OnPerformModule.StoredEnergy > 0):
			CCost = Stats.OnPerformModule.StoredEnergy
		else:
			CCost = User.Energy
			
	for St in Stats.OnUseModules:
		if (St is MaxReserveModule or St is MaxShieldCardModule):
			CCost = User.Energy
			
	if (CCost == 0):
		CCost = Stats.Energy
	
	return CCost


func SetRealistic() -> void:
	$SubViewportContainer/SubViewport/TextureRect.visible = true
	$SubViewportContainer/SubViewport/Panel.visible = false
	$SubViewportContainer/SubViewport/VBoxContainer/HBoxContainer/CardCost/TextureRect.visible = false
	
	CardName.add_theme_font_override("font", RealisticFont)
	CardCost.add_theme_font_override("font", RealisticFont)
	CardDesc.add_theme_font_override("normal_font", RealisticFont)
	CardCost.get_child(0).visible = false


func OnButtonPressed() -> void:

	OnCardPressed.emit(self)


func Dissable(Filter : bool = false) -> void:
	But.disabled = true
	var SoundMan = UISoundMan.GetInstance()
	if (is_instance_valid(SoundMan)):
		SoundMan.RemoveSelf(But)
	if (Filter):
		But.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		FrontSide.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
func Enable() -> void:
	But.disabled = false
	var SoundMan = UISoundMan.GetInstance()
	if (is_instance_valid(SoundMan)):
		SoundMan.AddSelf(But)
	But.set_mouse_filter(Control.MOUSE_FILTER_PASS)
	FrontSide.set_mouse_filter(Control.MOUSE_FILTER_PASS)
	
	
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
