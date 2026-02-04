@tool
extends VBoxContainer

class_name ShipStatContainer

@export_file("*.tscn") var Tooltipscene : String
@export_group("Nodes")
@export var StatNameLabel : Label
@export var StatValueLabel : Label
@export var ShipStatBar : ProgressBar
@export var ItemStatBar : ProgressBar
@export var ItemNegativeBar : ProgressBar

var STName = -1

var Metric = ""

var Tooltip : Control

func _ready() -> void:
	set_physics_process(false)

func _physics_process(_delta: float) -> void:
	PositionTooltip()

func PositionTooltip() -> void:
	var Mpos = get_global_mouse_position() 
	var VPRect =  get_viewport().get_visible_rect()
	var DistanceFromDown = VPRect.size.y - get_global_mouse_position().y
	var DistFromRight = VPRect.size.x - get_global_mouse_position().x
	var Diff = Tooltip.size.y - DistanceFromDown
	var Diff2 = Tooltip.size.x - DistFromRight
	
	var FinalPos = Mpos
	if (Diff > 0):
		FinalPos -= Vector2(0,Diff)
	if (Diff2 > 0):
		FinalPos -= Vector2(Diff2,0)
	
	Tooltip.global_position = FinalPos
	#Tooltip.global_position = get_global_mouse_position()

func SetData(Stat : STAT_CONST.STATS) -> void:
	#store stat type and the metric
	STName = Stat
	Metric =  STAT_CONST.GetStatMetric(STName)
	
	#Set the stat name to the label
	StatNameLabel.text = STAT_CONST.STATS.keys()[Stat].replace("_", " ")
	
	#assign the max possible value of the stat to the progress bars
	var MaxVal = STAT_CONST.GetStatMaxValue(Stat)

	ShipStatBar.max_value = MaxVal
	ItemStatBar.max_value = MaxVal
	ItemNegativeBar.max_value = MaxVal

#used for "custom" stats that are pseudo stat, created from the combination of others, like speed and range
func SetDataCustom(MaxValue : float, StatMetric : String, StatName : String, Stat : STAT_CONST.STATS) -> void:
	#store stat type and the metric
	STName = Stat
	Metric = StatMetric
	
	#Set the stat name on the label
	StatNameLabel.text = StatName
	
	#assign the max possible value of the stat to the progress bars
	ShipStatBar.max_value = MaxValue
	ItemStatBar.max_value = MaxValue
	ItemNegativeBar.max_value = MaxValue


func UpdateStatCustom(StatVal : float, ItemVar : float, ItemPenalty : float) -> void:
	
	StatValueLabel.text = "{0} {1}".format([var_to_str(StatVal + ItemVar - ItemPenalty).replace(".0", ""), Metric])

	ShipStatBar.value = StatVal
	ItemStatBar.value = StatVal + ItemVar
	
	ItemNegativeBar.visible = ItemPenalty > 0
	ItemNegativeBar.value = StatVal + ItemVar - ItemPenalty
	
func UpdateStatValue(StatVal : float, ItemVar : float, ItemPenalty : float) -> void:

	if (!STAT_CONST.ShouldStatStack(STName)):
		StatValueLabel.text = "{0} {1}".format([var_to_str(max(StatVal, ItemVar) - ItemPenalty).replace(".0", ""), Metric])
	else:
		StatValueLabel.text = "{0} {1}".format([var_to_str(StatVal + ItemVar - ItemPenalty).replace(".0", ""), Metric])
	
	ShipStatBar.value = StatVal
	ItemStatBar.value = StatVal + ItemVar
	ItemNegativeBar.visible = ItemPenalty > 0
	ItemNegativeBar.value = StatVal + ItemVar - ItemPenalty

func _on_mouse_entered() -> void:
	var tipscene : PackedScene = ResourceLoader.load(Tooltipscene)
	Tooltip = tipscene.instantiate()
	
	Ingame_UIManager.GetInstance().add_child(Tooltip)
	Tooltip.set_deferred("size", Vector2(Tooltip.size.x,0))
	Tooltip.get_child(0).text = STAT_CONST.GetTooltip(STName)
	
	Tooltip.global_position = get_global_mouse_position()
	
	PositionTooltip()
	set_physics_process(true)

func _on_mouse_exited() -> void:
	Tooltip.queue_free()
	set_physics_process(false)
