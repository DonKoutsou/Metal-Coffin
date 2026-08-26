extends Control

class_name CardFightShipViz2

@export_file_path(".tscn") var CardScene : String
@export var floaterScene : PackedScene
@export_group("Nodes")

@export var ShipNameLabel : Label

@export var ShipIcon : TextureRect
@export var ShadowPivot : Control

@export var TurnPanel : Control
@export var HasMovePanel : Control
@export var ActionParent : Control
@export var PassiveParent : Control


@export_group("Particles")
@export var FirePart : Control
@export var Shield : Control
@export var SpeedBuff : GPUParticles2D
@export var SpeedDeBuff : GPUParticles2D
@export var FPBuff : GPUParticles2D
@export var FPDeBuff : GPUParticles2D
@export var ExplosionPart : GPUParticles2D
@export var SmokePart : GPUParticles2D
@export var DefBuff : GPUParticles2D
@export var DefDeBuff : GPUParticles2D

@export_group("Sounds")
@export var Explosion : AudioStreamPlayer2D
@export var Land : AudioStreamPlayer2D

@export_group("Stats")
@export var statContainer : Control
@export var HullBar : ProgressBar
@export var HullLabel : Label
@export var ShieldBar : ProgressBar
@export var FPLabel : RichTextLabel
@export var SPDLabel : RichTextLabel
@export var WeightLabel : RichTextLabel
@export var DefenceLabel : RichTextLabel

@export_group("Animation")
@export var drift_radius: Vector2 = Vector2(24.0, 12.0)
@export var drift_speed: float = 0.7

@export var bob_height: float = 8.0
@export var bob_speed: float = 1.6

@export var wobble_amount_degrees: float = 3.0
@export var wobble_speed: float = 2.0

@export var turn_smoothing: float = 8.0
@export var facing_offset_degrees: float = 0.0

@export_group("Damage Pushback")
@export var pushback_strength: float = 250.0
@export var pushback_return_strength: float = 35.0
@export var pushback_damping: float = 8.0
@export var damage_wobble_degrees: float = 12.0
@export var damage_wobble_decay: float = 7.0

var time: float = 0.0
var phase: float = 0.0
var pushback_offset: Vector2 = Vector2.ZERO
var pushback_velocity: Vector2 = Vector2.ZERO
var lastPos : Vector2
var returnOffset : Vector2

var damage_wobble: float = 0.0
var animOffset : Vector2 = Vector2.ZERO

const StatText = "[color=#ffc315]HULL[/color][p][color=#6be2e9]SHIELD[/color][p][color=#308a4d]SPEED[/color][p][color=#f35033]FPWR[/color]"

signal OnFallbackPressed()
signal Hovered()
signal Unhovered()
signal ActionHovered()
signal ActionUnhovered()

var Destroyed : bool = false
var Ship : BattleShipStats
var Fr : bool

func DoFloater(text : String, col : Color = Color(1,1,1)) -> void:
	var DFloater = floaterScene.instantiate() as Floater
	DFloater.text = text
	DFloater.modulate = col
	add_child(DFloater)
	DFloater.global_position = (global_position + (size / 2)) - DFloater.size / 2

