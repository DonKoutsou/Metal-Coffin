extends Control

class_name CardFightShipViz2

@export var ShipNameLabel : Label
@export var ShipIcon : TextureRect
@export var HullBar : ProgressBar
@export var HullLabel : Label
@export var ShieldBar : ProgressBar
@export var TurnPanel : Control
@export var SpeedBuff : GPUParticles2D
@export var SpeedDeBuff : GPUParticles2D
@export var FPBuff : GPUParticles2D
@export var FPDeBuff : GPUParticles2D

@export var FirePart : GPUParticles2D
@export var ExplosionPart : GPUParticles2D
@export var SmokePart : GPUParticles2D
@export var FPLabel : RichTextLabel
@export var SPDLabel : RichTextLabel
@export var HasMovePanel : Control
@export var ActionParent : Control
@export var ShadowPivot : Control

@export var DefBuff : GPUParticles2D
@export var DefDeBuff : GPUParticles2D
@export var WeightLabel : RichTextLabel
@export var DefenceLabel : RichTextLabel

const StatText = "[color=#ffc315]HULL[/color][p][color=#6be2e9]SHIELD[/color][p][color=#308a4d]SPEED[/color][p][color=#f35033]FPWR[/color]"

signal OnFallbackPressed()

var Fr : bool

func Destroy() -> void:
	var mat = ExplosionPart.process_material as ParticleProcessMaterial
	mat.scale_max = 0.6
	ExplosionPart.emitting = true
	$HBoxContainer/Control/TextureRect/ExplosionSound.play()
	var RandomPos = ShipIcon.global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	var MoveTw = create_tween()
	MoveTw.set_ease(Tween.EASE_IN)
	MoveTw.set_trans(Tween.TRANS_QUAD)
	MoveTw.tween_property(ShipIcon, "global_position", RandomPos, 3)
	var ScaleTw = create_tween()
	ScaleTw.set_ease(Tween.EASE_IN)
	ScaleTw.set_trans(Tween.TRANS_QUAD)
	ScaleTw.tween_property(ShipIcon, "scale", Vector2(0.2, 0.2), 3)
	var RandomRot = randf_range(-720, 720)
	var RotTween = create_tween()
	RotTween.set_ease(Tween.EASE_IN)
	RotTween.set_trans(Tween.TRANS_QUAD)
	RotTween.tween_property(ShipIcon, "rotation_degrees", RandomRot, 3)
	var ShadowPosTween = create_tween()
	ShadowPosTween.set_ease(Tween.EASE_IN)
	ShadowPosTween.set_trans(Tween.TRANS_QUAD)
	ShadowPosTween.tween_property(ShadowPivot.get_child(0), "position", Vector2(0, 0), 3)
	var ShadowScaleTween = create_tween()
	ShadowScaleTween.set_ease(Tween.EASE_IN)
	ShadowScaleTween.set_trans(Tween.TRANS_QUAD)
	ShadowScaleTween.tween_property(ShadowPivot.get_child(0), "scale", Vector2(1,1), 3)
	var ShadowPivotRotTween = create_tween()
	ShadowPivotRotTween.set_ease(Tween.EASE_IN)
	ShadowPivotRotTween.set_trans(Tween.TRANS_QUAD)
	ShadowPivotRotTween.tween_property(ShadowPivot, "rotation_degrees", -RandomRot, 3)
	var ShadowRotTween = create_tween()
	ShadowRotTween.set_ease(Tween.EASE_IN)
	ShadowRotTween.set_trans(Tween.TRANS_QUAD)
	ShadowRotTween.tween_property(ShadowPivot.get_child(0), "rotation_degrees", RandomRot, 3)
	ToggleFire(false)
	ToggleDefBuff(false, 1)
	ToggleDefDeBuff(false)
	ToggleDmgBuff(false, 1)
	ToggleDmgDebuff(false)
	ToggleSpeedBuff(false, 1)
	ToggleSpeedDebuff(false)
	
	
	EnableSmoke()
	$HBoxContainer/VBoxContainer/PanelContainer2.queue_free()
	
	await MoveTw.finished
	$HBoxContainer/Control/TextureRect/LandSound.play()
	mat.scale_max = 0.1
	ExplosionPart.restart()
	ExplosionPart.emitting = true
	

func _ready() -> void:
	#Destroy()
	ToggleFire(false)
	
func Pop(t : bool):
	var PopTween = create_tween()
	var FinalPos : Vector2 = Vector2(0, 50)
	if (t):
		if (Fr):
			FinalPos.x = 270
		else:
			FinalPos.x = -90
	else:
		if (Fr):
			FinalPos.x = 180
		else:
			FinalPos.x = 0
	PopTween.set_ease(Tween.EASE_OUT)
	PopTween.set_trans(Tween.TRANS_QUAD)
	PopTween.tween_property($HBoxContainer/Control, "position", FinalPos, 0.2)
	await PopTween.finished
	
