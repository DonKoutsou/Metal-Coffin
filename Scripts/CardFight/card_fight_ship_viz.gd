extends PanelContainer

class_name CardFightShipViz

func _ready() -> void:
	$Panel.visible = false
	ToggleFire(false)

func SetStats(S : BattleShipStats, Friendly : bool) -> void:
	$HBoxContainer/TextureRect.texture = S.ShipIcon
	$HBoxContainer/VBoxContainer/Label.text = "HL : " + var_to_str(S.Hull)
	$HBoxContainer/VBoxContainer/Label2.text = "SPD : " + var_to_str(S.Speed)
	$HBoxContainer/VBoxContainer/Label4.text = "FP : " + var_to_str(S.FirePower)
	$HBoxContainer/TextureRect.flip_v = Friendly

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
