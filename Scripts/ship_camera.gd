extends Camera2D

class_name ShipCamera

@export var Background : Control
@export var CityLines : MapLineDrawer

static var Instance : ShipCamera

signal ZoomChanged(NewVal : float)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
	$Clouds.material.set_shader_parameter("offset", global_position / 1500)
	$Ground.material.set_shader_parameter("offset", global_position / 1500)
	
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
	var newzoom = clamp(prevzoom * Vector2(zoomval, zoomval), Vector2(0.045,0.045), Vector2(5,5))
	#ZoomTw.tween_property(self, "zoom", newzoom, 1)
	ZoomTw.tween_method(UpdateZoom, zoom, newzoom, 1)
	prevzoom = newzoom
	ZoomTw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	call_deferred("OnZoomChanged", newzoom)
	

func UpdateZoom(Zoom : Vector2) -> void:
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
		zoom = clamp(start_zoom / zoom_factor, Vector2(0.045,0.045), Vector2(2.1,2.1))
		call_deferred("OnZoomChanged", zoom)
		_UpdateMapGridVisibility()
	else:
		UpdateCameraPos(event.relative)

func OnZoomChanged(NewZoom : Vector2) -> void:
	for g in get_tree().get_nodes_in_group("MapLines"):
		g.material.set_shader_parameter("line_width", lerp(0.01, 0.001, NewZoom.x / 2))
	get_tree().call_group("LineMarkers", "CamZoomUpdated", NewZoom.x)
	get_tree().call_group("ZoomAffected", "UpdateCameraZoom", NewZoom.x)
	ZoomChanged.emit(NewZoom.x)
	
var GridShowing = false
func _UpdateMapGridVisibility():
	if (zoom.x < 0.5 and !GridShowing):
		var mtw = create_tween()
		mtw.tween_property(CityLines, "modulate", Color(1,1,1,1), 0.5)
		#$"../MapLines".visible = true
		var tw = create_tween()
		tw.tween_property(Background, "modulate", Color(1,1,1,1), 0.5)
		GridShowing = true
	else: if (zoom.x >= 0.5 and GridShowing):
		var tw = create_tween()
		tw.tween_property(Background, "modulate", Color(1,1,1,0), 0.5)
		var mtw = create_tween()
		mtw.tween_property(CityLines, "modulate", Color(1,1,1,0), 0.5)
		GridShowing = false
	#$"../InScreenUI/Control3/Rulers/Panel3".material.set_shader_parameter("zoom", zoom.x * 2)
func UpdateCameraPos(relativeMovement : Vector2):
	if (FrameTween != null):
		FrameTween.kill()
	var maxposY = 999999
	var vpsizehalf = (get_viewport_rect().size.x / 2)
	var maxposX = Vector2(vpsizehalf - 11000, vpsizehalf + 11000)
	var rel = relativeMovement / zoom
	var newpos = Vector2(clamp(position.x - rel.x, maxposX.x, maxposX.y) ,clamp(position.y - rel.y, -maxposY,1000) )
	if (newpos.x != position.x):
		position.x = newpos.x
	if (newpos.y != position.y):
		position.y = newpos.y

	$Clouds.material.set_shader_parameter("offset", global_position / 1500)
	$Ground.material.set_shader_parameter("offset", global_position / 1500)
#SCREEN SHAKE///////////////////////////////////
var shakestr = 0.0
func applyshake():
	shakestr = 2

var custom_time = 0.0
var time_scale = 1.0  # 1.0 for normal, 2.0 for 2x, etc.


func _physics_process(delta: float) -> void:
	if (!SimulationManager.IsPaused()):
		custom_time += delta * SimulationManager.SimSpeed()
		$Clouds.material.set_shader_parameter("custom_time", custom_time)

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
	
func RandomOffset()-> Vector2:
	return Vector2(randf_range(-shakestr, shakestr), randf_range(-shakestr, shakestr))
var stattween : Tween

func ShowStation():
	stattween = create_tween()
	var stations = get_tree().get_nodes_in_group("CAPITAL")
	var stationpos
	for g : MapSpot in stations:
		if (g.GetSpotName() == "Dormak"):
			stationpos = g.global_position
			break
	stattween.set_trans(Tween.TRANS_EXPO)
	stattween.tween_property(self, "global_position", stationpos, 6)
	if (zoom.x > 1):
		_HANDLE_ZOOM(0.05)
	#var mattw = create_tween()
	#mattw.set_trans(Tween.TRANS_EXPO)
	#mattw.tween_property(GalaxyMat, "shader_parameter/thing", stationpos.x / 1800, 6)

func ShowArmak():
	stattween = create_tween()
	var stations = get_tree().get_nodes_in_group("CITY_CENTER")
	var stationpos
	for g : MapSpot in stations:
		if (g.GetSpotName() == "Armak"):
			stationpos = g.global_position
			break
	stattween.set_trans(Tween.TRANS_EXPO)
	stattween.tween_property(self, "global_position", stationpos, 6)
	if (zoom.x > 1):
		_HANDLE_ZOOM(0.05)
	#var mattw = create_tween()
	#mattw.set_trans(Tween.TRANS_EXPO)
	#mattw.tween_property(GalaxyMat, "shader_parameter/thing", stationpos.x / 1800, 6)

var FrameTween : Tween

func FrameCamToPlayer():
	if (stattween != null):
		stattween.kill()
	FrameTween = create_tween()
	var plpos = $"../PlayerShip".global_position
	FrameTween.set_trans(Tween.TRANS_QUAD)
	FrameTween.set_ease(Tween.EASE_OUT)
	FrameTween.tween_method(ForceCamPosition, global_position, plpos, 6)



func FrameCamToPos(pos : Vector2, OverrideTime : float = 1, Unzoom : bool = true) -> void:
	if (stattween != null):
		stattween.kill()
	FrameTween = create_tween()
	FrameTween.set_trans(Tween.TRANS_QUAD)
	FrameTween.set_ease(Tween.EASE_OUT)
	FrameTween.tween_method(ForceCamPosition, global_position, pos, OverrideTime)
	
	if (Unzoom and zoom.x > 1):
		_HANDLE_ZOOM(0.05)

func ForceCamPosition(Pos : Vector2) -> void:
	global_position = Pos
	$Clouds.material.set_shader_parameter("offset", global_position / 1500)
	#$Clouds2.material.set_shader_parameter("offset", global_position / 1500)
	$Ground.material.set_shader_parameter("offset", global_position / 1500)
