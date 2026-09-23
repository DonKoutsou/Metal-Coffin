extends TextureRect

class_name OutScreenCursor

@export_file("*.png") var NormalPointer : String

enum MouseMode {
	NORMAL,
	DIRECTIONAL
}

static var Instance : OutScreenCursor

func _ready() -> void:
	Instance = self
	OutScreenCursor.Instance.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()
