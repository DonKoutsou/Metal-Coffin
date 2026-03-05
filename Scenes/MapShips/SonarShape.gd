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

func GetSonarTargetInfo() -> Array[SonarTargetInfo]:
	var TargetInfo : Array[SonarTargetInfo]
	for g in SonarTargets:
		if g is MapShip:
			if (isPartOfFleet(get_parent(), g)):
				continue
			if (g.Command != null):
				continue
		var Info := SonarTargetInfo.new()
		Info.Position = g.global_position
		Info.Altitude = g.Altitude
		if g is MapShip:
			Info.Signature = g.GetSquaddB()
		elif g is Missile:
			Info.Signature = g.GetdB() 
		TargetInfo.append(Info)
	return TargetInfo

func isPartOfFleet(controller : PlayerDrivenShip,target: Node2D) -> bool:
	return target == controller or target in controller.GetDroneDock().GetDockedShips()

func BodyEnteredSonar(Body : Area2D) -> void:
	var Parent = Body.get_parent()
	if (Parent is MapShip or Parent is Missile):
		#ShipEnteredSonar.emit(Body.get_parent())
		SonarTargets.append(Parent)

func BodyLeftSonar(Body : Area2D) -> void:
	var Parent = Body.get_parent()
	if (Parent is MapShip or Parent is Missile):
		SonarTargets.erase(Parent)
