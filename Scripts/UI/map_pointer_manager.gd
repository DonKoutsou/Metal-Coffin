extends Node2D

class_name MapPointerManager

@export var MarkerScene : PackedScene
@export var MapSpotMarkerScene : PackedScene
@export var FriendlyColor : Color
@export var EnemyColor : Color
@export var ConvoyColor : Color
@export var EnemyDebug : bool = false
@export var UIEventH : UIEventHandler
#@export var SpotColor : Color
var Ships : Array[Node2D] = []
var _ShipMarkers : Array[ShipMarker] = []
var Spots : Array[Node2D] = []
var _SpotMarkers : Array[SpotMarker] = []

static var Instance : MapPointerManager

func _enter_tree() -> void:
	Instance = self

func _ready() -> void:
	UIEventH.connect("MarkerEditorCleared", ClearLines)

static func GetInstance() -> MapPointerManager:
	return Instance
#
#func _draw() -> void:
	#pass
#
#func DrawLines() -> void:
	#pass

func ClearLines() -> void:
	for g in $MapLines.get_children():
		g.queue_free()
	PopUpManager.GetInstance().DoFadeNotif("Marker Cleared")
func AddShip(Ship : Node2D, Friend : bool) -> void:
	if (Ships.has(Ship)):
		if (Ship is HostileShip and !Ship.Destroyed):
			_ShipMarkers[Ships.find(Ship)].PlayHostileShipNotif("Hostile Ship Located")
		return
		
	Ships.append(Ship)
	var marker = MarkerScene.instantiate() as ShipMarker
	
	add_child(marker)
	
	marker.global_position = Ship.global_position
	
	if (Friend):
		marker.modulate = FriendlyColor
	else:
		marker.modulate = EnemyColor
		#_ShipMarkers[Ships.find(Ship)].PlayHostileShipNotif()
	if (Ship is HostileShip):
		if (Ship.Convoy):
			marker.modulate = ConvoyColor
		if (EnemyDebug):
			#HOSTILE_SHIP_DEBUG
			marker.ToggleFriendlyShipDetails(true)
			#////
		
		marker.ToggleShipDetails(true)
		if (Ship.Destroyed):
			marker.OnHostileShipDestroyed()
		else:
			marker.SetMarkerDetails(Ship.ShipName, Ship.Cpt.ShipCallsign ,Ship.GetShipSpeed())
			marker.PlayHostileShipNotif("Hostile Ship Located")
			marker.SetType("Ship")
			Ship.connect("ShipWrecked", marker.OnHostileShipDestroyed)
		
	else : if (Ship is MapShip):
		Ship.connect("ShipDockActions", marker.ToggleShowRefuel)
		Ship.connect("ShipDeparted", marker.OnShipDeparted)
		if (Ship is Drone):
			Ship.connect("DroneReturning", marker.DroneReturning)
		Ship.connect("Elint", marker.ToggleShowElint)
		Ship.connect("LandingStarted", marker.OnLandingStarted)
		Ship.connect("LandingCanceled", marker.OnLandingEnded)
		Ship.connect("LandingEnded", marker.OnLandingEnded)
		Ship.connect("TakeoffStarted", marker.OnLandingStarted)
		Ship.connect("TakeoffEnded", marker.OnLandingEnded)
		marker.call_deferred("ToggleShipDetails", true)
		marker.call_deferred("ToggleFriendlyShipDetails", true)
		marker.SetMarkerDetails(Ship.Cpt.CaptainName, "F",Ship.GetShipSpeed())
		marker.SetType("Ship")
	else : if (Ship is Missile):
		if (!Friend):
			marker.PlayHostileShipNotif("Hostile Missile Located")
		marker.ToggleShipDetails(true)
		marker.SetMarkerDetails(Ship.MissileName, "M",Ship.GetSpeed())
		marker.SetType("Missile")
	_ShipMarkers.append(marker)
	
	marker.UpdateCameraZoom(ShipCamera.GetInstance().zoom.x)
