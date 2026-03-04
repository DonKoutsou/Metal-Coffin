extends Area2D

class_name Sonar
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var SonarStat : ShipStat

var SonarTargets : Array[Node2D]

signal AerosonarRangeChanged

func UpdateSonarRange():
	(collision_shape_2d.shape as CircleShape2D).radius = SonarStat.GetFinalValue()
	AerosonarRangeChanged.emit()

func _ready() -> void:
	area_entered.connect(BodyEnteredSonar)
	area_exited.connect(BodyLeftSonar)

func GetSonarTargets() -> Array[Node2D]:
	return SonarTargets.duplicate()

func BodyEnteredSonar(Body : Area2D) -> void:
	var Parent = Body.get_parent()
	if (Parent is MapShip or Parent is Missile):
		#ShipEnteredSonar.emit(Body.get_parent())
		SonarTargets.append(Parent)

func BodyLeftSonar(Body : Area2D) -> void:
	var Parent = Body.get_parent()
	if (Parent is MapShip or Parent is Missile):
		SonarTargets.erase(Parent)
