extends VBoxContainer

class_name ShipStatContainer

var STName

func SetData(Stat : ShipStat) -> void:
	STName = Stat.StatName
	$HBoxContainer/Label.text = Stat.StatName.replace("_", " ")
	$ProgressBar.max_value = Stat.StatMax
	$ProgressBar.value = Stat.GetShipBuff()
	$ProgressBar/ShipBar.max_value = Stat.StatMax
	$ProgressBar/ItemBar.max_value = Stat.StatMax
	
func SetTradeData(Stat : BaseShipStat) -> void:
	if (Stat != null):
		$ProgressBar.value = Stat.StatBuff
	else :
		$ProgressBar.value = 0
	$ProgressBar/ShipBar.max_value = 1
	$ProgressBar/ItemBar.max_value = 1
	$ProgressBar/ShipBar.value = 0
	$ProgressBar/ItemBar.value = 0

func UpdateStatValue(StatVal : float, ItemVar : float, ShipVar : float) -> void:
	$ProgressBar.value = StatVal
	$ProgressBar/ItemBar.value = StatVal + ItemVar
	$ProgressBar/ShipBar.value = StatVal + ItemVar + ShipVar
	var Max = var_to_str($ProgressBar.max_value).replace(".0", "")
	$HBoxContainer/Label2.text = "|{0} / {1}|".format([var_to_str(StatVal + ItemVar + ShipVar).replace(".0", ""), Max])
