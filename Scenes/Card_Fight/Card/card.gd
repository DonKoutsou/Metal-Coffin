extends Control

class_name Card

@export var CardName : RichTextLabel
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
signal CardKilled

var CStats : CardStats

var Cost : int
var ShownCost : int

var TargetLocs : Array[Vector2]

var InterpolationValue : float

var TrackMouse : bool = false

var mat : ShaderMaterial

func _physics_process(delta: float) -> void:
	InterpolationValue = min(InterpolationValue + delta * 2, 1)
	UpdateLine()
	
	#$SubViewportContainer/SubViewport.visible = false
	#$SubViewportContainer/SubViewport.render_target_update_mode =  SubViewport.UPDATE_ONCE

func _process(delta: float) -> void:
	
	if (TrackMouse):
		var pos = global_position + (size/2)
		var offset = get_global_mouse_position() - pos
		var currenty = mat.get_shader_parameter("y_rot")
		var currentx = mat.get_shader_parameter("x_rot")
		var Newy = lerpf(currenty, -offset.x / 8, delta * 6.0)
		var Newx = lerpf(currentx, offset.y / 8, delta * 6.0)
		mat.set_shader_parameter("y_rot", Newy)
		mat.set_shader_parameter("x_rot", Newx)

func UpdateLine() -> void:
	for g in TargetLocs.size():
		Lines[g].set_point_position(1, lerp(Vector2.ZERO ,Line.to_local(TargetLocs[g]),InterpolationValue))


func KillCard(CustomTime : float = 1.0, Free : bool = true) -> void:
	But.disabled = true
	var KillTw = create_tween()
	KillTw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	#var mat = material as ShaderMaterial
	KillTw.tween_method(UpdateBurnShader, 1.0, 0.0 ,CustomTime)
	#KillTw.tween_property(mat, "dissolve_value", 0, 0.2)
	await KillTw.finished
	CardKilled.emit()
	if (Free):
		queue_free()


func UpdateBurnShader(Value : float) -> void:
	FrontSide.material.set_shader_parameter("dissolve_value", Value)


func ForcePersp(t : bool) -> void:
	var Value : float
	if (t):
		Value = 25
	else:
		Value = 0
	mat.set_shader_parameter("x_rot", Value)


func TogglePerspective(t : bool, tOverride : float = 0.75) -> void:
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
	mat.set_shader_parameter("x_rot", v)


func _ready() -> void:
	mat = FrontSide.material as ShaderMaterial
	
	var SoundMan = UISoundMan.GetInstance()
	if (is_instance_valid(SoundMan)):
		SoundMan.AddSelf(But)
	for g in TargetLocs.size() - 1:
		var NewLine = Line.duplicate()
		add_child(NewLine)
		Lines.append(NewLine)
	set_physics_process(TargetLocs.size() > 0)
	Line.visible = TargetLocs.size() > 0

func _enter_tree() -> void:
	$SubViewportContainer/SubViewport.set_deferred("render_target_update_mode",  SubViewport.UPDATE_ONCE)
	

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
	if (CStats.Burned):
		CardDesc.text = ""
		CardCost.text = "0"
	else:
		var DescText =  "[center] {0}".format([CStats.GetBattleDescription(User)])
		CardDesc.text = DescText
		ShownCost = GetBattleCost(User, CStats)
		CardCost.text = "{0}".format([ShownCost])
	
	$SubViewportContainer/SubViewport.set_deferred("render_target_update_mode",  SubViewport.UPDATE_ONCE)

func Flip() -> void:
	FrontSide.visible = false
	BackSide.visible = true
	$Amm.visible = false


func SetCardBattleStats(User : BattleShipStats, Stats : CardStats, Amm : int = 0) -> void:
	CStats = Stats
	Cost = Stats.Energy
	ShownCost = GetBattleCost(User, Stats)
	if (Stats.Burned):
		CardName.text = "Burned"
		CardDesc.text = ""
		CardCost.text = "0"
		UpdateBurnShader(0.75)
		CardTex.texture = null
	else:
		var DescText =  "[center] {0}".format([Stats.GetBattleDescription(User)])
		CardName.text = Stats.GetCardName()
		CardDesc.text = DescText
		CardCost.text = "{0}".format([ShownCost])
		CardTex.texture = Stats.Icon
	
	$Amm.visible = Amm > 1
	AmmountLabel.text = "{0}x".format([Amm])

	if (Stats.Type == CardStats.CardType.OFFENSIVE):
		CardTypeEmblem.modulate = Color("ff3c22")
	else : if (Stats.Type == CardStats.CardType.DEFFENSIVE):
		CardTypeEmblem.modulate = Color("6be2e9")
	else:
		CardTypeEmblem.modulate = Color("8db354")

