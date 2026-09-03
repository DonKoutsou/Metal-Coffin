@tool
extends ShipStatContainer

class_name CapCrStatSlider

@export var slider : HSlider

signal StatChanged

var ItemAddedStat : float = 0
var ItemPenaltyStat : float = 0

func SetData(Stat : STAT_CONST.STATS) -> void:
	super(Stat)

	$HSlider.min_value = 0
	var MaxV = STAT_CONST.GetStatMaxValue(STName)
	if (MaxV >= 1000):
		$HSlider.step = 10
	$HSlider.max_value = MaxV
	

#used for "custom" stats that are pseudo stat, created from the combination of others, like speed and range
func SetDataCustom(MaxValue : float, StatMetric : String, StatName : String, Stat : STAT_CONST.STATS, step : float = 1.0) -> void:
	super(MaxValue, StatMetric, StatName, Stat)
	
	slider.max_value = MaxValue
	slider.step = step

func UpdateStatCustom(StatVal : float, ItemVar : float, ItemPenalty : float) -> void:
	super(StatVal, ItemVar, ItemPenalty)
	$HSlider.set_value_no_signal(StatVal)

func UpdateStatValue(StatVal : float, ItemVar : float, ItemPenalty : float) -> void:
	super(StatVal, ItemVar, ItemPenalty)
	$HSlider.set_value_no_signal(StatVal)

func _on_h_slider_value_changed(value: float) -> void:
	StatChanged.emit(STName, value)
