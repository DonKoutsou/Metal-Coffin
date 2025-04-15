extends Button

class_name CardFightShipViz

const StatText = "[color=#ffc315]HULL[/color] : {0}\n[color=#ffc315]SLD[/color] : {1}\n[color=#ffc315]SPD[/color] : {2}\n[color=#ffc315]FPWR[/color] : {3}"

func _ready() -> void:
	#$Panel.visible = false
	ToggleFire(false)

func SetStats(S : BattleShipStats, Friendly : bool) -> void:
	$HBoxContainer/Label.text = S.Name.substr(0, 3)
	$HBoxContainer/TextureRect.texture = S.ShipIcon
	$HBoxContainer/RichTextLabel.text = StatText.format([var_to_str(snapped(S.Hull, 0.1)).replace(".0", ""), var_to_str(snapped(S.Shield, 0.1)).replace(".0", ""), var_to_str(snapped(S.Speed, 0.1)).replace(".0", ""), var_to_str(snapped(S.FirePower + S.FirePowerBuff, 0.1)).replace(".0", "")])
	$HBoxContainer/TextureRect.flip_v = Friendly
	$Panel.visible = false
func SetStatsAnimation(S : BattleShipStats, Friendly : bool) -> void:
	$HBoxContainer/Label.text = S.Name.substr(0, 3)
	$HBoxContainer/TextureRect.texture = S.ShipIcon
	$Panel.visible = Friendly

func Dissable() -> void:
	$Panel.visible = false

func Enable() -> void:
	$Panel.visible = true
	var tw = create_tween()
	#tw.set_trans(Tween.TRANS_CIRC)
	tw.tween_property($Panel, "modulate", Color(1,1,1,0), 1)
	tw.tween_callback(TweenEnded)

func TweenEnded() -> void:
	var tw = create_tween()
	#tw.set_trans(Tween.TRANS_CIRC)
	if ($Panel.modulate == Color(1,1,1,0)):
		tw.tween_property($Panel, "modulate", Color(1,1,1,1), 1)
	else:
		tw.tween_property($Panel, "modulate", Color(1,1,1,0), 1)
	tw.tween_callback(TweenEnded)

func ToggleFire(t : bool) -> void:
	$GPUParticles2D.visible = t

func IsOnFire() -> bool:
	return $GPUParticles2D.visible

func ShipDestroyed() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1,1,1,0), 1)
	await tw.finished
	queue_free()
