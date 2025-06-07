extends ScrollContainer

class_name InputScroll

@export var XLock : bool = false
@export var YLock : bool = false

func _ready() -> void:
	gui_input.connect(HandleInput)
	
func HandleInput(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		if (!XLock):
			scroll_horizontal -= event.relative.x
		if (!YLock):
			scroll_vertical -= event.relative.y
	else : if (event is InputEventScreenDrag and Input.is_action_pressed("Click")):
		if (!XLock):
			scroll_horizontal -= event.relative.x
		if (!YLock):
			scroll_vertical -= event.relative.y
