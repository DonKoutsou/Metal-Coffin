extends Camera2D

class_name ShipCamera

@export var Background : Control
@export var CityLines : MapLineDrawer

static var Instance : ShipCamera

signal ZoomChanged(NewVal : float)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self

static func GetInstance() -> ShipCamera:
	return Instance

#////////////////////////////
func _HANDLE_ZOOM(zoomval : float):
	var prevzoom = zoom
	zoom = clamp(prevzoom * Vector2(zoomval, zoomval), Vector2(0.045,0.045), Vector2(10,10))
	call_deferred("OnZoomChanged")
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
		call_deferred("OnZoomChanged")
		_UpdateMapGridVisibility()
	else:
		UpdateCameraPos(event.relative)

func OnZoomChanged() -> void:
	for g in get_tree().get_nodes_in_group("MapLines"):
		g.material.set_shader_parameter("line_width", lerp(0.01, 0.001, zoom.x / 2))
	get_tree().call_group("LineMarkers", "CamZoomUpdated", zoom.x)
	get_tree().call_group("ZoomAffected", "UpdateCameraZoom", zoom.x)
	ZoomChanged.emit(zoom.x)
	
var GridShowing = false
func _UpdateMapGridVisibility():
	if (zoom.x < 1 and !GridShowing):
		var mtw = create_tween()
		mtw.tween_property(CityLines, "modulate", Color(1,1,1,1), 0.5)
		#$"../MapLines".visible = true
		var tw = create_tween()
		tw.tween_property(Background, "modulate", Color(1,1,1,1), 0.5)
		GridShowing = true
	else: if (zoom.x >= 1 and GridShowing):
		var tw = create_tween()
		tw.tween_property(Background, "modulate", Color(1,1,1,0), 0.5)
		var mtw = create_tween()
		mtw.tween_property(CityLines, "modulate", Color(1,1,1,0), 0.5)
		GridShowing = false
	#$"../InScreenUI/Control3/Rulers/Panel3".material.set_shader_parameter("zoom", zoom.x * 2)
func UpdateCameraPos(relativeMovement : Vector2):
	if (FrameTween.is_valid()):
		FrameTween.kill()
	var maxposY = 999999
	var vpsizehalf = (get_viewport_rect().size.x / 2)
	var maxposX = Vector2(vpsizehalf - 6000, vpsizehalf + 6000)
	var rel = relativeMovement / zoom
	var newpos = Vector2(clamp(position.x - rel.x, maxposX.x, maxposX.y) ,clamp(position.y - rel.y, -maxposY,300) )
	if (newpos.x != position.x):
		position.x = newpos.x
	if (newpos.y != position.y):
		
		position.y = newpos.y
#SCREEN SHAKE///////////////////////////////////
var shakestr = 0.0
func applyshake():
	shakestr = 2

func _physics_process(delta: float) -> void:
	if shakestr > 0.0:
		shakestr = lerpf(shakestr, 0, 5.0 * delta)
		var of = RandomOffset()
		offset = of
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
	#var mattw = create_tween()
	#mattw.set_trans(Tween.TRANS_EXPO)
	#mattw.tween_property(GalaxyMat, "shader_parameter/thing", stationpos.x / 1800, 6)

var FrameTween : Tween

func FrameCamToPlayer():
	if (stattween != null):
		stattween.kill()
	FrameTween = create_tween()
	var plpos = $"../PlayerShip".global_position
	FrameTween.set_trans(Tween.TRANS_EXPO)
	FrameTween.tween_property(self, "global_position", plpos, 6)

func FrameCamToPos(pos : Vector2) -> void:
	if (stattween != null):
		stattween.kill()
	FrameTween = create_tween()
	FrameTween.set_trans(Tween.TRANS_EXPO)
	FrameTween.tween_property(self, "global_position", pos, 2)
