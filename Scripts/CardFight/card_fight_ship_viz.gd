extends Button

class_name CardFightShipViz

@export var ShipNameLabel : Label
@export var ShipIcon : TextureRect
@export var StatLabel : RichTextLabel
@export var FriendlyPanel : Panel

const StatText = "[color=#ffc315]HULL[/color][p][color=#6be2e9]SHIELD[/color][p][color=#308a4d]SPEED[/color][p][color=#f35033]FPWR[/color]"

func _ready() -> void:
	#$Panel.visible = false
	ToggleFire(false)

func SetStats(S : BattleShipStats, Friendly : bool) -> void:
	ShipNameLabel.text = S.Name
	ShipIcon.texture = S.ShipIcon
	var Hull = var_to_str(snapped(S.Hull, 0.1)).replace(".0", "")
	var Shield = var_to_str(snapped(S.Shield, 0.1)).replace(".0", "")
	var Speed = var_to_str(snapped(S.Speed, 0.1)).replace(".0", "")
	var Firep = var_to_str(S.GetFirePower()).replace(".0", "")
	if (S.FirePowerBuff > 1):
		Firep = "[color=#308a4d]" + Firep + "[/color]"
	StatLabel.text = "[right]{0}[right]{1}[right]{2}[right]{3}".format([Hull, Shield, Speed, Firep])
	#ShipIcon.flip_v = !Friendly
	FriendlyPanel.visible = false
	
func SetStatsAnimation(S : BattleShipStats, Friendly : bool) -> void:
	ShipNameLabel.text = S.Name
	ShipIcon.texture = S.ShipIcon
	FriendlyPanel.visible = Friendly

func Dissable() -> void:
	FriendlyPanel.visible = false

func Enable() -> void:
	FriendlyPanel.visible = true
	var tw = create_tween()
	#tw.set_trans(Tween.TRANS_CIRC)
	tw.tween_property(FriendlyPanel, "modulate", Color(1,1,1,0), 1)
	tw.tween_callback(TweenEnded)

func TweenEnded() -> void:
	var tw = create_tween()
	#tw.set_trans(Tween.TRANS_CIRC)
	if (FriendlyPanel.modulate == Color(1,1,1,0)):
		tw.tween_property(FriendlyPanel, "modulate", Color(1,1,1,1), 1)
	else:
		tw.tween_property(FriendlyPanel, "modulate", Color(1,1,1,0), 1)
	tw.tween_callback(TweenEnded)

func ToggleFire(t : bool) -> void:
	$HBoxContainer/VBoxContainer/TextureRect/GPUParticles2D.visible = t

func IsOnFire() -> bool:
	return $HBoxContainer/VBoxContainer/TextureRect/GPUParticles2D.visible

func ShipDestroyed() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1,1,1,0), 1)
	await tw.finished
	queue_free()