func GetBattleCost(User : BattleShipStats, Stats : CardStats) -> int:
	if (Stats.Burned):
		return 0
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
	$SubViewportContainer/SubViewport.set_deferred("render_target_update_mode",  SubViewport.UPDATE_ONCE)
	
	CardName.add_theme_font_override("normal_font", RealisticFont)
	CardCost.add_theme_font_override("font", RealisticFont)
	CardDesc.add_theme_font_override("normal_font", RealisticFont)
	CardCost.get_child(0).visible = false


func OnButtonPressed() -> void:

	OnCardPressed.emit(self)


func Dissable(Filter : bool = false) -> void:
	FrontSide.disabled = true
	var SoundMan = UISoundMan.GetInstance()
	if (is_instance_valid(SoundMan)):
		SoundMan.RemoveSelf(FrontSide)
	if (Filter):
		#But.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		FrontSide.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
func Enable() -> void:
	FrontSide.disabled = false
	var SoundMan = UISoundMan.GetInstance()
	if (is_instance_valid(SoundMan)):
		SoundMan.AddSelf(FrontSide)
	#But.set_mouse_filter(Control.MOUSE_FILTER_PASS)
	FrontSide.set_mouse_filter(Control.MOUSE_FILTER_PASS)
	
	
func GetCost() -> int:
	return Cost

var OriginalRot : float
var TweenHover : Tween
var RotTweenHover : Tween


func _on_button_mouse_entered() -> void:
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.SWIFT_CARDS)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.SWIFT_CARDS)
		ActionTracker.QueueTutorial("Swift Cards", "Some cards are marked witn [color=#ffc315]SW[/color] in their name. Those cards will be placed at the top of the pile at the start of every card fight. Usefull for starting a fight prepared.", [])
	
	z_index = 1
	
	if (TweenHover and TweenHover.is_running()):
		TweenHover.kill()
	
	TweenHover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel(true)
	TweenHover.tween_property(self,"scale", Vector2(1.1, 1.1), 0.55)
	#TrackMouse = true

func _on_button_mouse_exited() -> void:
	z_index = 0
	if (TweenHover and TweenHover.is_running()):
		TweenHover.kill()

	TweenHover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	TweenHover.tween_property(self,"scale", Vector2.ONE, 0.55)
	#TrackMouse = false
	if (dirTw != null):
		dirTw.kill()
	dirTw = create_tween()
	dirTw.set_ease(Tween.EASE_OUT)
	dirTw.set_trans(Tween.TRANS_BACK)
	var currenty = mat.get_shader_parameter("y_rot")
	var currentx = mat.get_shader_parameter("x_rot")
	dirTw.tween_method(SetCardDiretion, Vector2(currentx, currenty), Vector2(0, 0), 0.25)

func SetCardDiretion(dir : Vector2) -> void:
	mat.set_shader_parameter("y_rot", dir.y)
	mat.set_shader_parameter("x_rot", dir.x)
	
var dirTw : Tween

func _on_button_gui_input(_event: InputEvent) -> void:
	if (dirTw != null):
		dirTw.kill()
	dirTw = create_tween()
	dirTw.set_ease(Tween.EASE_OUT)
	dirTw.set_trans(Tween.TRANS_BACK)
	
	var pos = global_position + (size/2)
	var offset = get_global_mouse_position() - pos
	var currenty = mat.get_shader_parameter("y_rot")
	var currentx = mat.get_shader_parameter("x_rot")
	var Newy = -offset.x / 8
	var Newx = offset.y / 8
	#mat.set_shader_parameter("y_rot", Newy)
	#mat.set_shader_parameter("x_rot", Newx)
	
	dirTw.tween_method(SetCardDiretion, Vector2(currentx, currenty), Vector2(Newx, Newy), 0.25)
	
