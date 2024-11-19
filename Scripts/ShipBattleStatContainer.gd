extends VBoxContainer

class_name ShipBattleStatContainer

func SetData(StatName : String, StatVal : float, StatMax : float) -> void:
	$HBoxContainer/Label.text = StatName.replace("_", " ")
	$ProgressBar.max_value = StatMax
	$ProgressBar.value = StatVal
	$HBoxContainer/Label2.text = var_to_str(StatVal).replace(".0", "")
