extends VBoxContainer

class_name ShipStatContainer

var STName

func SetData(Stat : ShipStat) -> void:
	STName = Stat.StatName
	$Label.text = Stat.StatName
	$ProgressBar.max_value = Stat.StatMax
	$ProgressBar.value = Stat.GetShipBuff()
	$ProgressBar/ProgressBar.max_value = Stat.StatMax
	
func SetTradeData(Stat : BaseShipStat) -> void:
	if (Stat != null):
		$ProgressBar.value = Stat.StatBuff
	else :
		$ProgressBar.value = 0
	$ProgressBar/ProgressBar.max_value = 1
	$ProgressBar/ProgressBar.value = 0

func UpdateStatValue(StatVal : float, ShipVar : float) -> void:
	$ProgressBar.value = ShipVar
	$ProgressBar/ProgressBar.value = StatVal
