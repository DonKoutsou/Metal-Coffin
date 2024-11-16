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
	$Node2D.position.x = Cpt.GetStatValue("SPEED")
	set_physics_process(false)
	$Radar.monitoring = false
	$Line2D.visible = false
	UpdateVizRange(Cpt.GetStatValue("RADAR_RANGE"))
	UpdateAnalyzerRange(Cpt.GetStatValue("ANALYZE_RANGE"))
func TogglePause(t : bool):
	Paused = t
	$AudioStreamPlayer2D.stream_paused = t

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
	$PointLight2D.texture_scale = rang / 600
	$Radar2/Radar_Range.visible = false
	
func UpdateAnalyzerRange(rang : float):
	if (rang == 0):
		$Analyzer.queue_free()
	var AnalyzerRangeIndicator = $Analyzer/Analyzer_Range
	var AnalyzerRangeCollisionShape = $Analyzer/CollisionShape2D
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
	$Radar.monitoring = true
	$Line2D.visible = true
	$AudioStreamPlayer2D.play()
	var rad = get_node_or_null("Radar2/Radar_Range")
	if (rad != null):
		rad.visible = true
	var an = get_node_or_null("Analyzer/Analyzer_Range")
	if (an != null):
		an.visible = true
	
func _physics_process(_delta: float) -> void:
	if (Paused):
		return
	if (CommingBack):
		var interceptionpoint = calculateinterceptionpoint()
		updatedronecourse(interceptionpoint)
	else:
		Fuel -= $Node2D.position.x
		global_position = $Node2D.global_position
		$Line2D.set_point_position(1, Vector2(Fuel, 0))
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
	var time_to_interception = (position.distance_to(ship_position)) / $Node2D.position.x

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception

	return predicted_position
	
func updatedronecourse(interception_point: Vector2):
	
	# Calculate the direction vector from the drone to the interception point
	var direction = (interception_point - position).normalized()
	$Node2D2.look_at(to_global(interception_point - position))
	# Move the drone towards the interception point
	position += direction * $Node2D.position.x
	$Line2D.set_point_position(1, interception_point - position)

func Notify(NotificationText : String)-> void:
	var notif = DroneNotifScene.instantiate() as DroneNotif
	notif.SetNotifText(NotificationText)
	notif.EntityToFollow = self
	add_child(notif)

func _on_radar_area_entered(area: Area2D) -> void:
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
		$Line2D.visible = false
		$Node2D2.rotation = 0.0
		Inventory.GetInstance().AddItems(StoredItem)
		StoredItem.clear()
		$AudioStreamPlayer2D.stop()
		set_physics_process(false)
		var rad = get_node_or_null("Radar2/Radar_Range")
		if (rad != null):
			rad.visible = false
		var an = get_node_or_null("Analyzer/Analyzer_Range")
		if (an != null):
			an.visible = false
		
func DissableMonitoring():
	$Radar.monitoring = false

func _on_return_sound_trigger_area_entered(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip and CommingBack):
		var plship = area.get_parent() as PlayerShip
		plship.GetDroneDock().PlayReturnSound()