func Destroy() -> void:
	if (ShipIcon.texture is AnimatedTexture):
		ShipIcon.texture.pause = true
	
	Shield.visible = false
	Destroyed = true
	var mat = ExplosionPart.process_material as ParticleProcessMaterial
	mat.scale_max = 0.6
	ExplosionPart.emitting = true
	Explosion.play()
	var RandomPos = ShipIcon.global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
	
	var MoveTw = create_tween()
	MoveTw.set_ease(Tween.EASE_IN)
	MoveTw.set_trans(Tween.TRANS_QUAD)
	
	MoveTw.tween_property(ShipIcon, "global_position", RandomPos, 3)

	MoveTw.tween_property(ShipIcon, "scale", Vector2(0.2, 0.2), 3)
	
	var RandomRot = randf_range(-720, 720)
	MoveTw.tween_property(ShipIcon, "rotation_degrees", RandomRot, 3)

	MoveTw.tween_property(ShadowPivot.get_child(0), "position", Vector2(0, 0), 3)

	MoveTw.tween_property(ShadowPivot.get_child(0), "scale", Vector2(1,1), 3)

	MoveTw.tween_property(ShadowPivot, "rotation_degrees", -RandomRot, 3)

	MoveTw.tween_property(ShadowPivot.get_child(0), "rotation_degrees", RandomRot, 3)
	
	ToggleFire(false)
	ToggleDefBuff(false, 1)
	ToggleDefDeBuff(false)
	ToggleDmgBuff(false, 1)
	ToggleDmgDebuff(false)
	ToggleSpeedBuff(false, 1)
	ToggleSpeedDebuff(false)

	EnableSmoke()
	if (ModulateTween != null):
		ModulateTween.kill()
	$HBoxContainer/PanelContainer2.queue_free()
	
	await MoveTw.finished
	Land.play()
	mat.scale_max = 0.1
	ExplosionPart.restart()
	ExplosionPart.emitting = true
	

func _ready() -> void:
	statContainer.visible = false
	HullLabel.visible = false
	ToggleFire(false)
	phase = randf() * TAU



func _process(delta: float) -> void:
	if (Destroyed or !Ship.PlayAnimations):
		return

	time += delta

	_update_pushback(delta)
	
	var drift := Vector2(
		cos(time * drift_speed + phase) * drift_radius.x,
		sin(time * drift_speed * 1.37 + phase) * drift_radius.y
	)

	var bob := Vector2(
		0.0,
		sin(time * bob_speed + phase) * bob_height
	)
	
	#if (pushback_offset.is_equal_approx(Vector2.ZERO)):
		#apply_damage_pushback(0,0,null)
	if (lastPos != ShipIcon.global_position):
		returnOffset += ShipIcon.global_position - lastPos

	ShipIcon.position = drift + bob + pushback_offset - returnOffset - animOffset
	lastPos = ShipIcon.global_position
	returnOffset = returnOffset.slerp(Vector2.ZERO, delta * 2)

	# The visual center of the Control
	var my_center := ShipIcon.global_position

	var center = get_viewport_rect().size / 2
	center.y = clamp(center.y, my_center.y - 30, my_center.y + 30)
	var direction_to_center = center - my_center

	if direction_to_center.length_squared() > 0.001:
		var target_rotation := direction_to_center.angle() - deg_to_rad(90)
		target_rotation += deg_to_rad(facing_offset_degrees)

		var wobble := sin(time * wobble_speed + phase) * deg_to_rad(wobble_amount_degrees)
		var hit_wobble := sin(time * 28.0) * deg_to_rad(damage_wobble)
		target_rotation += wobble + hit_wobble

		ShipIcon.rotation = lerp_angle(ShipIcon.rotation, target_rotation, delta * turn_smoothing)
		
	ShadowPivot.rotation = -ShipIcon.rotation - deg_to_rad(90)
	ShadowPivot.get_child(0).rotation = ShipIcon.rotation + deg_to_rad(90)
	
	

func _update_pushback(delta: float) -> void:
	# Spring back toward the normal idle position.
	pushback_velocity += -pushback_offset * pushback_return_strength * delta

	# Dampen the motion so it settles.
	pushback_velocity = pushback_velocity.lerp(Vector2.ZERO, pushback_damping * delta)

	pushback_offset += pushback_velocity * delta

	# Damage wobble fadeout.
	damage_wobble = move_toward(damage_wobble, 0.0, damage_wobble_decay * delta)


func apply_damage_pushback(amm : float, shieldamm : float, Instigator : BattleShipStats, direct : bool) -> void:
	if (Instigator == null):
		return
	var my_center := ShipIcon.global_position

	var center = get_viewport_rect().size / 2
	# Push away from the thing that hit us.
	var direction = my_center - center

	if direction.length_squared() < 0.001:
		# Fallback: push away from the world center.
		direction = my_center - center

	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT

	direction = direction.normalized()

	pushback_velocity += direction * 40 * amm
	damage_wobble = 1.0

