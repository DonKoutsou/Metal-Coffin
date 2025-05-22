extends ParallaxBackground

class_name TownBackground

@export var LimitTop : float
@export var LimitSide : float

@export var LocationPositions : Dictionary[Location, NodePath] = {
	Location.WORKSHOP : "",
	Location.FUEL : "",
	Location.MERCH : "",
}

signal PositionChanged

func GetLocationForPosition(Loc : Location) -> Vector2:
	return get_node(LocationPositions[Loc]).global_position

func _physics_process(delta: float) -> void:
	var midpoint = get_viewport().get_visible_rect().size / 2
	var Mousepos = get_viewport().get_mouse_position()
	var NewX = clamp(Mousepos.x, -LimitSide + midpoint.x, LimitSide + midpoint.x)
	var NewY = clamp(Mousepos.y, -LimitTop + midpoint.y, midpoint.y + 50)
	#if ($Camera2D.global_position != Vector2(NewX, NewY)):
	PositionChanged.emit()
		
	$Camera2D.global_position = Vector2(NewX, NewY)

enum Location {
	WORKSHOP,
	FUEL,
	MERCH,
}
