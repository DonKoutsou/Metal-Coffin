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
	var Parent = Body.get_parent()
	if (Parent is HostileShip):
		InsideRadar.append(Parent)
		#Parent.OnShipSeen(self)
		if (Parent.Convoy and !ActionTracker.IsActionCompleted(ActionTracker.Action.CONVOY)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.CONVOY)
			ActionTracker.QueueTutorial(ActionTracker.Action.CONVOY)
		
	else: if (Parent is Missile):
		if (Parent.FiredBy is HostileShip):
			InsideRadar.append(Parent)
			#Parent.OnShipSeen(self)
	else : if (Parent is MapSpot):
		if (Parent.EnemyCity):
			if (!ActionTracker.IsActionCompleted(ActionTracker.Action.ENEMY_TOWN_APROACH)):
				ActionTracker.OnActionCompleted(ActionTracker.Action.ENEMY_TOWN_APROACH)
				ActionTracker.QueueTutorial(ActionTracker.Action.ENEMY_TOWN_APROACH)
		else:
			if (!ActionTracker.IsActionCompleted(ActionTracker.Action.TOWN_APROACH)):
				ActionTracker.OnActionCompleted(ActionTracker.Action.TOWN_APROACH)
				ActionTracker.QueueTutorial(ActionTracker.Action.TOWN_APROACH)
				
		if (!Parent.Seen):
			Parent.OnSpotSeen()

func BodyLeftRadar(Body : Area2D) -> void:
	var Parent = Body.get_parent()
	if (Parent is HostileShip):
		InsideRadar.erase(Parent)
		Parent.OnShipUnseen(self)
		#Parent.OnShipUnseen(self)
	else: if (Parent is Missile):
		if (Parent.FiredBy is HostileShip):
			InsideRadar.erase(Parent)
			Parent.OnShipUnseen(get_parent())
			#Parent.OnShipUnseen(self)
