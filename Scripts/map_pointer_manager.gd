extends Control

class_name MapPointerManager

@export var MarkerScene : PackedScene
@export var FriendlyColor : Color
@export var EnemyColor : Color
var Ships : Array[Node2D] = []
var _ShipMarkers : Array[ShipMarker] = []

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
	
	if (Ship is HostileShip):
		marker.ToggleShipDetails(true)
		marker.SetMarkerDetails(Ship.ShipName, Ship.GetSpeed())
	
	if (Ship is Drone):
		marker.SetMarkerDetails(Ship.Cpt.CaptainName, Ship.GetSpeed())
	
	if (Ship is Missile):
		marker.SetMarkerDetails(Ship.MissileName, Ship.GetSpeed())
	
	_ShipMarkers.append(marker)
func RemoveShip(Ship : Node2D) -> void:
	if (!Ships.has(Ship)):
		return
	var index = Ships.find(Ship)
	_ShipMarkers[index].queue_free()
	_ShipMarkers.remove_at(index)
	Ships.remove_at(index)
func _physics_process(_delta: float) -> void:
	for g in _ShipMarkers.size():
		var ship = Ships[g]
		var Marker = _ShipMarkers[g]
		if (ship is HostileShip):
			if (ship.VisibleBt.size() > 0):
				Marker.global_position = ship.global_position
				Marker.UpdateSpeed(ship.GetSpeed())
				if (ship.SeenShips()):
					Marker.UpdateThreatLevel(ship.VisibleBt[ship.VisibleBt.keys()[0]])
				#Marker.UpdateSeenTime()
				Marker.ToggleTimeLastSeend(false)
				Marker.ToggleThreat(true)
			else :
				Marker.ToggleThreat(false)
				Marker.ToggleTimeLastSeend(true)
				Marker.UpdateTime()
			
		else:
			if (ship is Drone):
				Marker.ToggleShipDetails(!ship.Docked)
				Marker.UpdateSpeed(ship.GetSpeed())
			if (ship is Missile):
				Marker.ToggleShipDetails(true)
				#Marker.UpdateSpeed(ship.GetSpeed())
			Marker.global_position = ship.global_position
