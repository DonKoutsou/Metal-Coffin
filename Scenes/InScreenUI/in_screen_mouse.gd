extends TextureRect

class_name InScreenCursor

@export_file("*.png") var NormalPointer : String
@export_file("*.png") var DirectionalPointer : String

enum MouseMode {
	NORMAL,
	DIRECTIONAL
}

var CurrentMode : MouseMode

func SwitchMouse(Mode : MouseMode) -> void:
	if (Mode == CurrentMode):
		return
	match (Mode):
		MouseMode.NORMAL:
			CurrentMode = MouseMode.NORMAL
			texture = ResourceLoader.load(NormalPointer)
		MouseMode.DIRECTIONAL:
			CurrentMode = MouseMode.DIRECTIONAL
			texture = ResourceLoader.load(DirectionalPointer)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:

	var mousepos = get_global_mouse_position()
	var Local = mousepos - get_viewport().global_canvas_transform.origin
	var MouseInScreen = Local.x > 0 and Local.y > 0 and Local.x < get_viewport_rect().size.x and Local.y < get_viewport_rect().size.y
	if (MouseInScreen):
		position = mousepos
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		#print("mouse hidden " + var_to_str(Time.get_ticks_msec()))
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

#func MouseOut() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#
	#
#func MouseIn() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
