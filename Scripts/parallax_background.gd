@tool
extends ParallaxBackground

class_name TownBackground

@export var LimitTop : float
@export var LimitSide : float
@export var Animated : Array[AnimatedSprite2D]
@export var Camera : Camera2D

@export var Zoom : float = 1


@export var LocationPositions : Dictionary[Location, NodePath] = {
	Location.WORKSHOP : "",
	Location.FUEL : "",
	Location.MERCH : "",
}

signal PositionChanged

func UpdateCameraZoom(NewZoom : Vector2) -> void:
	Camera.zoom = NewZoom
	Camera.position.y = 360.0 * NewZoom.x
	print("UpdatedZoom")

func _ready() -> void:
	if (Engine.is_editor_hint()):
		return
	for g in Animated:
		g.play("default")
		
	Camera.zoom = Vector2(Zoom, Zoom)
	var vpsize = get_viewport().get_visible_rect().size.y
	Camera.position.y = vpsize - ((vpsize / Zoom)/2)

func Dissable() -> void:
	for g in get_children():
		if g is ParallaxLayer:
			g.motion_scale = Vector2(1,1)

func GetLocationForPosition(Loc : Location) -> Vector2:
	return get_node(LocationPositions[Loc]).global_position

func GetNodeForPosition(Loc : Location) -> Node2D:
	return get_node(LocationPositions[Loc])

func _physics_process(_delta: float) -> void:
	if (Engine.is_editor_hint()):
		Camera.zoom = Vector2(Zoom, Zoom)
		var vpsize = ProjectSettings.get_setting("display/window/size/viewport_height")
		Camera.position.y = vpsize - ((vpsize / Zoom)/2)
		#print("UpdatedZoom")
		return
	var midpoint = get_viewport().get_visible_rect().size / 2
	var Mousepos = get_viewport().get_mouse_position()
	var NewX = clamp(Mousepos.x, LimitSide, LimitSide + midpoint.x)
	var NewY = clamp(Mousepos.y, -LimitTop + midpoint.y, midpoint.y + 50)
	#if ($Camera2D.global_position != Vector2(NewX, NewY)):
	PositionChanged.emit()
		
	$Camera2D.position = Vector2(NewX, NewY)

enum Location {
	WORKSHOP,
	FUEL,
	MERCH,
	REPAIR,
}
