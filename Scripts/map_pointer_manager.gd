extends Control

class_name MapPointerManager

@export var MarkerScene : PackedScene
@export var MapSpotMarkerScene : PackedScene
@export var FriendlyColor : Color
@export var EnemyColor : Color
#@export var SpotColor : Color
var Ships : Array[Node2D] = []
var _ShipMarkers : Array[ShipMarker] = []
var Spots : Array[Node2D] = []
var _SpotMarkers : Array[SpotMarker] = []
static var Instance : MapPointerManager

func _enter_tree() -> void:
	Instance = self
static func GetInstance() -> MapPointerManager:
	return Instance

func _draw() -> void:
	pass

func AddShip(Ship : Node2D, Friend : bool) -> void:
	if (Ships.has(Ship)):
		if (Ship is HostileShip):
			_ShipMarkers[Ships.find(Ship)].PlayHostileShipNotif()
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
		marker.SetMarkerDetails(Ship.ShipName, Ship.ShipCallsign ,Ship.GetSpeed())
		marker.PlayHostileShipNotif()
	
	if (Ship is Drone):
		marker.SetMarkerDetails(Ship.Cpt.CaptainName, "F",Ship.GetSpeed())
	
	if (Ship is Missile):
		marker.SetMarkerDetails(Ship.MissileName, "M",Ship.GetSpeed())
	
	_ShipMarkers.append(marker)
	
func AddSpot(Spot : MapSpot, PlayAnim : bool) -> void:
	if (Spots.has(Spot)):
		return
	Spots.append(Spot)
	var marker = MapSpotMarkerScene.instantiate() as SpotMarker
	
	add_child(marker)
	
	#marker.modulate = SpotColor
	
	#marker.ToggleShipDetails(true)
	marker.SetMarkerDetails(Spot, PlayAnim)
	
	Spot.connect("SpotAnalazyed", marker.OnSpotAnalyzed)
	
	_SpotMarkers.append(marker)
	
	marker.global_position = Spot.global_position
	
func RemoveShip(Ship : Node2D) -> void:
	if (!Ships.has(Ship)):
		return
	var index = Ships.find(Ship)
	_ShipMarkers[index].queue_free()
	_ShipMarkers.remove_at(index)
	Ships.remove_at(index)
var d = 0.1
func _physics_process(delta: float) -> void:
	#var Mapinfos = get_tree().get_nodes_in_group("MapInfo")
	
	#for g in Mapinfos:
		#for z in Mapinfos:
			#if (g == z):
				#continue
			#var control1 = g as Control
			#if (!control1.visible):
				#continue
			#var r1 = control1.get_rect()
			#r1.position = control1.global_position
			#var control2 = z as Control
			#if (!control2.visible):
				#continue
			#var r2 = control2.get_rect()
			#r2.position = control2.global_position
			#if (r1.intersects(r2)):
				#control1.rotation -= 1
				#control1.get_parent().rotation += 1
	d -= delta
	if (d > 0):
		return
	d = 0.1
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
	
	
		
