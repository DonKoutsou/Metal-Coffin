@tool
extends VBoxContainer

class_name CapCrStatSlider

signal StatChanged

var CurrentStat : ShipStat

var ItemAddedStat : float = 0
var ItemPenaltyStat : float = 0

func _SetData(Stat : ShipStat) -> void:
	#$ShipStatContainer/HBoxContainer/Label.theme_override_font_sizes/font_size = 2
	CurrentStat = Stat
	#$Label.text = STAT_CONST.STATS.keys()[Stat.StatName]
	#$HBoxContainer/Label.text = var_to_str(Stat.GetFinalValue()).replace(".0", "")
	$HSlider.min_value = 0
	var MaxV = STAT_CONST.GetStatMaxValue(Stat.StatName)
	if (MaxV >= 1000):
		$HSlider.step = 10
	$HSlider.max_value = MaxV
	$HSlider.value = Stat.GetFinalValue()
	$ShipStatContainer.SetData(Stat.StatName)
	$ShipStatContainer.UpdateStatValue(Stat.GetBaseValue(), ItemAddedStat, ItemPenaltyStat)

func ResetItemStat() -> void:
	ItemAddedStat = 0
	ItemPenaltyStat = 0
	$ShipStatContainer.UpdateStatValue(CurrentStat.GetBaseValue(), ItemAddedStat, ItemPenaltyStat)
	
func AddToItemStat(Amm : float, PenaltyAmm : float) -> void:
	ItemAddedStat += Amm
	ItemPenaltyStat += PenaltyAmm
	#CurrentStat.StatBase = ItemAddedStat
	$ShipStatContainer.UpdateStatValue(CurrentStat.GetBaseValue(), ItemAddedStat, ItemPenaltyStat)
	
func _on_h_slider_value_changed(value: float) -> void:
	#$HBoxContainer/Label.text = var_to_str(value).replace(".0", "")
	CurrentStat.StatBase = value
	$ShipStatContainer.UpdateStatValue(CurrentStat.GetBaseValue(), ItemAddedStat, ItemPenaltyStat)
	StatChanged.emit()

func GetStatValue() -> float:
	return CurrentStat.GetBaseValue() + ItemAddedStat - ItemPenaltyStat
