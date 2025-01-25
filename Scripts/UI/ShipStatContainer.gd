extends VBoxContainer

class_name ShipStatContainer

var STName

func SetData(Stat : STAT_CONST.STATS) -> void:
	STName = Stat
	
	$HBoxContainer/Label.text = STAT_CONST.STATS.keys()[Stat].replace("_", " ")
	var MaxVal = STAT_CONST.GetStatMaxValue(Stat)
	$ProgressBar.max_value = MaxVal
	#$ProgressBar.value = Stat.GetShipBuff()
	$ProgressBar/ShipBar.max_value = MaxVal
	$ProgressBar/ItemBar.max_value = MaxVal

func UpdateStatValue(StatVal : float, ItemVar : float) -> void:
	$ProgressBar.value = StatVal
	$ProgressBar/ItemBar.value = StatVal + ItemVar
	#$ProgressBar/ShipBar.value = StatVal + ItemVar + ShipVar
	var Max = var_to_str($ProgressBar.max_value).replace(".0", "")
	$HBoxContainer/Label2.text = "|{0} / {1}|".format([var_to_str(StatVal + ItemVar).replace(".0", ""), Max])
	
