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
@export var UIEventH : UIEventHandler
@export var ControllerEventHandler : ShipControllerEventHandler
@export var MapSpotMarkerParent : Node2D
@export var ShipMarkerParent : Node2D

#@export var SpotColor : Color

var Ships : Array[Node2D] = []
var _ShipMarkers : Array[ShipMarker] = []
var Spots : Array[Node2D] = []
var _SpotMarkers : Array[SpotMarker] = []

static func GetInstance() -> MapPointerManager:
	return Instance

static var Instance : MapPointerManager

var ControlledShip : PlayerDrivenShip

signal TargetSelected(Ship : MapShip)
signal TargetSpotSelected(Target : SpotMarker)

func _enter_tree() -> void:
	Instance = self

func _ready() -> void:
	UIEventH.connect("MarkerEditorCleared", ClearLines)
	ControllerEventHandler.connect("OnControlledShipChanged", OnControlledShipChanged)
	ControlledShip = ControllerEventHandler.CurrentControlled

func OnControlledShipChanged(Ship : PlayerDrivenShip) -> void:
	ControlledShip = Ship

func OnShipTargetSelected(Marker : ShipMarker) -> void:
	var index = _ShipMarkers.find(Marker)
	var Ship = Ships[index]
	TargetSelected.emit(Ship)

func OnSpotTargetSelected(Marker : SpotMarker) -> void:
	TargetSpotSelected.emit(Marker)

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

	ShipMarkerParent.add_child(marker)
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
		#if (Commander.ENEMY_DEBUG):
			#HOSTILE_SHIP_DEBUG
			#marker.ToggleFriendlyShipDetails(true)
			#////
		marker.ShipTargetSelected.connect(OnShipTargetSelected)
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
		Ship.AltitudeChanged.connect(marker.AltitudeChanged)
		if (Ship is Drone):
			Ship.DroneReturning.connect(marker.DroneReturning)
		
		marker.ShipSelected.connect(ControllerEventHandler.ShipChanged.bind(Ship))
		marker.ShipTargetSelected.connect(OnShipTargetSelected)
		marker.call_deferred("ToggleShipDetails", true)
		marker.SetMarkerDetails(Ship.Cpt.GetCaptainName(), "F",Ship.GetAffectedSpeed())
		marker.SetType("Ship")
		
	else : if (Ship is Missile):
		if (!Friend):
			marker.PlayHostileShipNotif("Hostile Missile Located")
		marker.ToggleShipDetails(true)
		marker.SetMarkerDetails(Ship.MissileName, "M",Ship.GetSpeed())
		Ship.AltitudeChanged.connect(marker.AltitudeChanged)
		marker.SetType("Missile")
	
	marker.Init(Ship)
	
	return marker

func AddSpot(Spot : MapSpot, PlayAnim : bool) -> void:
	if (Spots.has(Spot)):
		return
	Spots.append(Spot)
	var marker = MapSpotMarkerScene.instantiate() as SpotMarker
	marker.TownTargetSelected.connect(OnSpotTargetSelected)
	MapSpotMarkerParent.add_child(marker)
	
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

func FixMarkerClipping() -> void:
	var ShipMarkers = get_tree().get_nodes_in_group("MapShipVizualiser")
	for Marker1 : TextureRect in ShipMarkers:
		if (!Marker1.is_visible_in_tree()):
			continue

		for Marker2 : TextureRect in ShipMarkers:
			if (Marker1 == Marker2):
				continue
			if (!Marker2.is_visible_in_tree()):
				continue

			var OffsetToApply : float = 4 * Marker1.scale.x
			if (Marker2.global_position.x < Marker1.global_position.x):
				OffsetToApply *= -1
			var tries = 0
			while (Marker1.get_global_rect().intersects(Marker2.get_global_rect()) and tries < 10):
				Marker2.owner.position.x += OffsetToApply
				tries += 1


			

func FixLabelClipping() -> void:
	var Mapinfos = get_tree().get_nodes_in_group("MapInfo")
	var AllMapInfos = get_tree().get_nodes_in_group("UnmovableMapInfo")
	AllMapInfos.append_array(Mapinfos)
	for Info1 : Control in Mapinfos:
		if (!Info1.is_visible_in_tree()):
			continue

		for Info2 : Control in AllMapInfos:
			if (Info1 == Info2):
				continue
			if (!Info2.is_visible_in_tree()):
				continue

			var tries = 0
			while (Info1.get_global_rect().intersects(Info2.get_global_rect()) and tries < 10):
				Info1.owner.UpdateSignRotation()
				tries += 1

var hulls: Array[PackedVector2Array] = []

func _physics_process(delta: float) -> void:
	
	FixLabelClipping()

	hulls.clear()
	
	var CamPos = ShipCamera.GetInstance().get_screen_center_position()
	var d = delta
	if (SimulationManager.IsPaused()):
		d = 0
	#var LightAmm = WeatherManage.GetLightAmm()
	for g in _ShipMarkers.size():
		var Ship = Ships[g]
		if (Ship is PlayerDrivenShip):
			if (Ship.Command == null):
				hulls.append(Ship.GetBiggestRadarCicle())
			#var visibility = WeatherManage.GetVisibilityInPosition(Ship.global_position, LightAmm)
			#var Radius : float
			#if (Ship.RadarWorking):
				#Radius = max(Ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE), 110 * visibility)
			#else:
				#Radius = 110 * visibility
		
		
		_ShipMarkers[g].Update(Ship == ControlledShip, CamPos, d)
	CircleDr.UpdatePolygons(hulls)
	FixMarkerClipping()

func get_circle_points(center: Vector2, radius: float, num_points: int = 10) -> PackedVector2Array:
	var circle_points = PackedVector2Array()
	for i in num_points:
		var angle = float(i) / float(num_points) * PI * 2.0
		var pt = center + Vector2(cos(angle), sin(angle)) * radius
		circle_points.append(pt)
	# Optionally close the loop:
	circle_points.append(circle_points[0])
	return circle_points

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
