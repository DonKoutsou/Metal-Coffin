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
	set_process(t)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#var vp = get_tree().root.size
	#var dif = vp - get_window().size
	#var mPos = get_global_mouse_position() * (Vector2(get_window().size) / Vector2(1280.0, 720.0))
	#
	#var mPos2 = get_global_mouse_position() * (Vector2(vp) / Vector2(1280, 720))
	
	
	
	#var Local = Helper.mapv2(get_global_mouse_position(), Vector2.ZERO, get_window().size, Vector2.ZERO, Vector2(1280, 720))
	var Local = get_global_mouse_position() - get_viewport().canvas_transform.origin
	#print(vp)
	var MouseInScreen = Local.x > 0 and Local.y > 0 and Local.x < get_viewport_rect().size.x and Local.y < get_viewport_rect().size.y
	if (MouseInScreen):
		global_position = get_global_mouse_position()
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
	
