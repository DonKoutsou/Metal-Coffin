@tool
extends ScrollContainer

class_name InputScroll

@export var XLock : bool = false
@export var YLock : bool = false
@export var Momentum : bool = false

var force : Vector2
var pos : Vector2

func _ready() -> void:
	gui_input.connect(HandleInput)
	pos = Vector2(scroll_horizontal, scroll_vertical)
	visibility_changed.connect(OnVisChanged)

func OnVisChanged() -> void:
	set_process(is_visible_in_tree())

func _process(delta: float) -> void:
	var maxPos : Vector2 = Vector2.ZERO
	
	if (get_child_count() > 0):
		maxPos = abs(get_child(0).size - size)
		#print(maxPos)
		var appliedForce = force * delta * 10
		pos = pos + appliedForce
		pos = Vector2(clamp(pos.x, 0, maxPos.x), clamp(pos.y, 0, maxPos.y + 50))
		
	scroll_vertical = roundi(pos.y)
	scroll_horizontal = roundi(pos.x)
	
	if (pos.y == 0 or pos.y == maxPos.y):
		force.y = 0
		
	if (pos.x == 0 or pos.x == maxPos.x):
		force.x = 0

	force = force.move_toward(Vector2.ZERO, delta * 20)

func HandleInput(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		if (!XLock):
			if(Momentum):
				if (signf(force.x) == signf(event.relative.x)):
					force.x = 0
				force.x =  clamp(force.x -event.relative.x, event.relative.x * 6, -event.relative.x * 6)
			else:
				pos.x -= event.relative.x
			
		if (!YLock):
			if(Momentum):
				if (signf(force.y) == signf(event.relative.y)):
					force.y = 0
				
				force.y =  clamp(force.y -event.relative.y, event.relative.y * 6, -event.relative.y * 6)
			else:
				pos.y -= event.relative.y
			#force.y = -event.relative.y * 6
	
	else: if (event.is_action_pressed("ZoomIn")):
		if (!YLock):
			if(Momentum):
				if (signf(force.y) == 1):
					force.y = 0
				force.y -= 20
			else:
				pos.y -= 40
	
	else: if (event.is_action_pressed("ZoomOut")):
		if (!YLock):
			if(Momentum):
				if (signf(force.y) == -1):
					force.y = 0
				force.y -= -20
			else:
				pos.y += 40
	
	else : if (event is InputEventScreenDrag and Input.is_action_pressed("Click")):
		if (!XLock):
			if(Momentum):
				if (signf(force.x) == signf(event.relative.x)):
					force.x = 0
				force.x =  clamp(force.x -event.relative.x, event.relative.x * 6, -event.relative.x * 6)
			else:
				pos.x -= event.relative.x
			
		if (!YLock):
			if(Momentum):
				if (signf(force.y) == signf(event.relative.y)):
					force.y = 0
				force.y =  clamp(force.y -event.relative.y, event.relative.y * 6, -event.relative.y * 6)
			else:
				pos.y -= event.relative.y
			
	else: if  Input.is_action_pressed("Click"):
		force = Vector2.ZERO
