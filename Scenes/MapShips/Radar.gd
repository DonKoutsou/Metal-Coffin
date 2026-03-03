extends Area2D

class_name Radar

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var VisStat : ShipStat

var Working : bool = true
var Detectable = true

var CurrentVisualRange : float = 110

var InsideRadar : Array[Node2D]

signal VisuaLRangeChanged

func _ready() -> void:
	area_entered.connect(BodyEnteredRadar)
	area_exited.connect(BodyLeftRadar)

func ToggleRadar(t : bool):
	Detectable = t
	Working = t
	if (t):
		#RadarShape.get_child(0).disabled = false
		UpdateVizRange(VisStat.GetFinalValue())
	else:
		#RadarShape.get_child(0).disabled = false
		UpdateVizRange(0)

func UpdateVizRange(rang : float):
	CurrentVisualRange = max(rang, 110)
	#print("{0}'s radar range has been set to {1}".format([GetShipName(), rang]))
	(collision_shape_2d.shape as CircleShape2D).radius = max(rang, 110)
	VisuaLRangeChanged.emit()

func RephreshVisRange(VisibilityValue : float) -> void:
	var VisualRange = VisibilityValue
	if (Working):
		VisualRange = VisStat.GetFinalValue()
	(collision_shape_2d.shape as CircleShape2D).radius = max(VisualRange, VisibilityValue)
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
		#if (Parent.Convoy and !ActionTracker.IsActionCompleted(ActionTracker.Action.CONVOY)):
			#ActionTracker.OnActionCompleted(ActionTracker.Action.CONVOY)
			#ActionTracker.GetInstance().QueueTutorial("Enemy Convoys", "You have located an enemy convoy. These convoys pose no risk since the have no weapons on them an are usually not escorted by any combatants. Capturing any of those convoys is dangerous since they can raise the alarm on you and signify your position to the enemy. Managing to capture on will provide a good reward once any of those is brought back to any of the cities, where the ship can be broken down and sold. Bring any captured convoy to any city and land it to receive your reward.", [], true)
		
	else: if (Parent is Missile):
		if (Parent.FiredBy is HostileShip):
			InsideRadar.append(Parent)
			#Parent.OnShipSeen(self)
	else : if (Parent is MapSpot):
		if (Parent.EnemyCity):
			if (!ActionTracker.IsActionCompleted(ActionTracker.Action.ENEMY_TOWN_APROACH)):
				ActionTracker.OnActionCompleted(ActionTracker.Action.ENEMY_TOWN_APROACH)
				var TutText = "You are reaching an enemy [color=#ffc315]city[/color]. Enemy cities are usual refuel spots for [color=#ffc315]patrols[/color], and always have a guarding [color=#ffc315]garrisson[/color] in their center. Entering the perimiter of a city will comence combat with all enemies that happen to be in it."
				ActionTracker.GetInstance().QueueTutorial("Enemy Cities", TutText, [])
		else:
			if (!ActionTracker.IsActionCompleted(ActionTracker.Action.TOWN_APROACH)):
				ActionTracker.OnActionCompleted(ActionTracker.Action.TOWN_APROACH)
				var TutText = "You are reaching one of the many friendly [color=#ffc315]villages[/color] in the glacier. No enemies exist in those [color=#ffc315]villages[/color] and none of the locals wil raise the [color=#ffc315]alarm[/color] on you. You are free to use those [color=#ffc315]villages[/color] to restock/repair or even as a hideout. The location of those [color=#ffc315]villages[/color] is unknown and will need to be discovered."
				ActionTracker.GetInstance().QueueTutorial("Friendly Villages", TutText, [])
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
			Parent.OnShipUnseen(self)
			#Parent.OnShipUnseen(self)
