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
@export var FPLabel : RichTextLabel
@export var SPDLabel : RichTextLabel

const StatText = "[color=#ffc315]HULL[/color][p][color=#6be2e9]SHIELD[/color][p][color=#308a4d]SPEED[/color][p][color=#f35033]FPWR[/color]"

signal OnFallbackPressed()

func _ready() -> void:
	ToggleFire(false)

func SetStats(S : BattleShipStats, Friendly : bool) -> void:
	ShipNameLabel.text = S.Name
	ShipIcon.texture = S.ShipIcon
	ShipIcon.get_child(0).texture = S.ShipIcon
	HullLabel.text = "{0}/{1}".format([snapped(S.CurrentHull + S.Shield, 0.1), S.Hull]).replace(".0", "")
	HullBar.max_value = S.Hull
	ShieldBar.max_value = S.Hull
	HullBar.value = S.CurrentHull
	ShieldBar.value = 0
	FPLabel.text = "[color=#f35033]FRPW[/color] {0}".format([S.GetFirePower()]).replace(".0", "")
	SPDLabel.text = "[color=#308a4d]SPD[/color] {0}".format([roundi(S.GetSpeed())])
	
	ShipIcon.flip_v = !Friendly
	ShipIcon.get_child(0).flip_v = !Friendly
	#$HBoxContainer/PanelContainer/VBoxContainer/PanelContainer2.visible = Friendly
	if (Friendly):
		$HBoxContainer.move_child($HBoxContainer/VBoxContainer, 0)
	else:
		ShipNameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ShipNameLabel.get_parent().move_child(ShipNameLabel, 1)
		HullLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		$HBoxContainer.move_child($HBoxContainer/VBoxContainer, 1)
	TurnPanel.self_modulate.a = 0

func UpdateStats(S : BattleShipStats) -> void:
	HullBar.value = S.CurrentHull
	HullLabel.text = "{0}/{1}".format([snapped(S.CurrentHull + S.Shield, 0.1), S.Hull]).replace(".0", "")
	ShieldBar.value = S.Shield
	FPLabel.text = "[color=#f35033]FRPW[/color] {0}".format([S.GetFirePower()]).replace(".0", "")
	SPDLabel.text = "[color=#308a4d]SPD[/color] {0}".format([roundi(S.GetSpeed())])

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
	#tw.set_trans(Tween.TRANS_CIRC)
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

func ToggleDmgBuff(t : bool, amm : float) -> void:
	FPBuff.amount = 5 * amm
	FPBuff.visible = t

func ToggleDmgDebuff(t : bool) -> void:
	FPDeBuff.visible = t

func ToggleSpeedBuff(t : bool, amm : float) -> void:
	SpeedBuff.amount = 5 * amm
	SpeedBuff.visible = t

func ToggleSpeedDebuff(t : bool) -> void:
	SpeedDeBuff.visible = t

func IsOnFire() -> bool:
	return FirePart.visible

func ShipDestroyed() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1,1,1,0), 1)
	await tw.finished
	get_parent().queue_free()

func _on_button_pressed() -> void:
	OnFallbackPressed.emit()
