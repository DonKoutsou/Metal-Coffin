extends TextureRect

class_name InScreenCursor

@export_file("*.png") var NormalPointer : String
@export_file("*.png") var DirectionalPointer : String

enum MouseMode {
	NORMAL,
	DIRECTIONAL
}

var CurrentMode : MouseMode

static var Instance : InScreenCursor

func _ready() -> void:
	Instance = self

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

func ToggleMouse(t : bool) -> void:
	set_physics_process(t)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:

	var mousepos = get_viewport().get_mouse_position()
	var Local = mousepos - get_viewport().canvas_transform.origin
	var MouseInScreen = Local.x > 0 and Local.y > 0 and Local.x < get_viewport_rect().size.x and Local.y < get_viewport_rect().size.y
	if (MouseInScreen):
		global_position = mousepos
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
	
