extends Node2D

class_name Missile
#Missile class. Used in Map when spawning an enemy, has a radar infront, 
#once an enemy enters it the missile will hone at them and kill once struc
var MissileName : String
var Distance : int = 1500
@export var Speed : float = 1
var Damage : float = 20
@export var MissileLaunchSound : AudioStream

var FoundShips : Array[Node2D] = []
var Paused = false
var Friendly = false

var DistanceTraveled : float

var FiredBy : MapShip
var VisibleBy : Array[MapShip]

signal OnShipDestroyed(Mis : Missile)

var activationdistance : float = 0

func SetData(Dat : MissileItem) -> void:
	Speed = Dat.Speed
	MissileName = Dat.ItemName
	Damage = Dat.Damage
	Distance = Dat.Distance
	
func TogglePause(t : bool):
	Paused = t
#func ChangeSimulationSpeed(i : float):
	#SimulationSpeed = i

func GetSpeed() -> float:
	return Speed

func GetShipName() -> String:
	return MissileName

func _ready() -> void:
	Paused = SimulationManager.IsPaused()
	if (FiredBy is not HostileShip):
		var s = DeletableSound.new()
		s.stream = MissileLaunchSound
		s.volume_db = -15
		s.bus = "MapSounds"
		s.autoplay = true
		s.max_distance = 20000
		get_parent().add_child(s)
	$AccelPosition.position.x = Speed / 360
	

func _physics_process(delta: float) -> void:
	if (Paused):
		return

	var offset = GetShipSpeedVec()
	
	DistanceTraveled += offset.length() * SimulationManager.SimSpeed()

	if (DistanceTraveled > Distance):
		Kill()
	
	var WindVel = Vector2.RIGHT.rotated(rotation).dot(WeatherManage.WindDirection) * 0.1
	var affectedoffset = (offset * (1 + WindVel)) * SimulationManager.SimSpeed()
	global_position += affectedoffset
	
	
	$TrailLine.Update(delta)
	
	activationdistance += offset.length() * SimulationManager.SimSpeed()
	
	if (activationdistance < 50):
		return
	
	$Radar_Range.visible = Friendly
	
	if (FoundShips.size() > 0):
		HoneAtEnemy()
	
func CheckForBodiesOnTrajectory(Dir : Vector2) -> Node2D:
	var Body : Node2D
	
	var shape_cast = ShapeCast2D.new()
	add_child(shape_cast)
	shape_cast.exclude_parent = true
	shape_cast.collide_with_areas = true
	shape_cast.collision_mask = $MissileBody.collision_mask
	shape_cast.shape = CapsuleShape2D.new()
	# Set ShapeCast destination
	shape_cast.target_position = global_position + Dir

	# Perform the ShapeCast
	shape_cast.force_shapecast_update()
	if shape_cast.get_collision_count() > 0:
		Body = shape_cast.get_collider(0)
	shape_cast.queue_free()
	return Body

func StopSeeing() -> void:
	VisibleBy.clear()

func OnShipDest(Sh : MapShip) -> void:
	FoundShips.erase(Sh)
func OnMissDest(Mis : Missile) -> void:
	FoundShips.erase(Mis)

func _on_area_2d_area_entered(area: Area2D) -> void:
	var bod = area.get_parent()
	if (bod == FiredBy):
		return
	if (bod is HostileShip):
		if (bod.Destroyed):
			return
	if (!FoundShips.has(area.get_parent())):
		FoundShips.append(area.get_parent())
		if (area.get_parent() is MapShip):
			area.get_parent().connect("OnShipDestroyed" ,OnShipDest)
		else : if (area.get_parent() is Missile):
			area.get_parent().connect("OnShipDestroyed" ,OnMissDest)
		if (FiredBy is PlayerDrivenShip):
			if (area.get_parent() is HostileShip):
				area.get_parent().OnShipSeen(self)
				
func _on_area_2d_area_exited(area: Area2D) -> void:
	if (FoundShips.has(area.get_parent())):
		FoundShips.erase(area.get_parent())
		if (FiredBy is PlayerDrivenShip):
			if (area.get_parent() is HostileShip):
				area.get_parent().OnShipUnseen(self)
				
func _on_missile_body_area_entered(area: Area2D) -> void:
	if (area.get_parent() == FiredBy):
		return
	
	if (activationdistance < 50):
		return
	
	var Bod = area.get_parent()
	
	if (FoundShips.size() == 0):
		return
	if (Bod is HostileShip):
		if (Bod.Destroyed):
			return
	if (area.get_parent() is Missile):
		area.get_parent().Kill()
		Kill()
		return
	area.get_parent().Damage(Damage)
	if (area.get_parent().IsDead()):
		RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.TARGET_DEST)
	call_deferred("Kill")
		
func _on_missile_body_area_exited(area: Area2D) -> void:
	var IsRadar = area.get_collision_layer_value(2)
	if (IsRadar):
		if (area.get_parent() is PlayerDrivenShip):
			OnShipUnseen(area.get_parent())
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
	
	var WindVel = Vector2.RIGHT.rotated(rotation).dot(WeatherManage.WindDirection) * 0.1
	# Predict where the ship will be in a future time `t`
	var time_to_interception = (global_position.distance_to(ship_position) / ($AccelPosition.position.x * (1 + WindVel))) / 60

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception

	look_at(predicted_position)

func GetAffectedSpeed() -> float:
	var WindVel = Vector2.RIGHT.rotated(rotation).dot(WeatherManage.WindDirection) * 0.1
	return ($AccelPosition.position.x * 360) * (1 + WindVel)

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
	dat.DistanceTraveled = DistanceTraveled
	
	return dat
	
func OnShipSeen(SeenBy : MapShip):
	if (VisibleBy.has(SeenBy)):
		return
	VisibleBy.append(SeenBy)
	if (VisibleBy.size() > 1):
		return
	MapPointerManager.GetInstance().AddShip(self, false)
	SimulationManager.GetInstance().SpeedToggle(false)
	Map.GetInstance().GetCamera().FrameCamToPos(global_position, 1, false)
func OnShipUnseen(UnSeenBy : MapShip):
	VisibleBy.erase(UnSeenBy)

func Kill() -> void:
	OnShipDestroyed.emit(self)
	StopSeeing()
	queue_free()
	get_parent().remove_child(self)
