extends Camera2D

class_name ShipCamera

static var Instance : ShipCamera
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self

static func GetInstance() -> ShipCamera:
	return Instance

#////////////////////////////
func _HANDLE_ZOOM(zoomval : float):
	var prevzoom = zoom
	zoom = clamp(prevzoom * Vector2(zoomval, zoomval), Vector2(0.07,0.07), Vector2(2.1,2.1))
	#for g in get_tree().get_nodes_in_group("MapShipVizualiser"):
		#g.visible = zoom < Vector2(1, 1)
	for g in get_tree().get_nodes_in_group("MapLines"):
		g.material.set_shader_parameter("line_width", lerp(0.02, 0.001, zoom.x / 2))
	get_tree().call_group("LineMarkers", "CamZoomUpdated", zoom.x)
	get_tree().call_group("Ships", "UpdateCameraZoom", zoom.x)
	_UpdateMapGridVisibility()
	#$Screen.scale = zoom / 2
	#for g in get_tree().get_nodes_in_group("DissapearingMap"):
		#g.modulate.a = mod
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
		zoom = clamp(start_zoom / zoom_factor, Vector2(0.1,0.1), Vector2(2.1,2.1))
		for g in get_tree().get_nodes_in_group("MapLines"):
			g.material.set_shader_parameter("line_width", lerp(0.01, 0.001, zoom.x / 2))
		get_tree().call_group("LineMarkers", "CamZoomUpdated", zoom.x)
		get_tree().call_group("Ships", "UpdateCameraZoom", zoom.x)
		_UpdateMapGridVisibility()
	else:
		UpdateCameraPos(event.relative)
		
func _UpdateMapGridVisibility():
	if (zoom.x < 0.25):
		var mtw = create_tween()
		mtw.tween_property($"../MapPointerManager/MapLineDrawer", "modulate", Color(1,1,1,1), 0.5)
		#$"../MapLines".visible = true
		var tw = create_tween()
		tw.tween_property($"../InScreenUI/Control3/DarkBlueBackground", "modulate", Color(1,1,1,1), 0.5)
	else:
		var tw = create_tween()
		tw.tween_property($"../InScreenUI/Control3/DarkBlueBackground", "modulate", Color(1,1,1,0), 0.5)
		var mtw = create_tween()
		mtw.tween_property($"../MapPointerManager/MapLineDrawer", "modulate", Color(1,1,1,0), 0.5)
	#$"../InScreenUI/Control3/Rulers/Panel3".material.set_shader_parameter("zoom", zoom.x * 2)

func UpdateCameraPos(relativeMovement : Vector2):
	var maxposY = 999999
	var vpsizehalf = (get_viewport_rect().size.x / 2)
	var maxposX = Vector2(vpsizehalf - 6000, vpsizehalf + 6000)
	var rel = relativeMovement / zoom
	var newpos = Vector2(clamp(position.x - rel.x, maxposX.x, maxposX.y) ,clamp(position.y - rel.y, -maxposY,300) )
	if (newpos.x != position.x):
		#$CanvasLayer/SubViewportContainer/SubViewport/Control2.position.x = newpos.x - ($CanvasLayer/SubViewportContainer/SubViewport/Control2.size.x /2)
		position.x = newpos.x
		#var val = GalaxyMat.get_shader_parameter("thing")
		#GalaxyMat.set_shader_parameter("thing", val - (rel.x / 1800))
	if (newpos.y != position.y):
		
		position.y = newpos.y
		#var val2 = GalaxyMat.get_shader_parameter("thing2")
		#GalaxyMat.set_shader_parameter("thing2", val2 - (rel.y / 1800))
	#$"../InScreenUI/Control3/Rulers/Panel3".material.set_shader_parameter("pan_offset", position * zoom)
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
	var stations = get_tree().get_nodes_in_group("CITY_CENTER")
	var stationpos = stations[stations.size()-1].global_position
	stattween.set_trans(Tween.TRANS_EXPO)
	stattween.tween_property(self, "global_position", stationpos, 6)
	#var mattw = create_tween()
	#mattw.set_trans(Tween.TRANS_EXPO)
	#mattw.tween_property(GalaxyMat, "shader_parameter/thing", stationpos.x / 1800, 6)
	
func FrameCamToPlayer():
	if (stattween != null):
		stattween.kill()
	var tw = create_tween()
	var plpos = $"../PlayerShip".global_position
	tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "global_position", plpos, plpos.distance_to(global_position) / 1000)
