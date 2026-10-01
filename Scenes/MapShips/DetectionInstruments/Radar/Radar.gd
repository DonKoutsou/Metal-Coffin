extends Area2D

class_name Radar

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var VisStat : ShipStat

var Working : bool = true
var Detectable = true

var CurrentVisualRange : float = 110
var StormPenalty : float = 1
var VisualRangePenalty : float = 1

var InsideRadar : Array[Node2D]

signal VisuaLRangeChanged

func _ready() -> void:
	area_entered.connect(BodyEnteredRadar)
	area_exited.connect(BodyLeftRadar)

func ToggleRadar(t : bool):
	Detectable = t
	Working = t
	UpdateVizRange()

func UpdateVizRange():
	var NewRange : float
	if (!Working):
		NewRange = 110 * VisualRangePenalty
	else:
		NewRange = max(110 * VisualRangePenalty, VisStat.GetFinalValue()) * StormPenalty
	NewRange = roundi(NewRange)
	if (NewRange == CurrentVisualRange):
		return
	CurrentVisualRange = NewRange
	(collision_shape_2d.shape as CircleShape2D).radius = CurrentVisualRange
	VisuaLRangeChanged.emit()

func EvaluateRadarrPoint(_Altitude : float) -> void:
	pass

func EvaluateRadarTargets(_Altitude : float) -> void:
	pass

func BodyEnteredRadar(Body : Area2D) -> void:
	pass

func BodyLeftRadar(Body : Area2D) -> void:
	pass
