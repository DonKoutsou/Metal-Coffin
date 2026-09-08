extends TextureRect

class_name OutScreenCursor

@export_file("*.png") var NormalPointer : String

enum MouseMode {
	NORMAL,
	DIRECTIONAL
}

#var CurrentMode : MouseMode

static var Instance : OutScreenCursor

func _ready() -> void:
	Instance = self
	OutScreenCursor.Instance.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#var vp = get_tree().root.size
	#var dif = vp - get_window().size
	#var mPos = get_global_mouse_position() * (Vector2(get_window().size) / Vector2(1280.0, 720.0))
	#
	#var mPos2 = get_global_mouse_position() * (Vector2(vp) / Vector2(1280, 720))
	
	
	
	#var Local = Helper.mapv2(get_global_mouse_position(), Vector2.ZERO, get_window().size, Vector2.ZERO, Vector2(1280, 720))
	var mpos = get_global_mouse_position()
	#print(mpos)
	var Local = get_global_mouse_position()
	#print(vp)
	var MouseInScreen = Local.x > 0 and Local.y > 0 and Local.x < get_viewport_rect().size.x and Local.y < get_viewport_rect().size.y
	global_position = get_global_mouse_position()
	
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

#func MouseOut() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#
	#
#func MouseIn() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
