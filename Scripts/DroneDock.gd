extends Area2D
class_name DroneDock
@export var DroneScene : PackedScene

var DockedDrones : Array[Drone]
var FlyingDrones : Array[Drone]

func _ready() -> void:
	for g in 6:
		var drone = DroneScene.instantiate()
		call_deferred("AddDroneToHierarchy",drone)

func AddDroneToHierarchy(drone : Drone):
	get_parent().get_parent().add_child(drone)
	DockDrone(drone)
	
func DockDrone(drone : Drone):
	FlyingDrones.erase(drone)
	DockedDrones.append(drone)
	var docks = $DroneSpots.get_children()
	for g in docks.size():
		if (docks[g].get_child_count() > 0):
			continue
		var dock = docks[g]
		var trans = RemoteTransform2D.new()
		dock.add_child(trans)
		trans.remote_path = drone.get_path()
		return

func UndockDrone(drone : Drone):
	DockedDrones.erase(drone)
	FlyingDrones.append(drone)
	var docks = $DroneSpots.get_children()
	for g in docks.size():
		if (docks[g].get_child_count() > 0):
			var trans = docks[g].get_child(0) as RemoteTransform2D
			if (trans.remote_path == drone.get_path()):
				trans.free()
				return

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("ShootDrone")):
		if (DockedDrones.size() == 0):
			return
		var drone = DockedDrones[0]
		UndockDrone(drone)
		drone.look_at(get_global_mouse_position())
		drone.EnableDrone()
