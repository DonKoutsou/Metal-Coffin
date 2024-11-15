extends VBoxContainer

class_name CaptainStatContainer

func SetData(Stat : ShipStat) -> void:
	$HBoxContainer/Label.text = Stat.StatName
	$ProgressBar.max_value = Stat.StatMax
	$ProgressBar.value = Stat.StatBase
	$HBoxContainer/Label2.text = var_to_str(Stat.StatBase)
func SetTradeData(Stat : BaseShipStat) -> void:
	if (Stat != null):
		$ProgressBar.value = Stat.StatBuff
	else :
		$ProgressBar.value = 0
	$ProgressBar/ProgressBar.max_value = 1
	$ProgressBar/ProgressBar.value = 0