func SetStats(S : BattleShipStats, Friendly : bool) -> void:
	Fr = Friendly
	ShipNameLabel.text = S.Name
	ShipIcon.texture = S.ShipIcon
	ShadowPivot.get_child(0).texture = S.ShipIcon
	HullLabel.text = "{0}/{1}".format([roundi(S.CurrentHull + S.Shield), S.Hull]).replace(".0", "")
	HullBar.max_value = S.Hull
	ShieldBar.max_value = S.MaxShield
	HullBar.value = S.CurrentHull
	ShieldBar.value = 0
	FPLabel.text = "[color=#f35033]FRPW[/color] {0}".format([S.GetFirePower()]).replace(".0", "")
	SPDLabel.text = "[color=#308a4d]SPD[/color] {0}".format([roundi(S.GetSpeed())])
	WeightLabel.text = "[color=#828dff]WGHT[/color] {0}".format([S.GetWeight()]).replace(".0", "")
	DefenceLabel.text = "[color=#7bb0b4]DEF[/color] {0}".format([roundi(S.GetDef())])
	
	ShipIcon.flip_v = !Friendly
	ShadowPivot.get_child(0).flip_v = !Friendly
	
	if (Friendly):
		$HBoxContainer.move_child($HBoxContainer/VBoxContainer, 0)
	else:
		ShipNameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ShipNameLabel.get_parent().move_child(ShipNameLabel, 1)
		HullLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		$HBoxContainer.move_child($HBoxContainer/VBoxContainer, 1)
		HasMovePanel.get_parent().move_child(HasMovePanel, 0)
	
	HasMovePanel.visible = false
	TurnPanel.self_modulate.a = 0

func GetShipPos() -> Vector2:
	return ShipIcon.global_position

func ActionPicked(Text : Texture) -> void:
	var TexNode = TextureRect.new()
	TexNode.texture = Text
	TexNode.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	TexNode.custom_minimum_size = Vector2(38,22)
	ActionParent.add_child(TexNode)

func ActionRemoved(Tex : Texture) -> void:
	for g : TextureRect in ActionParent.get_children():
		if (g.texture == Tex):
			g.free()
			return

func OnNewTurnStarted() -> void:
	HasMovePanel.visible = true

func OnActionsPerformed() -> void:
	HasMovePanel.visible = false

func UpdateStats(S : BattleShipStats) -> void:
	var HullTween = create_tween()
	HullTween.set_ease(Tween.EASE_OUT)
	HullTween.set_trans(Tween.TRANS_QUAD)
	HullTween.tween_property(HullBar, "value", S.CurrentHull, 1)
	
	var ShieldTween = create_tween()
	ShieldTween.set_ease(Tween.EASE_OUT)
	ShieldTween.set_trans(Tween.TRANS_QUAD)
	ShieldTween.tween_property(ShieldBar, "value", S.Shield, 1)
	
	HullLabel.text = "{0}/{1}".format([roundi(S.CurrentHull + S.Shield), S.Hull]).replace(".0", "")
	FPLabel.text = "[color=#f35033]FRPW[/color] {0}".format([S.GetFirePower()]).replace(".0", "")
	SPDLabel.text = "[color=#308a4d]SPD[/color] {0}".format([roundi(S.GetSpeed())])
	WeightLabel.text = "[color=#828dff]WGHT[/color] {0}".format([S.GetWeight()]).replace(".0", "")
	DefenceLabel.text = "[color=#7bb0b4]DEF[/color] {0}".format([S.GetDef()]).replace(".0", "")

func SetStatsAnimation(S : BattleShipStats, Friendly : bool) -> void:
	ShipNameLabel.text = S.Name
	ShipIcon.texture = S.ShipIcon
	TurnPanel.visible = Friendly

func Dissable() -> void:
	TurnPanel.self_modulate.a = 0
	Enabled = false
	if (is_instance_valid(ModulateTween)):
		ModulateTween.kill()

var Enabled : bool = false

var ModulateTween : Tween

func Enable() -> void:
	Enabled = true
	TurnPanel.self_modulate.a = 1
	ModulateTween = create_tween()
	ModulateTween.tween_property(TurnPanel, "self_modulate", Color(1,1,1,0), 1)
	ModulateTween.tween_callback(TweenEnded)

func TweenEnded() -> void:
	if (!Enabled):
		return
	ModulateTween = create_tween()
	ModulateTween.set_trans(Tween.TRANS_CUBIC)
	if (TurnPanel.self_modulate == Color(1,1,1,0)):
		ModulateTween.tween_property(TurnPanel, "self_modulate", Color(1,1,1,0.75), 0.5)
	else:
		ModulateTween.tween_property(TurnPanel, "self_modulate", Color(1,1,1,0), 0.5)
	ModulateTween.tween_callback(TweenEnded)

func ToggleFire(t : bool) -> void:
	FirePart.visible = t

func EnableSmoke() -> void:
	SmokePart.visible = true

func ToggleDmgBuff(t : bool, amm : float) -> void:
	FPBuff.amount = roundi(5.0 * amm)
	FPBuff.visible = t

func ToggleDmgDebuff(t : bool) -> void:
	FPDeBuff.visible = t

func ToggleDefBuff(t : bool, amm : float) -> void:
	DefBuff.amount = max(5 * abs(amm), 1)
	DefBuff.visible = t

func ToggleDefDeBuff(t : bool) -> void:
	DefDeBuff.visible = t

func ToggleSpeedBuff(t : bool, amm : float) -> void:
	SpeedBuff.amount = roundi(5.0 * amm)
	SpeedBuff.visible = t

func ToggleSpeedDebuff(t : bool) -> void:
	SpeedDeBuff.visible = t

func ShipDestroyed() -> void:
	#Destroy()
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1,1,1,0), 1)
	await tw.finished
	queue_free()

func _on_button_pressed() -> void:
	OnFallbackPressed.emit()
