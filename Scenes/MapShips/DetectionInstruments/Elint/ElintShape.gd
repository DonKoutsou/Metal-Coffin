extends Area2D

class_name Elint

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var ElintStat : ShipStat

signal ElintTriggered(T : bool, Lvl : int, Dir : String)
signal ElintRangeChanged


var ElintContacts : Dictionary

func _ready() -> void:
	area_entered.connect(BodyEnteredElint)
	area_exited.connect(BodyLeftElint)

func ToggleElint(t : bool):
	if (!t):
		ElintContacts.clear()
	collision_shape_2d.disabled = t

func UpdateELINTTRange():
	(collision_shape_2d.shape as CircleShape2D).radius = ElintStat.GetFinalValue()
	ElintRangeChanged.emit()

var d = 0.4

func UpdateElint(delta: float) -> void:
	d -= delta
	if (d > 0):
		return
	d = 0.4
	var BiggestLevel = -1
	var Dir : float
	for g in ElintContacts.size():
		var ship = ElintContacts.keys()[g] as MapShip
		var lvl = ElintContacts.values()[g]
		var Newlvl = GetElintLevel(global_position.distance_squared_to(ship.global_position), ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE))
		if (Newlvl > BiggestLevel):
			BiggestLevel = Newlvl
			Dir = global_position.angle_to_point(ship.global_position)
		if (Newlvl != lvl):
			ElintContacts[ship] = Newlvl
	if (BiggestLevel > -1):
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.ELINT_CONTACT)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.ELINT_CONTACT)
			ActionTracker.GetInstance().QueueTutorial("Electronic Intelligence", "The Elint sensors of one of your ships has been triggered. Elint detects enemy radar signals and provides a rough estimation on the distance and the direction of the signal. If the sensor is triggered it means you are about to enter into a radar's signal range and be detected.", [])
		ElintTriggered.emit(true, BiggestLevel, Helper.AngleToDirection(Dir))
	else:
		ElintTriggered.emit(false, -1, "")

func GetClosestElint() -> Vector2:
	
	var closest : Vector2 = Vector2.ZERO
	var closestdist : float = 999999999999999999
	
	for g in ElintContacts.size():
		var ship = ElintContacts.keys()[g]
		var dist = global_position.distance_squared_to(ship.global_position)
		if (closestdist > dist):
			closest = ship.global_position
			closestdist = dist
	
	return closest

func GetClosestElintLevel() -> int:
	if (ElintContacts.size() == 0):
		return -1
	var closest : MapShip
	var closestdist : float = 9999999999999999
	for g in ElintContacts.size():
		var ship = ElintContacts.keys()[g]
		var dist = global_position.distance_squared_to(ship.global_position)
		if (closestdist > dist):
			closest = ship
			closestdist = dist
	
	var Newlvl = GetElintLevel(global_position.distance_squared_to(closest.global_position), closest.Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE))
	
	return Newlvl
	
func GetElintLevel(DistSq : float, RadarL : float) -> int:
	var Lvl = -1
	var RadarLSq = RadarL * RadarL
	var ElintDist = ElintStat.GetFinalValue()
	if (ElintDist == 0 or RadarL <= 90):
		return Lvl
	if (DistSq < RadarLSq):
		Lvl = 3
	else : if (DistSq < RadarLSq * 2):
		Lvl = 2
	else : if (DistSq < RadarLSq * 10):
		Lvl = 1
	return Lvl

func BodyEnteredElint(Body: Area2D) -> void:
	if (Body.get_parent() == self):
		return
	ElintContacts[Body.get_parent()] = 0
	#Elint.emit(true, 1)
	
func BodyLeftElint(Body: Area2D) -> void:
	if (Body.get_parent() == self):
		return
	ElintContacts.erase(Body.get_parent())
	#Elint.emit(false, 0)
