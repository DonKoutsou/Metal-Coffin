extends Node2D

class_name Drone

var CommingBack = false
var Docked = true

var StoredItem : Array[Item] = []

func  _ready() -> void:
	set_physics_process(false)
	$Radar.monitoring = false
	$Line2D.visible = false
func EnableDrone():
	Docked = false
	set_physics_process(true)
	$Radar.monitoring = true
	#$Line2D.visible = false
	
func _physics_process(_delta: float) -> void:
	if (CommingBack):
		var interceptionpoint = calculateinterceptionpoint()
		updatedronecourse(interceptionpoint)
	else:
		global_position = $Node2D.global_position

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

func _on_radar_area_entered(area: Area2D) -> void:
	if (Docked):
		return
	if (area.get_parent() is MapSpot and !CommingBack):
		rotation = 0.0
		CommingBack = true
		Docked = false
		$Line2D.visible = true
		var spot = area.get_parent() as MapSpot
		StoredItem = spot.SpotType.GetSpotDrop()
		spot.OnSpotSeen()
	else : if (area.get_parent() is PlayerShip and CommingBack):
		var plship = area.get_parent() as PlayerShip
		plship.GetDroneDock().DockDrone(self)
		CommingBack = false
		Docked = true
		$Line2D.visible = false
		$Node2D2.rotation = 0.0
		Inventory.GetInstance().AddItems(StoredItem)
		StoredItem.clear()
		set_physics_process(false)
		
func DissableMonitoring():
	$Radar.monitoring = false
