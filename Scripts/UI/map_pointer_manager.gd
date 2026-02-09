extends Node2D

#This script manages all the Ship and Town markers. 
class_name MapPointerManager

@export var CircleDr : CircleDrawer

@export var MapLonePos : Node2D
@export var MarkerScene : PackedScene
@export var MapSpotMarkerScene : PackedScene
@export var FriendlyColor : Color
@export var EnemyColor : Color
@export var ConvoyColor : Color
@export var EnemyDebug : bool = false
@export var UIEventH : UIEventHandler
@export var ControllerEventHandler : ShipControllerEventHandler
#@export var SpotColor : Color

var Ships : Array[Node2D] = []
var _ShipMarkers : Array[ShipMarker] = []
var Spots : Array[Node2D] = []
var _SpotMarkers : Array[SpotMarker] = []

static func GetInstance() -> MapPointerManager:
	return Instance

static var Instance : MapPointerManager

var ControlledShip : PlayerDrivenShip

func _enter_tree() -> void:
	Instance = self

func _ready() -> void:
	UIEventH.connect("MarkerEditorCleared", ClearLines)
	ControllerEventHandler.connect("OnControlledShipChanged", OnControlledShipChanged)
	ControlledShip = ControllerEventHandler.CurrentControlled

func OnControlledShipChanged(Ship : PlayerDrivenShip) -> void:
	ControlledShip = Ship


func ClearLines() -> void:
	for g in $MapLines.get_children():
		g.queue_free()
	PopUpManager.GetInstance().DoFadeNotif("Marker Cleared")
	
func AddShip(Ship : Node2D, Friend : bool, notify : bool = false) -> ShipMarker:
	if (Ships.has(Ship)):
		if (Ship is HostileShip and !Ship.Destroyed and notify):
			if (Ship.Convoy):
				_ShipMarkers[Ships.find(Ship)].PlayHostileShipNotif("Convoy\nLocated")
			else:
				_ShipMarkers[Ships.find(Ship)].PlayHostileShipNotif("Hostile Ship\nLocated")
		return
		
	Ships.append(Ship)
	var marker = MarkerScene.instantiate() as ShipMarker

	add_child(marker)
	_ShipMarkers.append(marker)
	
	marker.global_position = Ship.global_position
	
	if (Friend):
		marker.modulate = FriendlyColor
	else:
		marker.modulate = EnemyColor
		#_ShipMarkers[Ships.find(Ship)].PlayHostileShipNotif()
	if (Ship is HostileShip):
		if (Ship.Convoy):
			marker.modulate = ConvoyColor
		#if (EnemyDebug):
			#HOSTILE_SHIP_DEBUG
			#marker.ToggleFriendlyShipDetails(true)
			#////
		
		marker.ToggleShipDetails(true)
		if (Ship.Destroyed):
			marker.OnHostileShipDestroyed()
		else:
			marker.SetMarkerDetails(Ship.ShipName, Ship.Cpt.ShipCallsign ,Ship.GetShipSpeed())
			if (notify):
				marker.PlayHostileShipNotif("Hostile Ship\nLocated")
			marker.SetType("Ship")
			Ship.connect("ShipWrecked", marker.OnHostileShipDestroyed)
		
	else : if (Ship is PlayerDrivenShip):
		Ship.ShipDockActions.connect(marker.ToggleShowRefuel)
		Ship.ShipDeparted.connect(marker.OnShipDeparted)
		Ship.Elint.connect(marker.ToggleShowElint)
		Ship.Cpt.OnNameChanged.connect(marker.OnCaptainNameChanged)
		Ship.LandingStarted.connect(marker.OnLandingStarted)
		Ship.LandingEnded.connect(marker.OnLandingEnded)
		Ship.TakeoffStarted.connect(marker.OnLandingStarted)
		Ship.TakeoffEnded.connect(marker.OnLandingEnded)
		Ship.MatchingAltitudeStarted.connect(marker.OnLandingStarted)
		Ship.MatchingAltitudeEnded.connect(marker.OnLandingEnded)
		
		if (Ship is Drone):
			Ship.DroneReturning.connect(marker.DroneReturning)
		
		marker.ShipSelected.connect(ControllerEventHandler.ShipChanged.bind(Ship))
		marker.call_deferred("ToggleShipDetails", true)
		marker.SetMarkerDetails(Ship.Cpt.GetCaptainName(), "F",Ship.GetAffectedShipSpeed())
		marker.SetType("Ship")
		
	else : if (Ship is Missile):
		if (!Friend):
			marker.PlayHostileShipNotif("Hostile Missile Located")
		marker.ToggleShipDetails(true)
		marker.SetMarkerDetails(Ship.MissileName, "M",Ship.GetSpeed())
		marker.SetType("Missile")
	
	marker.Init(Ship)
	
	return marker

func AddSpot(Spot : MapSpot, PlayAnim : bool) -> void:
	if (Spots.has(Spot)):
		return
	Spots.append(Spot)
	var marker = MapSpotMarkerScene.instantiate() as SpotMarker
	
	add_child(marker)
	
	_SpotMarkers.append(marker)
	marker.SetMarkerDetails(Spot, PlayAnim)
	
	if (Spot.AlarmRaised):
		marker.OnAlarmRaised(false)
	else:
		Spot.SpotAlarmRaised.connect(marker.OnAlarmRaised)

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

var Circles : Array[PackedVector2Array] = []

#var d = 0.6

func _physics_process(_delta: float) -> void:
	#d -= _delta
	
	#CircleDr.queue_redraw()
	FixLabelClipping()
	#if (d > 0):
		#return
	#d = 1.0
	
	
	Circles.clear()
	
	var CamPos = ShipCamera.GetInstance().get_screen_center_position()
	var LightAmm = WeatherManage.GetLightAmm()
	for g in _ShipMarkers.size():
		var Ship = Ships[g]
		if (Ship is PlayerDrivenShip):
			var visibility = WeatherManage.GetVisibilityInPosition(Ship.global_position, LightAmm)
			if (Ship.RadarWorking):
				Circles.append(PackedVector2Array([Ship.global_position, Vector2(max(Ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE), 110 * visibility), 0)]))
			else:
				Circles.append(PackedVector2Array([Ship.global_position, Vector2(110 * visibility, 0)]))
				
		_ShipMarkers[g].Update(Ship, Ship == ControlledShip, CamPos)
	CircleDr.UpdateCircles(Circles)

func GetSaveData() -> SaveData:
	var Dat = SaveData.new()
	Dat.DataName = "Markers"
	for g in _ShipMarkers.size():
		
		var ship = Ships[g]
		var Marker = _ShipMarkers[g]
		
		if (ship is HostileShip):
			if (!ship.Destroyed and ship.VisibleBy.size() == 0):
				Dat.Datas.append(Marker.GetSaveData())
	return Dat

func LoadSaveData(Data : SaveData) -> void:
	var Enemies = get_tree().get_nodes_in_group("Enemy")
	for D : SD_ShipMarker in Data.Datas:
		var SavedName = D.ShipName
		for S : HostileShip in Enemies:
			var Name = S.GetShipName()
			if (SavedName == Name):
				var marker = AddShip(S, false, false)
				marker.TimeLastSeen = D.TimeLastSeen
				marker.global_position = D.Pos
				marker.UpdateTrajectory(D.Trajectory)
