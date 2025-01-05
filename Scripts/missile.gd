extends Node2D

class_name Missile
#Missile class. Used in Map when spawning an enemy, has a radar infront, 
#once an enemy enters it the missile will hone at them and kill once struc
var MissileName : String
var Distance : int = 1500
var Speed : float = 1
var Damage : float = 20
@export var MissileLaunchSound : AudioStream
@export var MissileKillSound : AudioStream
var FoundShips : Array[Node2D] = []
var Paused = false
var SimulationSpeed : int = 1

func SetData(Dat : MissileItem) -> void:
	Speed = Dat.Speed
	MissileName = Dat.MissileName
	Damage = Dat.Damage
	Distance = Dat.Distance
	
func TogglePause(t : bool):
	Paused = t
func ChangeSimulationSpeed(i : int):
	SimulationSpeed = i

func GetSpeed() -> float:
	return Speed

func _ready() -> void:
	MapPointerManager.GetInstance().AddShip(self, false)
	Paused = SimulationManager.IsPaused()
	var s = DeletableSound.new()
	s.stream = MissileLaunchSound
	s.volume_db = -5
	s.bus = "MapSounds"
	s.autoplay = true
	s.max_distance = 20000
	get_parent().add_child(s)
	$AccelPosition.position.x = Speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if (Paused):
		return
	if (FoundShips.size() > 0):
		HoneAtEnemy()
	for g in SimulationSpeed:
		global_position = $AccelPosition.global_position
		Distance -= $AccelPosition.position.x
	#if (Distance <= 0):
		#MapPointerManager.GetInstance().RemoveShip(self)
		#if (FoundShip):
			#MapPointerManager.GetInstance().RemoveShip(FoundShip)
		#queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if (!FoundShips.has(area.get_parent())):
		FoundShips.append(area.get_parent())
		if (area.get_parent() is HostileShip):
			area.get_parent().OnShipSeen(self)

func _on_missile_body_area_entered(area: Area2D) -> void:
	if (FoundShips.size() == 0):
		return
	#MapPointerManager.GetInstance().RemoveShip(area)
	#area.queue_free()
	if (area.get_parent() is Missile):
		area.get_parent().queue_free()
		queue_free()
		return
	area.get_parent().Damage(Damage)
	if (area.get_parent().IsDead()):
		var s = DeletableSoundGlobal.new()
		s.stream = MissileKillSound
		s.volume_db = -10
		s.bus = "UI"
		s.autoplay = true
		#s.max_distance = 20000
		get_parent().add_child(s)
	
	queue_free()

func _exit_tree() -> void:
	MapPointerManager.GetInstance().RemoveShip(self)

func HoneAtEnemy():
	var Ship
	for g in FoundShips:
		if (g != null):
			Ship = g
			break
	# Get the current position and velocity of the ship
	var ship_position = Ship.global_position
	var ship_velocity = Ship.GetShipSpeedVec()

	# Predict where the ship will be in a future time `t`
	var time_to_interception = (global_position.distance_to(ship_position) / $AccelPosition.position.x) / 60

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception

	look_at(predicted_position)

func GetShipSpeedVec() -> Vector2:
	return $AccelPosition.global_position - global_position

func GetSaveData() -> MissileSaveData:
	var dat = MissileSaveData.new()
	dat.Pos = global_position
	dat.Rot = global_rotation
	dat.MisName = MissileName
	dat.MisSpeed = Speed
	dat.Distance = Distance
	dat.Scene = scene_file_path
	return dat
