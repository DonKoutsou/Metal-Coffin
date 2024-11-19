extends VBoxContainer

class_name CaptainStatContainer

func SetData(Stat : ShipStat) -> void:
	$HBoxContainer/Label.text = Stat.StatName.replace("_", " ")
	if (Stat.StatName == "SPEED"):
		$ProgressBar.max_value = (Stat.StatMax * 60) * 3.6
		$ProgressBar.value = (Stat.StatBase * 60) * 3.6
		$HBoxContainer/Label2.text = var_to_str((Stat.StatBase * 60) * 3.6) + "km/h"
	else:
		$ProgressBar.max_value = Stat.StatMax
		$ProgressBar.value = Stat.StatBase
		$HBoxContainer/Label2.text = var_to_str(Stat.StatBase).replace(".0", "")

func SetTradeData(Stat : BaseShipStat) -> void:
	if (Stat != null):
		$ProgressBar.value = Stat.StatBuff
	else :
		$ProgressBar.value = 0
	$ProgressBar/ProgressBar.max_value = 1
	$ProgressBar/ProgressBar.value = 0
