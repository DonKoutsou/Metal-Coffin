extends Node2D

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
	
	if (Ship is PlayerShip):
		marker.call_deferred("ToggleShipDetails", true)
		marker.call_deferred("ToggleFriendlyShipDetails", true)
		Ship.connect("ShipDockActions", marker.ToggleShowRefuel)
		Ship.connect("ShipDeparted", marker.OnShipDeparted)
		Ship.connect("StatLow", marker.OnStatLow)
		Ship.connect("Elint", marker.ToggleShowElint)
		Ship.connect("LandingStarted", marker.OnLandingStarted)
		Ship.connect("LandingCanceled", marker.OnLandingEnded)
		Ship.connect("LandingEnded", marker.OnLandingEnded)
		Ship.connect("TakeoffStarted", marker.OnLandingStarted)
		Ship.connect("TakeoffEnded", marker.OnLandingEnded)
		
		marker.SetMarkerDetails("Flagship", "P",Ship.GetShipSpeed())
	
	if (Ship is HostileShip):
		marker.ToggleFriendlyShipDetails(true)
		marker.ToggleShipDetails(true)
		marker.SetMarkerDetails(Ship.ShipName, Ship.ShipCallsign ,Ship.GetShipSpeed())
		marker.PlayHostileShipNotif()
	
	if (Ship is Drone):
		Ship.connect("ShipDockActions", marker.ToggleShowRefuel)
		Ship.connect("ShipDeparted", marker.OnShipDeparted)
		Ship.connect("DroneReturning", marker.DroneReturning)
		Ship.connect("Elint", marker.ToggleShowElint)
		Ship.connect("LandingStarted", marker.OnLandingStarted)
		Ship.connect("LandingCanceled", marker.OnLandingEnded)
		Ship.connect("LandingEnded", marker.OnLandingEnded)
		Ship.connect("TakeoffStarted", marker.OnLandingStarted)
		Ship.connect("TakeoffEnded", marker.OnLandingEnded)
		marker.ToggleShipDetails(true)
		marker.ToggleFriendlyShipDetails(true)
		marker.SetMarkerDetails(Ship.Cpt.CaptainName, "F",Ship.GetShipSpeed())
	
	if (Ship is Missile):
		marker.ToggleShipDetails(true)
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
	
	#Spot.connect("SpotAnalazyed", marker.OnSpotAnalyzed)
	
	_SpotMarkers.append(marker)
	
	marker.global_position = Spot.global_position
	
func RemoveShip(Ship : Node2D) -> void:
	if (!Ships.has(Ship)):
		return
	var index = Ships.find(Ship)
	_ShipMarkers[index].queue_free()
	_ShipMarkers.remove_at(index)
	Ships.remove_at(index)

func FixLabelClipping() -> void:
	var Mapinfos = get_tree().get_nodes_in_group("MapInfo")
	var AllMapInfos = get_tree().get_nodes_in_group("UnmovableMapInfo")
	AllMapInfos.append_array(Mapinfos)
	for g in Mapinfos:
		var control1 = g as Control
		if (!control1.visible):
			continue
		var r1 = control1.get_global_rect()
		for z in AllMapInfos:
			if (g == z):
				continue
			var control2 = z as Control
			if (!control2.visible):
				continue
			var r2 = control2.get_global_rect()
			var tries = 0
			while (r1.intersects(r2)):
				control1.owner.UpdateSignRotation()
				tries += 1
				if (tries > 10):
					return

var d = 0.1
var Circles : Array[PackedVector2Array] = []
func _physics_process(delta: float) -> void:
	FixLabelClipping()
	$CircleDrawer.UpdateCircles(Circles)
	d -= delta
	if (d > 0):
		return
	d = 0.1
	Circles.clear()
	for g in _ShipMarkers.size():
		var ship = Ships[g]
		var Marker = _ShipMarkers[g]
		if (ship is HostileShip):
			#if (ship.VisibleBy.size() > 0):
			Marker.global_position = ship.global_position
			Marker.UpdateSpeed(ship.GetShipSpeed())
			#if (ship.SeenShips()):
				#Marker.UpdateThreatLevel(ship.VisibleBt[ship.VisibleBt.keys()[0]])
			#Marker.UpdateSeenTime()
			Marker.ToggleTimeLastSeend(false)
			#Marker.ToggleThreat(true)
			Marker.UpdateDroneFuel(roundi(ship.Cpt.GetStat("FUEL_TANK").CurrentVelue), ship.Cpt.GetStatValue("FUEL_TANK"))
			Marker.UpdateTrajectory(ship.global_rotation)
			#else :
				#Marker.ToggleThreat(false)
				#Marker.ToggleTimeLastSeend(true)
				#Marker.UpdateTime()
			
		else:
			if (ship is Drone):
				Marker.UpdateSpeed(ship.GetShipSpeed())
				Marker.UpdateDroneFuel(roundi(ship.Cpt.GetStat("FUEL_TANK").CurrentVelue), ship.Cpt.GetStatValue("FUEL_TANK"))
				Marker.UpdateDroneHull(ship.Cpt.GetStat("HULL").CurrentVelue, ship.Cpt.GetStat("HULL").GetStat())
				Marker.UpdateTrajectory(ship.global_rotation)
				if (ship.RadarWorking):
					Circles.append(PackedVector2Array([ship.global_position, Vector2(ship.Cpt.GetStatValue("RADAR_RANGE"), 0)]))
				if (ship.Landing or ship.TakingOff):
					Marker.UpdateAltitude(ship.Altitude)
				#Marker.global_position = ship.global_position
			if (ship is PlayerShip):
				Marker.UpdateSpeed(ship.GetShipSpeed())
				Marker.UpdateFuel()
				Marker.UpdateHull()
				Marker.UpdateTrajectory(ship.global_rotation)
				if (ship.RadarWorking):
					Circles.append(PackedVector2Array([ship.global_position, Vector2(ShipData.GetInstance().GetStat("VIZ_RANGE").GetStat(), 0)]))
				if (ship.Landing or ship.TakingOff):
					Marker.UpdateAltitude(ship.Altitude)
				#Marker.global_position = ship.global_position
				#Marker.UpdateSpeed(ship.GetSpeed())
			if (ship is Missile):
				Marker.UpdateTrajectory(ship.global_rotation)
			Marker.global_position = ship.global_position
		
	
	
		
