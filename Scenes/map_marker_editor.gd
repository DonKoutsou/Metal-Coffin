extends Control

class_name MapMarkerEditor

@export var LineScene : PackedScene

var Line : MapMarkerLine
var LineLeangth : float = 0

@onready var ship_camera: ShipCamera = $"../../../ShipCamera"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	#global_position = get_parent().global_position - (get_viewport_rect().size/2)
	var size = $Panel.size / 2
	$Panel.position = Vector2($XLine.position.x - size.x, $YLine.position.y - size.y)
	if (Line != null):
		Line.UpdateLine(($Panel.global_position + ($Panel.size / 2)) - Line.position, ship_camera.zoom.x)

func _on_drone_button_pressed() -> void:
	if (Line == null):
		Line = LineScene.instantiate() as MapMarkerLine
		add_child(Line)
		Line.global_position = $Panel.global_position + ($Panel.size / 2)
		Line.add_point(Vector2(0,0))
		Line.add_point(Vector2(0,0))
		LineLeangth = 0
	else:
		var pos = Line.position - (get_viewport_rect().size / 2)
		remove_child(Line)
		$"../../../MapPointerManager".add_child(Line)
		Line.add_to_group("LineMarkers")
		Line.CamZoomUpdated(ship_camera.zoom.x)
		Line.global_position = ship_camera.global_position + (pos / ship_camera.zoom)
		Line.set_point_position(1, Line.get_point_position(1) / ship_camera.zoom)
		Line.get_child(0).position = (Line.get_point_position(1) / 2) - (Line.get_child(0).size / 2)
		Line = null


func _on_y_gas_range_changed(NewVal: float) -> void:
	$YLine.global_position.y = clamp($YLine.global_position.y + NewVal * 5, 0, get_viewport_rect().size.y)


func _on_x_gas_range_changed(NewVal: float) -> void:
	$XLine.global_position.x = clamp($XLine.global_position.x + NewVal * 5, 0, get_viewport_rect().size.x)
