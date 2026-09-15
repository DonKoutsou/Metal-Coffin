extends Node2D

class_name Chain

var chainLinks : Array[Node2D]


var StartingPos : Vector2
@export var frequency: float = 1.0  # Wiggle speed
@export var phase_offset: float = 0.0  # Phase offset for randomness
@export var max_rotation: float = 0.1  # Maximum angle in radians for rotation
@export var Line : Line2D
@export var shadowLine : Line2D
@export var UIm : UIEventHandler
var streched : bool = false
var attached : bool = false

func _ready() -> void:
	phase_offset = randf_range(0.0, TAU)
	
	for g in get_children():
		if (g is PinJoint2D):
			continue
		if(g is RigidBody2D):
			var c : Control = g.get_child(1)
			c.gui_input.connect(_on_control_3_gui_input.bind(g))
			
		Line.add_point(g.position)
		shadowLine.add_point(g.position)
		chainLinks.append(g)
		
	#chainLinks.append_array(FindLinks(self))

func _physics_process(delta: float) -> void:
	var time = Time.get_ticks_msec() / 1000.0

	var rotation_angle = max_rotation * sin(frequency * 1.2 * time + phase_offset)  # Slightly different frequency

	max_rotation = max(max_rotation - delta / 60, 0.003)
	rotation = rotation_angle

	if (attached):
		var shape = $RigidBody2D4
		if (shape is RigidBody2D):
			if (shape.position.y < 230):
				shape.linear_velocity = shape.global_position.direction_to(get_global_mouse_position()) * 300
				if (shape.position.y > 220 and !streched):
					streched = true
					$PinJoint2D/AudioStreamPlayer2D.play()
					UIm.OnLightToggled()
				
	for g in chainLinks.size():
		var pos = chainLinks[g].position
		Line.set_point_position(g, pos)
		shadowLine.set_point_position(g, pos)

func FindLinks(origin : Node2D) -> Array[Node2D]:
	var links : Array[Node2D] = [origin]
	for g in origin.get_children():
		links.append_array(FindLinks(g))
	return links

func ApplyShake(amm : float = 1) -> void:
	max_rotation = max(max_rotation, 0.04 * amm)

func _on_control_3_gui_input(event: InputEvent, shape : RigidBody2D) -> void:
	if (event.is_action_pressed("Click")):
		attached = true
		
	if (event.is_action_released("Click")):
		attached = false
		if (streched):
			streched = false
			$PinJoint2D/AudioStreamPlayer2D2.play()
			
