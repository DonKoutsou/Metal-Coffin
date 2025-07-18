extends Camera2D

class_name ShipCamera

@export var Background : Control
#@export var CityLines : MapLineDrawer

@export var Cloud : Control
@export var WeatherMan : WeatherManage
#@export var Cloud2 : Control
@export var Ground : Control
@export var MinZoom : float = 0.1
@export var MaxZoom : float = 3.0
@export var ClickSound : AudioStreamPlayer

static var Instance : ShipCamera

static var WorldBounds : Vector2

signal ZoomChanged(NewVal : float)
signal PositionChanged(NewVal : Vector2)

var FocusedShip : PlayerDrivenShip
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
	Cloud.material.set_shader_parameter("offset", global_position / 1500)
	#Cloud2.material.set_shader_parameter("offset", (global_position / 1500) + Vector2(500,500))
	Ground.material.set_shader_parameter("offset", global_position / 1500)
	#call_deferred("OnZoomChanged", zoom)
	
static func GetInstance() -> ShipCamera:
	return Instance


#////////////////////////////
var ZoomStage = 1
var ZoomStageMulti = 0.5

var ZoomTw : Tween
var prevzoom = Vector2(1,1)

func _HANDLE_ZOOM(zoomval : float):
	#prevzoom = zoom
	if (is_instance_valid(ZoomTw)):
		ZoomTw.kill()
	ZoomTw = create_tween()
	ZoomTw.set_ease(Tween.EASE_OUT)
	ZoomTw.set_trans(Tween.TRANS_QUART)
	var newzoom = clamp(prevzoom * Vector2(zoomval, zoomval), Vector2(MinZoom,MinZoom), Vector2(MaxZoom,MaxZoom))
	#ZoomTw.tween_property(self, "zoom", newzoom, 1)
	ZoomTw.tween_method(UpdateZoom, zoom, newzoom, 1)
	if (prevzoom != newzoom):
		ClickSound.play()
	ZoomTw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	prevzoom = newzoom

func ForceZoomOut() -> void:
	if (is_instance_valid(ZoomTw)):
		ZoomTw.kill()
	ZoomTw = create_tween()
	ZoomTw.set_ease(Tween.EASE_OUT)
	ZoomTw.set_trans(Tween.TRANS_QUART)
	#ZoomTw.tween_property(self, "zoom", newzoom, 1)
	ZoomTw.tween_method(UpdateZoom, zoom, Vector2(MinZoom, MinZoom), 1)
	prevzoom = Vector2(MinZoom, MinZoom)
	ZoomTw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

func UpdateZoom(Zoom : Vector2) -> void:
	zoom = Zoom
	for g in get_tree().get_nodes_in_group("MapLines"):
		g.material.set_shader_parameter("line_width", lerp(0.01, 0.001, Zoom.x / 2))
	get_tree().call_group("LineMarkers", "CamZoomUpdated", Zoom.x)
	get_tree().call_group("ZoomAffected", "UpdateCameraZoom", Zoom.x)
	ZoomChanged.emit(Zoom.x)
	_UpdateMapGridVisibility()
	UpdateCameraPos(Vector2.ZERO)

func ForceZoom(Zoom : Vector2) -> void:
	prevzoom = Zoom
	zoom = Zoom
	for g in get_tree().get_nodes_in_group("MapLines"):
		g.material.set_shader_parameter("line_width", lerp(0.01, 0.001, Zoom.x / 2))
	get_tree().call_group("LineMarkers", "CamZoomUpdated", Zoom.x)
	get_tree().call_group("ZoomAffected", "UpdateCameraZoom", Zoom.x)
	ZoomChanged.emit(Zoom.x)
	_UpdateMapGridVisibility()
#////////////////////////////
var touch_points: Dictionary = {}
var start_zoom: Vector2
var start_dist: float
func _HANDLE_TOUCH(event: InputEventScreenTouch):
	if event.pressed:
		touch_points[event.index] = event.position
	else:
		touch_points.erase(event.index)

	if touch_points.size() == 2:
		var touch_point_positions = touch_points.values()
		start_dist = touch_point_positions[0].distance_to(touch_point_positions[1])
		start_zoom = zoom
		#start_dist = 0
#////////////////////////////
func _HANDLE_DRAG(event: InputEventScreenDrag):
	touch_points[event.index] = event.position
	if touch_points.size() == 2 :
		var touch_point_positions = touch_points.values()
		var current_dist = touch_point_positions[0].distance_to(touch_point_positions[1])
		var zoom_factor = (start_dist / current_dist)
		UpdateZoom(clamp(start_zoom / zoom_factor, Vector2(0.045,0.045), Vector2(2.1,2.1)))
		if (!ClickSound.playing):
			ClickSound.play()
	else:
		UpdateCameraPos(event.relative)

