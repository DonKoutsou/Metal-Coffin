extends Area2D

class_name HostileShip

@export var Speed = 0.5
@export var RadarRange = 300
@export var Direction = -1
@export var EnemyLocatedNotifScene : PackedScene
@export var EnemyLocatedSound : AudioStream
@export var ShipIcon : Texture
@export var CaptainIcon : Texture
#var Pursuing = false
var PursuingShip : Node2D

var Paused = false

var DestinationCity : MapSpot

var VisibleBy : Array[Node2D] = []

signal OnShipMet(FriendlyShips : Array[Node2D] , EnemyShips : Array[Node2D])

func  _ready() -> void:
	#visible = false

	$Node2D.position.x = Speed
	#set_physics_process(false)
	UpdateVizRange(RadarRange)
	var cities = get_tree().get_nodes_in_group("EnemyDestinations")
	
	var nextcity = cities.find(DestinationCity) + Direction
	if (nextcity < 0 or nextcity > cities.size() - 1):
		Direction *= -1
		nextcity = cities.find(DestinationCity) + Direction
	DestinationCity = cities[nextcity]
	call_deferred("AimForCiry")
func AimForCiry():
	look_at(DestinationCity.global_position)
func TogglePause(t : bool):
	Paused = t
	$AudioStreamPlayer2D.stream_paused = t

func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = 30
	stats.FirePower = 1
	stats.ShipIcon = ShipIcon
	stats.CaptainIcon = CaptainIcon
	stats.Name = "Enemy"
	return stats

func UpdateVizRange(rang : float):
	if (rang == 0):
		$Radar2.queue_free()
	var RadarRangeIndicator = $Radar2/Radar_Range
	var RadarRangeCollisionShape = $Radar2/CollisionShape2D
	#var RadarRangeIndicatorDescriptor = $Radar/Radar_Range/Label2
	var RadarMat = RadarRangeIndicator.material as ShaderMaterial
	RadarMat.set_shader_parameter("scale_factor", rang/10000)
	#scalling collision
	(RadarRangeCollisionShape.shape as CircleShape2D).radius = rang
	#$PointLight2D.texture_scale = rang / 600
	#$Radar2/Radar_Range.visible = false

func GetSpeed():
	return $Node2D.position.x
	
func _physics_process(_delta: float) -> void:
	if (Paused):
		return
	if (PursuingShip != null):
		var interceptionpoint = calculateinterceptionpoint()
		updatedronecourse(interceptionpoint)
	else:
		global_position = $Node2D.global_position

func calculateinterceptionpoint() -> Vector2:
	#var plship = PlayerShip.GetInstance()
	# Get the current position and velocity of the ship
	var ship_position = PursuingShip.position
	var ship_velocity = PursuingShip.GetShipSpeedVec()

	# Predict where the ship will be in a future time `t`
	var time_to_interception = (position.distance_to(ship_position)) / $Node2D.position.x

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception

	return predicted_position
	
func updatedronecourse(interception_point: Vector2):
	# Calculate the direction vector from the drone to the interception point
	var direction = (interception_point - position).normalized()
	$Node2D2.look_at(to_global(interception_point ))
	# Move the drone towards the interception point
	position += direction * $Node2D.position.x
	#$Line2D.set_point_position(1, interception_point - position)

func _on_radar_2_area_entered(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		PursuingShip = area.get_parent()

func OnShipSeen(SeenBy : Node2D):
	#visible = true
	if (VisibleBy.has(SeenBy)):
		return
	VisibleBy.append(SeenBy)
	if (VisibleBy.size() > 1):
		return
	MapPointerManager.GetInstance().AddShip(self, false)
	var notif = EnemyLocatedNotifScene.instantiate()
	var sound = DeletableSound.new()
	sound.stream = EnemyLocatedSound
	sound.volume_db = -10
	sound.bus = "UI"
	sound.autoplay = true
	add_child(sound)
	add_child(notif)
	
func OnShipUnseen(UnSeenBy : Node2D):
	VisibleBy.erase(UnSeenBy)
	
func _on_area_entered(area: Area2D) -> void:
	if (area.get_parent() == DestinationCity):
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
				for g in player.GetDroneDock().DockedDrones:
					ships.append(g)
				var hostships : Array[Node2D] = []
				hostships.append(self)
				OnShipMet.emit(ships, hostships)
			else:
				var drn = area.get_parent() as Drone
				var plships : Array[Node2D] = []
				plships.append(drn)
				
				var hostships : Array[Node2D] = []
				hostships.append(self)
				OnShipMet.emit(plships, hostships)
		else:
			OnShipSeen(area.get_parent())

func _on_area_exited(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		OnShipUnseen(area.get_parent())
