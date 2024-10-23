extends VBoxContainer

class_name ShipStatContainer

var STName

func SetData(Stat : ShipStat) -> void:
	STName = Stat.StatName
	$Label.text = Stat.StatName
	$ProgressBar.max_value = Stat.StatMax
	$ProgressBar.value = Stat.GetShipBuff()
	$ProgressBar/ProgressBar.max_value = Stat.StatMax

func UpdateStatValue(StatVal : float) -> void:
	$ProgressBar/ProgressBar.value = StatVal