func Pop(t : bool):
	var PopTween = create_tween()
	var FinalPos : Vector2 = Vector2(0, 0)
	if (t):
		if (Fr):
			FinalPos.x = 100
		else:
			FinalPos.x = -40
	else:
		FinalPos.x = 30

	PopTween.set_ease(Tween.EASE_OUT)
	PopTween.set_trans(Tween.TRANS_QUAD)
	PopTween.tween_property($HBoxContainer/Control/Control, "position", FinalPos, 0.2)
	await PopTween.finished
	
func SetStats(S : BattleShipStats, Friendly : bool) -> void:
	Ship = S
	Fr = Friendly
	ShipNameLabel.text = S.Name
	
	var newIcon : Texture
	if (S.ShipIcon is AnimatedTexture):
		#We make sure to duplicate it so we can pause it without pausing everything else on the world
		newIcon = S.ShipIcon.duplicate()
	else:
		newIcon = S.ShipIcon
		
	ShipIcon.texture = newIcon
	ShadowPivot.get_child(0).texture = newIcon
	HullLabel.text = "{0}/{1}".format([roundi(S.CurrentHull + S.Shield), S.Hull]).replace(".0", "")
	HullBar.max_value = S.Hull
	ShieldBar.max_value = S.MaxShield
	HullBar.value = S.CurrentHull
	ShieldBar.value = 0
	FPLabel.text = "[color=#f35033]FRPW[/color] {0}".format([S.GetFirePower()]).replace(".0", "")
	SPDLabel.text = "[color=#308a4d]SPD[/color] {0}".format([roundi(S.GetSpeed())])
	WeightLabel.text = "[color=#828dff]WGHT[/color] {0}".format([S.GetWeight()]).replace(".0", "")
	DefenceLabel.text = "[color=#7bb0b4]DEF[/color] {0}".format([roundi(S.GetDef())])
	
	var t : Texture2D = S.ShipIcon
	var tsize = t.get_size()
	FirePart.scale.x = tsize.x / 2
	FirePart.scale.y = FirePart.scale.x * 1.5
	Shield.scale = Vector2(tsize.y, tsize.y) * 2
	Shield.visible = false
	
	S.ShipDamaged.connect(apply_damage_pushback)
	S.ShieldChanged.connect(ShieldChanged)
	#ShipIcon.flip_v = !Friendly
	#ShadowPivot.get_child(0).flip_v = !Friendly
	
	if (Friendly):
		$HBoxContainer.move_child($HBoxContainer/PanelContainer2, 0)
	else:
		ShipNameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ShipNameLabel.get_parent().move_child(ShipNameLabel, 1)
		HullLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		$HBoxContainer.move_child($HBoxContainer/PanelContainer2, 1)
		HasMovePanel.get_parent().move_child(HasMovePanel, 0)
	
	HasMovePanel.visible = false
	TurnPanel.self_modulate.a = 0

func ShieldChanged(newShield : float) -> void:
	Shield.visible = newShield > 0

func GetShipPos() -> Vector2:
	return ShipIcon.global_position

func ActionPicked(C : CardStats, Targets : Array[BattleShipStats] = []) -> void:
	#ActionParent.visible = true
	var TexNode = TextureRect.new()
	TexNode.texture = C.Icon
	TexNode.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	TexNode.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	TexNode.custom_minimum_size = Vector2(38,22)
	TexNode.mouse_filter = Control.MOUSE_FILTER_PASS
	TexNode.mouse_entered.connect(OnActionHovered.bind(C, Targets))
	TexNode.mouse_exited.connect(OnActionUnhovered.bind())
	ActionParent.add_child(TexNode)

func PassiveAdded(C : CardStats) -> void:
	var TexNode = TextureRect.new()
	TexNode.texture = C.Icon
	TexNode.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	TexNode.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	TexNode.custom_minimum_size = Vector2(38,22)
	TexNode.mouse_filter = Control.MOUSE_FILTER_PASS
	TexNode.mouse_entered.connect(OnActionHovered.bind(C))
	TexNode.mouse_exited.connect(OnActionUnhovered.bind())
	TexNode.modulate = Color("f58800ff")
	PassiveParent.add_child(TexNode)

