@tool
extends VBoxContainer

class_name ShipStatContainer

var STName

func SetData(Stat : STAT_CONST.STATS) -> void:
	STName = Stat
	$HBoxContainer/Label.text = STAT_CONST.STATS.keys()[Stat].replace("_", " ") + " | " + STAT_CONST.GetStatMetric(STName)
	var MaxVal = STAT_CONST.GetStatMaxValue(Stat)

	$ProgressBar.max_value = MaxVal

	$ProgressBar/ItemBar.max_value = MaxVal
	$ProgressBar/ItemNegBar.max_value = MaxVal

func SetDataCustom(MaxValue : float, StatMetric : String, StatName : String) -> void:
	$HBoxContainer/Label.text = StatName + " | " + StatMetric
	$ProgressBar.max_value = MaxValue
	$ProgressBar/ItemBar.max_value = MaxValue
	$ProgressBar/ItemNegBar.max_value = MaxValue

func UpdateStatCustom(StatVal : float, ItemVar : float, ItemPenalty : float) -> void:
	$ProgressBar/ItemNegBar.visible = ItemPenalty > 0
	$ProgressBar.value = StatVal
	$ProgressBar/ItemBar.value = StatVal + ItemVar
	$ProgressBar/ItemNegBar.value = StatVal + ItemVar - ItemPenalty
	var Max = var_to_str($ProgressBar.max_value).replace(".0", "")
	$HBoxContainer/Label2.text = "|{0} / {1}|".format([var_to_str(StatVal + ItemVar - ItemPenalty).replace(".0", ""), Max])

func UpdateStatValue(StatVal : float, ItemVar : float, ItemPenalty : float) -> void:

	$ProgressBar/ItemNegBar.visible = ItemPenalty > 0
	
	$ProgressBar.value = StatVal
	$ProgressBar/ItemBar.value = StatVal + ItemVar
	$ProgressBar/ItemNegBar.value = StatVal + ItemVar - ItemPenalty
	#$ProgressBar/ShipBar.value = StatVal + ItemVar + ShipVar
	var Max = var_to_str($ProgressBar.max_value).replace(".0", "")
	if (!STAT_CONST.ShouldStatStack(STName)):
		$HBoxContainer/Label2.text = "|{0} / {1}|".format([var_to_str(max(StatVal, ItemVar) - ItemPenalty).replace(".0", ""), Max])
	else:
		$HBoxContainer/Label2.text = "|{0} / {1}|".format([var_to_str(StatVal + ItemVar - ItemPenalty).replace(".0", ""), Max])