var CloudShowing = true
var GridShowing = false

var MapGridTween : Tween
var WeatherTween : Tween

func ToggleWeatherMan() -> void:
	WeatherMan.visible = !WeatherMan.visible

func _UpdateMapGridVisibility():
	if (zoom.x < 1.5 and !GridShowing):
		if (is_instance_valid(MapGridTween)):
			MapGridTween.kill()
			MapGridTween = null
		MapGridTween = create_tween()
		MapGridTween.tween_property(Background, "modulate", Color(1,1,1,1), 0.5)
		WeatherTween = create_tween()
		WeatherTween.tween_property(WeatherMan, "modulate", Color(1,1,1,1), 0.5)
		GridShowing = true
		
		MapGridTween.finished.connect(Cloud.hide)
		#MapGridTween.finished.connect(Cloud2.hide)
		MapGridTween.finished.connect(Ground.hide)
		
		
	else: if (zoom.x >= 1.5):
		Cloud.visible = zoom.x < 8.0
		if (GridShowing):
			if (is_instance_valid(MapGridTween)):
				MapGridTween.kill()
				MapGridTween = null
			#Cloud2.show()
			Ground.show()
			
			MapGridTween = create_tween()
			MapGridTween.tween_property(Background, "modulate", Color(1,1,1,0), 0.5)
			WeatherTween = create_tween()
			WeatherTween.tween_property(WeatherMan, "modulate", Color(1,1,1,0), 0.5)
			GridShowing = false
	#if (zoom.x < 4.0 and CloudShowing):
		#var cloudtw = create_tween()
		#cloudtw.tween_property(Cloud, "modulate", Color(1,1,1,0), 0.5)
		#CloudShowing = false
	#else : if (zoom.x > 4.0 and !CloudShowing):
		#var cloudtw = create_tween()
		#cloudtw.tween_property(Cloud, "modulate", Color(1,1,1,1), 0.5)
		#CloudShowing = true
	#Cloud.visible = zoom.x > 0.8
	#Background.size = Vector2(30000,30000) / zoom
	#Background.position = -Background.size /2
	Background.UpdateZoom(zoom.x)
	

	#$"../InScreenUI/Control3/Rulers/Panel3".material.set_shader_parameter("zoom", zoom.x * 2)
func UpdateCameraPos(relativeMovement : Vector2):
	if (FrameTween != null):
		FrameTween.kill()
	if (FocusedShip != null):
		FocusedShip = null
	
	
	var extent = get_viewport_rect().size / 2 / zoom.x
	
	var maxposY = Vector2(-(0 - 1000 + extent.y), WorldBounds.y - 1000 + extent.y)
	
	var maxposX = Vector2(-((WorldBounds.x + 3000) / 2 - extent.x), (WorldBounds.x + 3000) / 2 - extent.x)

	var rel = relativeMovement / zoom
	var newpos = Vector2(clamp(position.x - rel.x, maxposX.x, maxposX.y) ,clamp(position.y - rel.y, maxposY.y, maxposY.x) )
	if (newpos.x != position.x):
		position.x = newpos.x
	if (newpos.y != position.y):
		position.y = newpos.y

	Cloud.material.set_shader_parameter("offset", global_position / 1500)
	#Cloud2.material.set_shader_parameter("offset", (global_position / 1500) + Vector2(500,500))
	Ground.material.set_shader_parameter("offset", global_position / 1500)
	Background.UpdateOffset(global_position)
	PositionChanged.emit(position)
#SCREEN SHAKE///////////////////////////////////
var shakestr = 0.0
func applyshake():
	shakestr = 2

var custom_time = 0.0
var time_scale = 1.0  # 1.0 for normal, 2.0 for 2x, etc.