func AddSpot(Spot : MapSpot, PlayAnim : bool) -> void:
	if (Spots.has(Spot)):
		return
	Spots.append(Spot)
	var marker = MapSpotMarkerScene.instantiate() as SpotMarker
	
	add_child(marker)
	
	#marker.modulate = SpotColor
	
	#marker.ToggleShipDetails(true)
	marker.SetMarkerDetails(Spot, PlayAnim)
	
	if (Spot.AlarmRaised):
		marker.OnAlarmRaised(false)
	else:
		Spot.connect("SpotAlarmRaised", marker.OnAlarmRaised)
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
		if (!control1.is_visible_in_tree()):
			continue
		var r1 = control1.get_global_rect()
		for z in AllMapInfos:
			if (g == z):
				continue
			var control2 = z as Control
			if (!control2.is_visible_in_tree()):
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
			Marker.ToggleShipDetails(!ship.Docked)
			Marker.ToggleVisualContactProgress(ship.VisualContactCountdown < 10)
			if (ship.VisualContactCountdown < 10):
				
				Marker.UpdateVisualContactProgress(ship.VisualContactCountdown)
			if (EnemyDebug):
				Marker.global_position = ship.global_position
				Marker.UpdateSpeed(ship.GetShipSpeed())

				Marker.ToggleTimeLastSeend(false)
				Marker.UpdateDroneHull(ship.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL), ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL))
				Marker.UpdateDroneFuel(roundi(ship.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)), ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK))
				Marker.UpdateTrajectory(ship.global_rotation)
			else:
				if (ship.Destroyed):
					Marker.SetMarkerDetails("Ship Debris", "" ,0)
					
				else: if (ship.VisibleBy.size() > 0):
					Marker.global_position = ship.global_position
					Marker.UpdateSpeed(ship.GetShipSpeed())
					
					Marker.ToggleTimeLastSeend(false)
					Marker.UpdateTrajectory(ship.global_rotation)
				else :
					###Marker.ToggleThreat(false)
					Marker.ToggleTimeLastSeend(true)
					var timepast = Clock.GetInstance().GetHoursSince(Marker.TimeLastSeen)
					if (timepast > 24):
						call_deferred("RemoveShip", ship)
					else:
						Marker.UpdateTime(timepast)
		else:
			if (ship is MapShip):
				var docked = ship.Docked
				Marker.global_position = ship.global_position
				Marker.ToggleShipDetails(!docked)
		
				Marker.UpdateTrajectory(ship.global_rotation)
				Marker.UpdateSpeed(ship.GetShipSpeed())
				if (docked):
					continue
				#if (ship.GetDroneDock().DockedDrones.size() > 0):
					#var fuel = ship.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
					#var MaxFuel = ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
					#for z in ship.GetDroneDock().DockedDrones:
						#fuel += z.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
						#MaxFuel += z.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
					#Marker.UpdateDroneFuel(roundi(fuel), MaxFuel)
				#else:
				var fuelstats = ship.GetFuelStats()
				Marker.UpdateDroneFuel(roundi(fuelstats["CurrentFuel"]), fuelstats["MaxFuel"])
				Marker.UpdateDroneHull(roundi(ship.Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)), ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL))
				
				if (ship.RadarWorking):
					Circles.append(PackedVector2Array([ship.global_position, Vector2(max(ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE), 105), 0)]))
				else:
					Circles.append(PackedVector2Array([ship.global_position, Vector2(105, 0)]))
				if (ship.Landing or ship.TakingOff):
					Marker.UpdateAltitude(ship.Altitude)

				
				
				#Marker.UpdateSpeed(ship.GetSpeed())
			else : if (ship is Missile):
				if (ship.FiredBy is PlayerDrivenShip or ship.VisibleBy.size() > 0):
					Marker.global_position = ship.global_position
					#Marker.UpdateSpeed(ship.GetShipSpeed())
					Marker.visible = true
					Marker.ToggleTimeLastSeend(false)
					Marker.UpdateTrajectory(ship.global_rotation)
				else :
					###Marker.ToggleThreat(false)
					Marker.visible = false
				#Marker.UpdateTrajectory(ship.global_rotation)
			
		
	
	
		
