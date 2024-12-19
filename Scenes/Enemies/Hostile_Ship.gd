extends Area2D

class_name HostileShip

@export var Speed = 0.5
@export var RadarRange = 300
@export var Direction = -1

@export var ShipIcon : Texture
@export var CaptainIcon : Texture
@export var ShipName : String
@export var Hull : float = 30
@export var Patrol : bool = true
@export var ShipCallsign : String = "P"
#var Pursuing = false
var PursuingShips : Array[Node2D]
var LastKnownPosition : Vector2

var Paused = false
var SimulationSpeed : int = 1

var DestinationCity : MapSpot

var VisibleBt : Dictionary
#var VisibleBy : Array[Node2D] = []

signal OnShipMet(FriendlyShips : Array[Node2D] , EnemyShips : Array[Node2D])
func SeenShips() -> bool:
	for g in VisibleBt:
		if (g == null):
			continue
		if (g is PlayerShip or g is Drone):
			return true
	return false
func  _ready() -> void:
	#visible = false
	$Node2D.position.x = Speed
	#set_physics_process(false)
	UpdateVizRange(RadarRange)
	var cities = get_tree().get_nodes_in_group("EnemyDestinations")
	if (!Patrol):
		return
	var nextcity = cities.find(DestinationCity) + Direction
	if (nextcity < 0 or nextcity > cities.size() - 1):
		Direction *= -1
		nextcity = cities.find(DestinationCity) + Direction
	DestinationCity = cities[nextcity]
	call_deferred("AimForCity")
func AimForCity():
	look_at(DestinationCity.global_position)
	
func GetCity(CityName : String) -> MapSpot:
	var cities = get_tree().get_nodes_in_group("EnemyDestinations")
	var CorrectCity : MapSpot
	for g in cities:
		var cit = g as MapSpot
		if (cit.GetSpotName() == CityName):
			CorrectCity = cit
			break
	return CorrectCity
	
func TogglePause(t : bool):
	Paused = t
	$AudioStreamPlayer2D.stream_paused = t
	$Radar/Radar_Range.material.set_shader_parameter("Paused", t)
func ChangeSimulationSpeed(i : int):
	SimulationSpeed = i
	
func Damage(amm : float) -> void:
	Hull -= amm
	if (Hull <= 0):
		MapPointerManager.GetInstance().RemoveShip(self)
		queue_free()
func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = Hull
	stats.FirePower = 1
	stats.ShipIcon = ShipIcon
	stats.CaptainIcon = CaptainIcon
	stats.Name = "Enemy"
	return stats

func UpdateVizRange(rang : float):
	if (rang == 0):
		$Radar.queue_free()
		return
	var RadarRangeIndicator = $Radar/Radar_Range
	var RadarRangeCollisionShape = $Radar/CollisionShape2D
	#var RadarRangeIndicatorDescriptor = $Radar/Radar_Range/Label2
	var RadarMat = RadarRangeIndicator.material as ShaderMaterial
	RadarMat.set_shader_parameter("scale_factor", rang/10000)
	#scalling collision
	(RadarRangeCollisionShape.shape as CircleShape2D).radius = rang
	#$PointLight2D.texture_scale = rang / 600
	#$Radar2/Radar_Range.visible = false

func GetSpeed():
	return $Node2D.position.x
func GetShipSpeedVec() -> Vector2:
	return $Node2D.global_position - global_position
func _physics_process(_delta: float) -> void:
	if (Paused):
		return
	if (PursuingShips.size() > 0 or LastKnownPosition != Vector2.ZERO):
		updatedronecourse()
	else : if (Patrol):
		for g in  SimulationSpeed:
			global_position = $Node2D.global_position
	for g in VisibleBt:
		if (g == null):
			continue
		if (g is Missile):
			continue
		VisibleBt[g] = min(VisibleBt[g] + 0.05, 10)
		if (VisibleBt[g] == 10 and !PursuingShips.has(g)):
			LastKnownPosition = g.global_position

func updatedronecourse():
	# Get the current position and velocity of the ship
	var ship_position
	var ship_velocity
	if (PursuingShips.size() > 0):
		ship_position = PursuingShips[0].position
		ship_velocity = PursuingShips[0].GetShipSpeedVec()
	else:
		ship_position = LastKnownPosition
		ship_velocity = Vector2.ZERO
	# Predict where the ship will be in a future time `t`
	var time_to_interception = (position.distance_to(ship_position)) / GetSpeed()

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception
	look_at(predicted_position)
	$Node2D.position.x = Speed
	global_position = $Node2D.global_position
func _on_radar_2_area_entered(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		PursuingShips.append(area.get_parent())
		
func _on_radar_2_area_exited(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		PursuingShips.erase(area.get_parent())
		LastKnownPosition = area.get_parent().global_position
		
#whan this ship gets seen by player or friendly drone
func OnShipSeen(SeenBy : Node2D):
	$Radar/Radar_Range.visible = true
	#visible = true
	if (VisibleBt.has(SeenBy)):
		return
	VisibleBt[SeenBy] = 0
	if (VisibleBt.keys().size() > 1):
		return
	MapPointerManager.GetInstance().AddShip(self, false)
	SimulationManager.GetInstance().TogglePause(true)

	
func OnShipUnseen(UnSeenBy : Node2D):
	VisibleBt.erase(UnSeenBy)
	$Radar/Radar_Range.visible = VisibleBt.size() > 0


func _on_area_entered(area: Area2D) -> void:
	if (area.get_parent() == DestinationCity and Patrol):
		var cities = get_tree().get_nodes_in_group("EnemyDestinations")
		
		var nextcity = cities.find(DestinationCity) + Direction
		if (nextcity < 0 or nextcity > cities.size() - 1):
			Direction *= -1
			nextcity = cities.find(DestinationCity) + Direction
		DestinationCity = cities[nextcity]
		look_at(DestinationCity.global_position)
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		var bit = area.get_collision_layer_value(3) or area.get_collision_layer_value(4)
		if (bit):
			if (area.get_parent() is PlayerShip):
				var player = area.get_parent() as PlayerShip
				var ships : Array[Node2D] = []
				ships.append(player)
				ships.append_array(player.GetDroneDock().DockedDrones)
				var hostships : Array[Node2D] = []
				hostships.append(self)
				OnShipMet.emit(ships, hostships)
			else:
				var plships : Array[Node2D] = []
				var drn = area.get_parent() as Drone
				if (drn.Docked):
					var player = PlayerShip.GetInstance()
					plships.append(player)
					plships.append_array(player.GetDroneDock().DockedDrones)
				else:
					plships.append(drn)
				
				var hostships : Array[Node2D] = []
				hostships.append(self)
				OnShipMet.emit(plships, hostships)
		else:
			OnShipSeen(area.get_parent())

func _on_area_exited(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		OnShipUnseen(area.get_parent())

func GetSaveData() -> SD_HostileShip:
	var dat = SD_HostileShip.new()
	if (DestinationCity != null):
		dat.DestinationCityName = DestinationCity.GetSpotName()
	dat.Direction = Direction
	dat.LastKnownPosition = LastKnownPosition
	dat.Position = global_position
	dat.RadarRange = RadarRange
	dat.Speed = Speed
	dat.Scene = scene_file_path
	dat.ShipName = ShipName
	return dat
func LoadSaveData(Dat : SD_HostileShip) -> void:
	DestinationCity = GetCity(Dat.DestinationCityName)
	Direction = Dat.Direction
	LastKnownPosition = Dat.LastKnownPosition
	global_position = Dat.Position
	RadarRange = Dat.RadarRange
	Speed = Dat.Speed
	ShipName = Dat.ShipName
