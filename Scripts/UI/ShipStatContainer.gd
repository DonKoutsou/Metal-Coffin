@tool
extends VBoxContainer

class_name ShipStatContainer

var STName

func SetData(Stat : STAT_CONST.STATS) -> void:
	STName = Stat
	$HBoxContainer/Label.text = STAT_CONST.STATS.keys()[Stat].replace("_", " ")
	var MaxVal = STAT_CONST.GetStatMaxValue(Stat)
	if (Stat == STAT_CONST.STATS.SPEED):
		MaxVal *= 360
	$ProgressBar.max_value = MaxVal
	#$ProgressBar.value = Stat.GetShipBuff()
	#$ProgressBar/ShipBar.max_value = MaxVal
	$ProgressBar/ItemBar.max_value = MaxVal
	$ProgressBar/ItemNegBar.max_value = MaxVal

func UpdateStatValue(StatVal : float, ItemVar : float, ItemPenalty : float) -> void:
	if (STName == STAT_CONST.STATS.SPEED):
		StatVal *= 360
		ItemVar *= 360
		ItemPenalty *= 360
	$ProgressBar/ItemNegBar.visible = ItemPenalty > 0
	
	$ProgressBar.value = StatVal
	$ProgressBar/ItemBar.value = StatVal + ItemVar
	$ProgressBar/ItemNegBar.value = StatVal + ItemVar - ItemPenalty
	#$ProgressBar/ShipBar.value = StatVal + ItemVar + ShipVar
	var Max = var_to_str($ProgressBar.max_value).replace(".0", "")
	$HBoxContainer/Label2.text = "|{0} / {1}|".format([var_to_str(StatVal + ItemVar - ItemPenalty).replace(".0", ""), Max])
	
