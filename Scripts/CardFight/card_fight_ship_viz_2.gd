extends Control

class_name CardFightShipViz2

@export var ShipNameLabel : Label
@export var ShipIcon : TextureRect
@export var StatLabel : RichTextLabel
@export var FriendlyPanel : PanelContainer
@export var SpeedBuff : GPUParticles2D
@export var FPBuff : GPUParticles2D
@export var FirePart : GPUParticles2D

const StatText = "[color=#ffc315]HULL[/color][p][color=#6be2e9]SHIELD[/color][p][color=#308a4d]SPEED[/color][p][color=#f35033]FPWR[/color]"

func _ready() -> void:
	#$Panel.visible = false
	$HBoxContainer/PanelContainer/HBoxContainer/RichTextLabel.text = StatText
	ToggleFire(false)

func SetStats(S : BattleShipStats, Friendly : bool) -> void:
	ShipNameLabel.text = S.Name.substr(0, 3)
	ShipIcon.texture = S.ShipIcon
	var Hull = var_to_str(snapped(S.Hull, 0.1)).replace(".0", "")
	var Shield = var_to_str(snapped(S.Shield, 0.1)).replace(".0", "")
	var Speed = var_to_str(snapped(S.GetSpeed(), 0.1)).replace(".0", "")
	var Firep = var_to_str(snapped(S.GetFirePower(), 0.1)).replace(".0", "")
	if (S.FirePowerBuff > 0):
		Firep = "[color=#308a4d]" + Firep + "[/color]"
	if (S.SpeedBuff > 0):
		Speed = "[color=#308a4d]" + Speed + "[/color]"
	if (S.Shield > 0):
		Shield = "[color=#308a4d]" + Shield + "[/color]"
	StatLabel.text = "[right]{0}[right]{1}[right]{2}[right]{3}".format([Hull, Shield, Speed, Firep])
	ShipIcon.flip_v = !Friendly
	if (Friendly):
		$HBoxContainer.move_child($HBoxContainer/PanelContainer, 0)
	else:
		$HBoxContainer.move_child($HBoxContainer/PanelContainer, 1)
	FriendlyPanel.self_modulate.a = 0
	
func SetStatsAnimation(S : BattleShipStats, Friendly : bool) -> void:
	ShipNameLabel.text = S.Name.substr(0, 3)
	ShipIcon.texture = S.ShipIcon
	FriendlyPanel.visible = Friendly

func Dissable() -> void:
	FriendlyPanel.self_modulate.a = 0
	Enabled = false
	ModulateTween.kill()

var Enabled : bool = false

var ModulateTween : Tween

func Enable() -> void:
	Enabled = true
	FriendlyPanel.self_modulate.a = 1
	ModulateTween = create_tween()
	#tw.set_trans(Tween.TRANS_CIRC)
	ModulateTween.tween_property(FriendlyPanel, "self_modulate", Color(1,1,1,0), 1)
	ModulateTween.tween_callback(TweenEnded)

func TweenEnded() -> void:
	if (!Enabled):
		return
	ModulateTween = create_tween()
	#tw.set_trans(Tween.TRANS_CIRC)
	if (FriendlyPanel.self_modulate == Color(1,1,1,0)):
		ModulateTween.tween_property(FriendlyPanel, "self_modulate", Color(1,1,1,1), 1)
	else:
		ModulateTween.tween_property(FriendlyPanel, "self_modulate", Color(1,1,1,0), 1)
	ModulateTween.tween_callback(TweenEnded)

func ToggleFire(t : bool) -> void:
	FirePart.visible = t

func ToggleDmgBuff(t : bool) -> void:
	FPBuff.visible = t

func ToggleSpeedBuff(t : bool) -> void:
	SpeedBuff.visible = t

func IsOnFire() -> bool:
	return FirePart.visible

func ShipDestroyed() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1,1,1,0), 1)
	await tw.finished
	queue_free()
