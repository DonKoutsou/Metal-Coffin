extends PanelContainer

class_name CardFightShipViz

func _ready() -> void:
	#$Panel.visible = false
	ToggleFire(false)

func SetStats(S : BattleShipStats, Friendly : bool) -> void:
	$HBoxContainer/Label.text = S.Name.substr(0, 3)
	$HBoxContainer/TextureRect.texture = S.ShipIcon
	$HBoxContainer/VBoxContainer/RichTextLabel.text = "[color=#c19200]HL[/color] : " + var_to_str(S.Hull)
	$HBoxContainer/VBoxContainer/RichTextLabel2.text = "[color=#c19200]SPD[/color] : " + var_to_str(S.Speed)
	$HBoxContainer/VBoxContainer/RichTextLabel3.text = "[color=#c19200]FP[/color] : " + var_to_str(S.FirePower)
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