func ClearPassives() -> void:
	for g in PassiveParent.get_children():
		g.queue_free()

func OnActionHovered(C : CardStats, Targets : Array[BattleShipStats] = []) -> void:
	ActionHovered.emit(Ship, C, Targets)

func OnActionUnhovered() -> void:
	ActionUnhovered.emit()

func ActionRemoved(Tex : Texture) -> void:
	for g : TextureRect in ActionParent.get_children():
		if (g.texture == Tex):
			g.free()
			break
	#ActionParent.visible = ActionParent.get_child_count() > 0



func OnNewTurnStarted() -> void:
	HasMovePanel.visible = true

func OnActionsPerformed() -> void:
	HasMovePanel.visible = false

func Refresh() -> void:
	if (Destroyed):
		return
	UpdateStats(Ship)
	ToggleDmgBuff(Ship.FirePowerBuff > 1, Ship.FirePowerBuff)
	ToggleSpeedBuff(Ship.SpeedBuff > 1, Ship.SpeedBuff)
	ToggleDefBuff(Ship.DefBuff > 0, Ship.DefBuff)
	
	ToggleDmgDebuff(Ship.FirePowerDeBuff > 0)
	ToggleSpeedDebuff(Ship.SpeedDeBuff > 0)
	ToggleDefDeBuff(Ship.DefDebuff > 0)
	ToggleFire(Ship.IsOnFire)


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
	var desttw = create_tween()
	desttw.tween_property(self, "modulate", Color(1,1,1,0), 1)
	await desttw.finished
	queue_free()

func _on_button_pressed() -> void:
	OnFallbackPressed.emit()

var tw : Tween

func _on_panel_container_2_mouse_entered() -> void:
	if (tw != null):
		tw.kill()
	tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property($HBoxContainer/PanelContainer2, "custom_minimum_size", Vector2(180,116), 0.15)
	tw.finished.connect(ToggleStatVisibility.bind(true))
	Hovered.emit()

func ToggleStatVisibility(t : bool) -> void:
	statContainer.visible = t
	#PassiveParent.visible = t
	HullLabel.visible = t
	
func _on_panel_container_2_mouse_exited() -> void:
	if (tw != null):
		tw.kill()
	tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property($HBoxContainer/PanelContainer2, "custom_minimum_size", Vector2(180, 0), 0.15)
	ToggleStatVisibility(false)
	Unhovered.emit()

var animTween : Tween

func PlayAnim(type : AnimatioType) -> void:
	if (animTween != null):
		return
		
	if (type == AnimatioType.EVASIVE):
		#animOffset = Vector2.ZERO
		animTween = create_tween()
		animTween.set_ease(Tween.EASE_IN_OUT)
		animTween.set_trans(Tween.TRANS_QUAD)
		animTween.tween_property(self, "animOffset", Vector2(0, 60), 0.5)
		animTween.set_parallel(true)
		if (Fr):
			animTween.tween_property(self, "facing_offset_degrees", 10, 0.5)
		else:
			animTween.tween_property(self, "facing_offset_degrees", -10, 0.5)
			
		await animTween.finished
		animTween = create_tween()
		animTween.set_ease(Tween.EASE_IN_OUT)
		animTween.set_trans(Tween.TRANS_QUAD)
		animTween.tween_property(self, "animOffset", Vector2(0, -60), 0.5)
		animTween.set_parallel(true)
		if (Fr):
			animTween.tween_property(self, "facing_offset_degrees", -10, 0.5)
		else:
			animTween.tween_property(self, "facing_offset_degrees", 10, 0.5)
			
		await animTween.finished
		animTween = create_tween()
		animTween.set_ease(Tween.EASE_IN_OUT)
		animTween.set_trans(Tween.TRANS_QUAD)
		animTween.tween_property(self, "animOffset", Vector2(0, 0), 0.5)
		animTween.set_parallel(true)
		animTween.tween_property(self, "facing_offset_degrees", 0, 0.5)
		
		animTween = null
		#drift_speed = 0.7
		#drift_speed = 0.7
	
enum AnimatioType{
	NONE,
	EVASIVE,
}
