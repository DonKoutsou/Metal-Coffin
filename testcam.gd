extends Camera2D

var Mat : ShaderMaterial

func _ready() -> void:
	Mat = $"..".material

func _physics_process(delta: float) -> void:
	Mat.set_shader_parameter("camera_position", global_position)
	var zoom_factor = (zoom.x + zoom.y) / 2.0
	Mat.set_shader_parameter("zoom", zoom_factor)
func _process(delta: float) -> void:
	if (Input.is_action_pressed("MapDown")):
		position.y += 10 / zoom.x
	if (Input.is_action_pressed("MapUp")):
		position.y -= 10 / zoom.x
	if (Input.is_action_pressed("MapRight")):
		position.x += 10 / zoom.x
	if (Input.is_action_pressed("MapLeft")):
		position.x -= 10 / zoom.x
	if (Input.is_action_just_pressed("ZoomIn")):
		zoom *= Vector2(1.1, 1.1)
	if (Input.is_action_just_pressed("ZoomOut")):
		zoom *= Vector2(0.9, 0.9)
