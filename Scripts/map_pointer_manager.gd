extends Control

class_name MapPointerManager

@export var MarkerScene : PackedScene
@export var FriendlyColor : Color
@export var EnemyColor : Color
var Ships : Array[Node2D] = []
var Markers : Array[ShipMarker] = []

static var Instance : MapPointerManager

func _enter_tree() -> void:
	Instance = self
static func GetInstance() -> MapPointerManager:
	return Instance

func AddShip(Ship : Node2D, Friend : bool) -> void:
	if (Ships.has(Ship)):
		return
	Ships.append(Ship)
	var marker = MarkerScene.instantiate() as ShipMarker
	
	add_child(marker)
	
	if (Friend):
		marker.modulate = FriendlyColor
	else:
		marker.modulate = EnemyColor
		marker.ToggleShipDetails(true)
		marker.SetMarkerDetails("TempName", Ship.GetSpeed())
	
	if (Ship is Drone):
		marker.SetMarkerDetails(Ship.Cpt.CaptainName, Ship.GetSpeed())
		
	
	Markers.append(marker)
func RemoveShip(Ship : Node2D) -> void:
	var index = Ships.find(Ship)
	Markers[index].queue_free()
	Markers.remove_at(index)
	Ships.remove_at(index)
func _physics_process(_delta: float) -> void:
	for g in Markers.size():
		var ship = Ships[g]
		var Marker = Markers[g]
		if (ship is HostileShip):
			if (ship.VisibleBy.size() > 0):
				Marker.global_position = ship.global_position
				Marker.UpdateSpeed(ship.GetSpeed())
				#Marker.UpdateSeenTime()
				Marker.ToggleTimeLastSeend(false)
			else :
				Marker.ToggleTimeLastSeend(true)
				Marker.UpdateTime()
			
		else:
			if (ship is Drone):
				Marker.ToggleShipDetails(!ship.Docked)
				Marker.UpdateSpeed(ship.GetSpeed())
			Marker.global_position = ship.global_position
