extends Node2D

class_name Missile
#Missile class. Used in Map when spawning an enemy, has a radar infront, 
#once an enemy enters it the missile will hone at them and kill once struc
var MissileName : String
var Distance : int = 1500
var Speed : float = 1
var Damage : float = 100
@export var MissileLaunchSound : AudioStream
@export var MissileKillSound : AudioStream
var FoundShip : HostileShip
var Paused = false
var SimulationSpeed : int = 1

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
	if (FoundShip != null):
		HoneAtEnemy()
	for g in SimulationSpeed:
		global_position = $AccelPosition.global_position
		Distance -= $AccelPosition.position.x
	if (Distance <= 0):
		MapPointerManager.GetInstance().RemoveShip(self)
		if (FoundShip):
			MapPointerManager.GetInstance().RemoveShip(FoundShip)
		queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if (FoundShip == null):
		FoundShip = area.get_parent()
		FoundShip.OnShipSeen(self)

func _on_missile_body_area_entered(area: Area2D) -> void:
	#MapPointerManager.GetInstance().RemoveShip(area)
	#area.queue_free()
	area.get_parent().Damage(Damage)
	if (area.get_parent().Hull <= 0):
		var s = DeletableSoundGlobal.new()
		s.stream = MissileKillSound
		s.volume_db = -10
		s.bus = "UI"
		s.autoplay = true
		#s.max_distance = 20000
		get_parent().add_child(s)
	MapPointerManager.GetInstance().RemoveShip(self)
	
	queue_free()
	
func HoneAtEnemy():
	# Get the current position and velocity of the ship
	var ship_position = FoundShip.global_position
	var ship_velocity = FoundShip.GetShipSpeedVec()

	# Predict where the ship will be in a future time `t`
	var time_to_interception = (global_position.distance_to(ship_position) / $AccelPosition.position.x) / 60

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception

	look_at(predicted_position)

func GetSaveData() -> MissileSaveData:
	var dat = MissileSaveData.new()
	dat.Pos = global_position
	dat.Rot = global_rotation
	dat.MisName = MissileName
	dat.MisSpeed = Speed
	dat.Distance = Distance
	dat.Scene = scene_file_path
	return dat
