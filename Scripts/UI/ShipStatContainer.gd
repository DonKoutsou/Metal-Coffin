@tool
extends VBoxContainer

class_name ShipStatContainer

@export_file("*.tscn") var Tooltipscene : String

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
	STName = Stat
	$HBoxContainer/Label.text = STAT_CONST.STATS.keys()[Stat].replace("_", " ")
	Metric =  STAT_CONST.GetStatMetric(STName)
	var MaxVal = STAT_CONST.GetStatMaxValue(Stat)

	$ProgressBar.max_value = MaxVal

	$ProgressBar/ItemBar.max_value = MaxVal
	$ProgressBar/ItemNegBar.max_value = MaxVal

func SetDataCustom(MaxValue : float, StatMetric : String, StatName : String, Stat : STAT_CONST.STATS) -> void:
	STName = Stat
	Metric = StatMetric
	$HBoxContainer/Label.text = StatName
	$ProgressBar.max_value = MaxValue
	$ProgressBar/ItemBar.max_value = MaxValue
	$ProgressBar/ItemNegBar.max_value = MaxValue

func UpdateStatCustom(StatVal : float, ItemVar : float, ItemPenalty : float) -> void:
	$ProgressBar/ItemNegBar.visible = ItemPenalty > 0
	$ProgressBar.value = StatVal
	$ProgressBar/ItemBar.value = StatVal + ItemVar
	$ProgressBar/ItemNegBar.value = StatVal + ItemVar - ItemPenalty
	#var Max = var_to_str($ProgressBar.max_value).replace(".0", "")
	$HBoxContainer/Label2.text = "{0} {1}".format([var_to_str(StatVal + ItemVar - ItemPenalty).replace(".0", ""), Metric])

func UpdateStatValue(StatVal : float, ItemVar : float, ItemPenalty : float) -> void:

	$ProgressBar/ItemNegBar.visible = ItemPenalty > 0
	
	$ProgressBar.value = StatVal
	$ProgressBar/ItemBar.value = StatVal + ItemVar
	$ProgressBar/ItemNegBar.value = StatVal + ItemVar - ItemPenalty
	#$ProgressBar/ShipBar.value = StatVal + ItemVar + ShipVar
	#var Max = var_to_str($ProgressBar.max_value).replace(".0", "")
	if (!STAT_CONST.ShouldStatStack(STName)):
		$HBoxContainer/Label2.text = "{0} {1}".format([var_to_str(max(StatVal, ItemVar) - ItemPenalty).replace(".0", ""), Metric])
	else:
		$HBoxContainer/Label2.text = "{0} {1}".format([var_to_str(StatVal + ItemVar - ItemPenalty).replace(".0", ""), Metric])


func _on_mouse_entered() -> void:
	if (STName == -1):
		return
	var tipscene : PackedScene = ResourceLoader.load(Tooltipscene)
	Tooltip = tipscene.instantiate()
	
	Ingame_UIManager.GetInstance().add_child(Tooltip)
	Tooltip.set_deferred("size", Vector2(Tooltip.size.x,0))
	Tooltip.get_child(0).text = STAT_CONST.GetTooltip(STName)
	
	Tooltip.global_position = get_global_mouse_position()
	
	set_physics_process(true)
	PositionTooltip()

func _on_mouse_exited() -> void:
	if (Tooltip == null):
		return
	Tooltip.queue_free()
	set_physics_process(false)
