extends Node2D

class_name Drone

@export var DroneNotifScene : PackedScene
@export var Cpt : Captain


var CommingBack = false
var Docked = true

var Fuel = 0

var StoredItem : Array[Item] = []

var Paused = false

func  _ready() -> void:
	#Set ships speed
	GetShipAcelerationNode().position.x = Cpt.GetStatValue("SPEED")
	#Make sure drone wont be walking unless sent
	set_physics_process(false)
	#Turn off areas to not get events while drone is docked
	GetShipBodyArea().monitoring = false
	GetShipTrajecoryLine().visible = false
	#Set range of radar and alanyzer
	UpdateVizRange(Cpt.GetStatValue("RADAR_RANGE"))
	UpdateAnalyzerRange(Cpt.GetStatValue("ANALYZE_RANGE"))
	MapPointerManager.GetInstance().AddShip(self, true)

func free() -> void:
	MapPointerManager.GetInstance().RemoveShip(self)

func TogglePause(t : bool):
	Paused = t
	$AudioStreamPlayer2D.stream_paused = t
func GetSpeed():
	return $Aceleration.position.x
func UpdateVizRange(rang : float):
	if (rang == 0):
		GetShipRadarArea().queue_free()
		return
	var RadarRangeIndicator = GetShipRadarArea().get_node("Radar_Range")
	var RadarRangeCollisionShape = GetShipRadarArea().get_node("CollisionShape2D")
	#var RadarRangeIndicatorDescriptor = $Radar/Radar_Range/Label2
	var RadarMat = RadarRangeIndicator.material as ShaderMaterial
	RadarMat.set_shader_parameter("scale_factor", rang/10000)
	#scalling collision
	(RadarRangeCollisionShape.shape as CircleShape2D).radius = rang
	$PointLight2D.texture_scale = rang / 600
	GetShipRadarArea().get_node("Radar_Range").visible = false
	GetShipRadarArea().monitorable = false
	
func UpdateAnalyzerRange(rang : float):
	if (rang == 0):
		GetShipAnalayzerArea().queue_free()
		return
	var AnalyzerRangeIndicator = GetShipAnalayzerArea().get_node("Analyzer_Range")
	var AnalyzerRangeCollisionShape =GetShipAnalayzerArea().get_node("CollisionShape2D")
	#var AnalyzerRangeIndicatorDescriptor = $Analyzer/Analyzer_Range/Label2
	var AnalyzerMat = AnalyzerRangeIndicator.material as ShaderMaterial
	#CHANGING SIZE OF RADAR
	AnalyzerMat.set_shader_parameter("scale_factor", rang/10000)
	#SCALLING COLLISION
	(AnalyzerRangeCollisionShape.shape as CircleShape2D).radius = rang
	AnalyzerRangeIndicator.visible = false
	
func EnableDrone():
	Docked = false
	set_physics_process(true)
	GetShipBodyArea().monitoring = true
	GetShipTrajecoryLine().visible = true
	$AudioStreamPlayer2D.play()
	var rad = get_node_or_null("Radar/Radar_Range")
	if (rad != null):
		rad.visible = true
		GetShipRadarArea().monitorable = true
	var an = get_node_or_null("Analyzer/Analyzer_Range")
	if (an != null):
		an.visible = true
		GetShipAnalayzerArea().monitorable = true

func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = Cpt.GetStat("HULL")
	stats.FirePower = Cpt.GetStat("FIREPOWER")
	stats.Icon = Cpt.ShipIcon
	stats.Name = Cpt.CaptainName
	return stats

func _physics_process(_delta: float) -> void:
	if (Paused):
		return
	if (CommingBack):
		var interceptionpoint = calculateinterceptionpoint()
		updatedronecourse(interceptionpoint)
	else:
		Fuel -= GetShipAcelerationNode().position.x
		global_position = GetShipAcelerationNode().global_position
		GetShipTrajecoryLine().set_point_position(1, Vector2(Fuel, 0))
		if (Fuel <= 0):
			rotation = 0.0
			CommingBack = true
			Notify("Drone returning to base")
			Docked = false
			#$Line2D.visible = true

func calculateinterceptionpoint() -> Vector2:
	var plship = PlayerShip.GetInstance()
	# Get the current position and velocity of the ship
	var ship_position = plship.position
	var ship_velocity = plship.GetShipSpeedVec()

	# Predict where the ship will be in a future time `t`
	var time_to_interception = (position.distance_to(ship_position)) / GetShipAcelerationNode().position.x

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception

	return predicted_position
	
func updatedronecourse(interception_point: Vector2):
	# Calculate the direction vector from the drone to the interception point
	var direction = (interception_point - position).normalized()
	GetShipIconPivot().look_at(to_global(interception_point - position))
	# Move the drone towards the interception point
	position += direction * GetShipAcelerationNode().position.x
	GetShipTrajecoryLine().set_point_position(1, interception_point - position)

func Notify(NotificationText : String)-> void:
	var notif = DroneNotifScene.instantiate() as DroneNotif
	notif.SetNotifText(NotificationText)
	notif.EntityToFollow = self
	add_child(notif)

func DissableMonitoring():
	GetShipBodyArea().monitoring = false

func _on_return_sound_trigger_area_entered(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip and CommingBack):
		var plship = area.get_parent() as PlayerShip
		plship.GetDroneDock().PlayReturnSound()

func _on_ship_body_area_entered(area: Area2D) -> void:
	if (Docked):
		return
	if (area.get_parent() is MapSpot and !CommingBack):
		var spot = area.get_parent() as MapSpot
		if (spot.CurrentlyVisiting):
			return
		if (spot.SpotType.FullName != "Black Whole"):
			for g in Cpt.GetStatValue("INVENTORY_CAPACITY"):
				StoredItem.append_array(spot.SpotType.GetSpotDrop())
		rotation = 0.0
		CommingBack = true
		Docked = false
		Notify("Drone returning to base")
		#$Line2D.visible = true
		if (!spot.Seen):
			spot.OnSpotSeenByDrone()
		spot.OnSpotVisitedByDrone()
	else : if (area.get_parent() is PlayerShip and CommingBack):
		var plship = area.get_parent() as PlayerShip
		plship.GetDroneDock().DockDrone(self, true)
		CommingBack = false
		Docked = true
		GetShipTrajecoryLine().visible = false
		GetShipIconPivot().rotation = 0.0
		Inventory.GetInstance().AddItems(StoredItem)
		StoredItem.clear()
		$AudioStreamPlayer2D.stop()
		set_physics_process(false)
		var rad = get_node_or_null("Radar/Radar_Range")
		if (rad != null):
			GetShipRadarArea().monitorable = false
			rad.visible = false
		var an = get_node_or_null("Analyzer/Analyzer_Range")
		if (an != null):
			GetShipAnalayzerArea().monitorable = false
			an.visible = false

func GetShipBodyArea() -> Area2D:
	return $ShipBody
func GetShipRadarArea() -> Area2D:
	return $Radar
func GetShipAnalayzerArea() -> Area2D:
	return $Analyzer
func GetShipAcelerationNode() -> Node2D:
	return $Aceleration
func GetShipIconPivot() -> Node2D:
	return $ShipIconPivot
func GetShipTrajecoryLine() -> Line2D:
	return $ShipTrajectory
