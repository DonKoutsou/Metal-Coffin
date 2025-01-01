extends PanelContainer

class_name CardFightShipViz

func SetStats(S : BattleShipStats, Friendly : bool) -> void:
	$HBoxContainer/TextureRect.texture = S.ShipIcon
	$HBoxContainer/VBoxContainer/Label.text = "HL : " + var_to_str(roundi(S.Hull))
	$HBoxContainer/VBoxContainer/Label2.text = "SPD : " + var_to_str(roundi(S.Speed))
	$HBoxContainer/VBoxContainer/Label4.text = "FP : " + var_to_str(roundi(S.FirePower))
	$HBoxContainer/TextureRect.flip_v = !Friendly
