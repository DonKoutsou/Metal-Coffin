extends Camera2D

class_name ShipCamera

@export var Background : Control
@export var Grid : MapGrid
@export var Cloud : Control
@export var Ground : Control
@export var WeatherMan : WeatherManage
@export var MinZoom : float = 0.1
@export var MaxZoom : float = 3.0
@export var ClickSound : AudioStreamPlayer

static var Instance : ShipCamera
static var WorldBounds : Vector2

signal ZoomChanged(NewVal : float)
signal PositionChanged(NewVal : Vector2)

var CloudMat : ShaderMaterial
var GroundMat : ShaderMaterial

var FocusedShip : PlayerDrivenShip
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
	
	CloudMat = Cloud.material
	GroundMat = Ground.material
	
	CloudMat.set_shader_parameter("Camera_Offset", global_position / 1500)
	GroundMat.set_shader_parameter("offset", global_position / 1500)
	
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
	ZoomTw.tween_method(UpdateZoom, zoom, Vector2(MinZoom, MinZoom), 1)
	prevzoom = Vector2(MinZoom, MinZoom)

func UpdateZoom(Zoom : Vector2) -> void:
	zoom = Zoom
	for g in get_tree().get_nodes_in_group("MapLines"):
		g.material.set_shader_parameter("line_width", lerp(0.01, 0.001, Zoom.x / 2))
	get_tree().call_group("ZoomAffected", "UpdateCameraZoom", Zoom.x)
	ZoomChanged.emit(Zoom.x)
	_UpdateMapGridVisibility()
	UpdateCameraPos(Vector2.ZERO)

func ForceZoom(Zoom : Vector2) -> void:
	prevzoom = Zoom
	zoom = Zoom
	for g in get_tree().get_nodes_in_group("MapLines"):
		g.material.set_shader_parameter("line_width", lerp(0.01, 0.001, Zoom.x / 2))
	get_tree().call_group("ZoomAffected", "UpdateCameraZoom", Zoom.x)
	ZoomChanged.emit(Zoom.x)
	_UpdateMapGridVisibility()
	
#////////////////////////////
#PHONE TOUCH INPUT HANDLING
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
#////////////////////////////
var CloudShowing = true
var GridShowing = false

var MapGridTween : Tween
var WeatherTween : Tween
var GridTween : Tween

func _UpdateMapGridVisibility():
	if (zoom.x < 1.5 and !GridShowing):
		if (is_instance_valid(MapGridTween)):
			MapGridTween.kill()
		if (is_instance_valid(WeatherTween)):
			WeatherTween.kill()
		if (is_instance_valid(GridTween)):
			GridTween.kill()
			
		MapGridTween = create_tween()
		MapGridTween.tween_property(Background, "modulate", Color(1,1,1,1), 0.5)
		WeatherTween = create_tween()
		WeatherTween.tween_property(WeatherMan, "modulate", Color(1,1,1,1), 0.5)
		GridTween = create_tween()
		GridTween.tween_property(Grid, "modulate", Color(1,1,1,1), 0.5)
		
		MapGridTween.finished.connect(Cloud.hide)
		MapGridTween.finished.connect(Ground.hide)
		
		GridShowing = true

	else: if (zoom.x >= 1.5):
		Cloud.visible = zoom.x < 8.0
		if (GridShowing):
			if (is_instance_valid(MapGridTween)):
				MapGridTween.kill()
			if (is_instance_valid(WeatherTween)):
				WeatherTween.kill()
			if (is_instance_valid(GridTween)):
				GridTween.kill()
			
			Ground.show()
			MapGridTween = create_tween()
			MapGridTween.tween_property(Background, "modulate", Color(1,1,1,0), 0.5)
			WeatherTween = create_tween()
			WeatherTween.tween_property(WeatherMan, "modulate", Color(1,1,1,0), 0.5)
			GridTween = create_tween()
			GridTween.tween_property(Grid, "modulate", Color(1,1,1,0), 0.5)

			GridShowing = false

func UpdateCameraPos(relativeMovement : Vector2):
	if (FrameTween != null):
		FrameTween.kill()

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

	CloudMat.set_shader_parameter("Camera_Offset", global_position / 1500)
	GroundMat.set_shader_parameter("offset", global_position / 1500)
	Grid.UpdateOffset(global_position)
	PositionChanged.emit(position)

#var CloudTime = 0.0
var CloudOffset = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if (!SimulationManager.IsPaused()):
		#CloudTime += delta * SimulationManager.SimSpeed()
		#CloudMat.set_shader_parameter("custom_time", CloudTime)
		CloudOffset += WeatherMan.WindDirection * (SimulationManager.SimSpeed() / 10000)
		CloudMat.set_shader_parameter("Offset", CloudOffset)
	
	if (FocusedShip != null):
		ForceCamPosition(FocusedShip.global_position)
	
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
		var light = WeatherManage.GetLightAmm()
		CloudMat.set_shader_parameter("Light", light)
		GroundMat.set_shader_parameter("Light", light)

var FrameTween : Tween

func FrameCamToPlayer():
	var plpos = $"../PlayerShip".global_position
	FrameCamToPos(plpos, 6, false)

func FrameCamToPos(pos : Vector2, OverrideTime : float = 1, Unzoom : bool = true) -> void:
	if (FrameTween != null):
		FrameTween.kill()

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

	FocusedShip = Ship


func ForceCamPosition(Pos : Vector2) -> void:
	global_position = Pos
	CloudMat.set_shader_parameter("Camera_Offset", global_position / 1500)
	GroundMat.set_shader_parameter("offset", global_position / 1500)
	PositionChanged.emit(position)
	Grid.UpdateOffset(global_position)