func _physics_process(delta: float) -> void:
	if (!SimulationManager.IsPaused()):
		custom_time += delta * SimulationManager.SimSpeed()
		Cloud.material.set_shader_parameter("custom_time", custom_time)
		#Cloud2.material.set_shader_parameter("custom_time", custom_time + 500)
	
	if (FocusedShip != null):
		ForceCamPosition(FocusedShip.global_position)
	
	if shakestr > 0.0:
		shakestr = lerpf(shakestr, 0, 5.0 * delta)
		var of = RandomOffset()
		offset = of
	
	var rel : Vector2
	if (Input.is_action_pressed("MapDown")):
		rel.y -= 10
	if (Input.is_action_pressed("MapUp")):
		rel.y += 10
	if (Input.is_action_pressed("MapRight")):
		rel.x -= 10
	if (Input.is_action_pressed("MapLeft")):
		rel.x += 10
	if (Input.is_action_pressed("ZoomIn")):
		_HANDLE_ZOOM(1.1)
	if (Input.is_action_pressed("ZoomOut")):
		_HANDLE_ZOOM(0.9)
	
	if (rel != Vector2.ZERO):
		UpdateCameraPos(rel)
	
	if (!GridShowing):
		var light = WeatherManage.GetInstance().GetLightAmm()
		Cloud.material.set_shader_parameter("Light", light)
		Ground.material.set_shader_parameter("Light", light)
	
func RandomOffset()-> Vector2:
	return Vector2(randf_range(-shakestr, shakestr), randf_range(-shakestr, shakestr))
	
var prev: Vector2 = Vector2.ZERO

# Function to generate a random offset based on the previous offset.
func RandomOffset2() -> Vector2:
	var x = clamp(randf_range(prev.x - 0.1, prev.x + 0.1), -10, 10)
	var y = clamp(randf_range(prev.y - 0.1, prev.y + 0.1), -10, 10)
	
	prev = Vector2(x, y)
	return prev

var FrameTween : Tween

func ShowStation():
	FrameTween = create_tween()
	var stations = get_tree().get_nodes_in_group("CAPITAL")
	var stationpos
	for g : MapSpot in stations:
		if (g.GetSpotName() == "Dormak"):
			stationpos = g.global_position
			break
	FrameTween.set_trans(Tween.TRANS_EXPO)
	FrameTween.tween_property(self, "global_position", stationpos, 6)
	if (zoom.x > 1):
		_HANDLE_ZOOM(0.05)
	#var mattw = create_tween()
	#mattw.set_trans(Tween.TRANS_EXPO)
	#mattw.tween_property(GalaxyMat, "shader_parameter/thing", stationpos.x / 1800, 6)

func ShowArmak():
	FrameTween = create_tween()
	var stations = get_tree().get_nodes_in_group("CITY_CENTER")
	var stationpos
	for g : MapSpot in stations:
		if (g.GetSpotName() == "Armak"):
			stationpos = g.global_position
			break
	FrameTween.set_trans(Tween.TRANS_EXPO)
	FrameTween.tween_property(self, "global_position", stationpos, 6)
	if (zoom.x > 1):
		_HANDLE_ZOOM(0.05)

func FrameCamToPlayer():
	if (FrameTween != null):
		FrameTween.kill()
	if (FocusedShip != null):
		FocusedShip = null
	FrameTween = create_tween()
	var plpos = $"../PlayerShip".global_position
	FrameTween.set_trans(Tween.TRANS_QUAD)
	FrameTween.set_ease(Tween.EASE_OUT)
	FrameTween.tween_method(ForceCamPosition, global_position, plpos, 6)
	

func FrameCamToPos(pos : Vector2, OverrideTime : float = 1, Unzoom : bool = true) -> void:
	if (FrameTween != null):
		FrameTween.kill()
	if (FocusedShip != null):
		FocusedShip = null
	FrameTween = create_tween()
	FrameTween.set_trans(Tween.TRANS_QUAD)
	FrameTween.set_ease(Tween.EASE_OUT)
	FrameTween.tween_method(ForceCamPosition, global_position, pos, OverrideTime)
	
	if (Unzoom):
		ForceZoomOut()

func FrameCamToShip(Ship : PlayerDrivenShip, _OverrideTime : float = 1, Unzoom : bool = true) -> void:
	if (FrameTween != null):
		FrameTween.kill()
	#FrameTween = create_tween()
	#FrameTween.set_trans(Tween.TRANS_QUAD)
	#FrameTween.set_ease(Tween.EASE_OUT)
	#FrameTween.tween_method(ForceCamPosition, global_position, Ship.global_position, OverrideTime)
	FocusedShip = Ship
	#if (Unzoom):
		#ForceZoomOut()

func ForceCamPosition(Pos : Vector2) -> void:
	global_position = Pos
	Cloud.material.set_shader_parameter("offset", global_position / 1500)
	#$Clouds2.material.set_shader_parameter("offset", (global_position / 1500) + Vector2(500,500))
	#$Clouds2.material.set_shader_parameter("offset", global_position / 1500)
	Ground.material.set_shader_parameter("offset", global_position / 1500)
	PositionChanged.emit(position)
	Background.UpdateOffset(global_position)
