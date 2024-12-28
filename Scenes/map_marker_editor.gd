extends Control

@export var LineColor : Color

var Line : Line2D

var ExistingLines : Array[Line2D]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var size = $Panel.size / 2
	$Panel.global_position = Vector2($XLine.global_position.x - size.x, $YLine.global_position.y - size.y)


func _on_x_wheel_steering_offseted(Offset: float) -> void:
	$XLine.global_position.x = clamp($XLine.global_position.x + Offset, 0, get_viewport_rect().size.x)
	if (Line != null):
		UpdateLine()
func _on_y_wheel_steering_offseted(Offset: float) -> void:
	$YLine.global_position.y = clamp($YLine.global_position.y + Offset, 0, get_viewport_rect().size.y)
	if (Line != null):
		UpdateLine()

func UpdateLine() -> void:
	Line.set_point_position(1, ($Panel.global_position + ($Panel.size / 2)) - Line.global_position )
	Line.get_child(0).text = var_to_str(roundi(Vector2(0,0).distance_to(Line.get_point_position(1))))
	Line.get_child(0).position = (Line.get_point_position(1) / 2) - (Line.get_child(0).size / 2)
func _on_drone_button_pressed() -> void:
	if (Line == null):
		Line = Line2D.new()
		Line.width = 2
		Line.default_color = LineColor
		$Lines.add_child(Line)
		Line.global_position = $Panel.global_position + ($Panel.size / 2)
		Line.add_point(Vector2(0,0))
		Line.add_point(Vector2(0,0))
		var text = Label.new()
		Line.add_child(text)
		text.text = var_to_str(0)
	else:
		ExistingLines.append(Line)
		Line = null


func _on_y_gas_range_changed(NewVal: float) -> void:
	$YLine.global_position.y = clamp($YLine.global_position.y + NewVal * 5, 0, get_viewport_rect().size.y)
	if (Line != null):
		UpdateLine()


func _on_x_gas_range_changed(NewVal: float) -> void:
	$XLine.global_position.x = clamp($XLine.global_position.x + NewVal * 5, 0, get_viewport_rect().size.x)
	if (Line != null):
		UpdateLine()
