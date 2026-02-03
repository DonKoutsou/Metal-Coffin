extends AnimatedSprite2D

class_name Dial

@export var Sound : AudioStreamPlayer

signal RangeChanged(NewVal : float)
signal RangeSnapedChaned(Dir : bool)

var framecount : int
var accumulatedrel : float
var CustomAccumulated : float

var DistanceTraveled = 0

func _ready() -> void:
	framecount = sprite_frames.get_frame_count("default")
	set_physics_process(false)
	Sound.pitch_scale = randf_range(0.8, 1.2)

func _physics_process(_delta: float) -> void:
	if (accumulatedrel == 0 and CustomAccumulated == 0):
		set_physics_process(false)
	
	DistanceTraveled += abs(accumulatedrel)
	accumulatedrel = lerp(accumulatedrel, 0.0, 0.2)
	#SteeringDitChanged.emit($TextureRect.rotation)
	if (abs(accumulatedrel) < 0.0001):
		#set_physics_process(false)
		accumulatedrel = 0
	else:
		RangeChanged.emit(accumulatedrel * 2)
		
		if (DistanceTraveled > 1):
			DistanceTraveled = 0
			
			Sound.play()
			Input.vibrate_handheld(30)
			if (accumulatedrel > 0):
				RangeSnapedChaned.emit(true)
				if (frame + 1 == framecount):
					frame = 0
				else:
					frame += 1
			else: if (accumulatedrel < 0):
				RangeSnapedChaned.emit(false)
				if (frame == 0):
					frame = framecount - 1
				else:
					frame -= 1
					
	DistanceTraveled += abs(CustomAccumulated)
	CustomAccumulated = lerp(CustomAccumulated, 0.0, 0.2)
	#SteeringDitChanged.emit($TextureRect.rotation)
	if (abs(CustomAccumulated) < 0.0001):
		#set_physics_process(false)
		CustomAccumulated = 0
	else:
		if (DistanceTraveled > 1):
			DistanceTraveled = 0
			
			Sound.play()
			Input.vibrate_handheld(30)
			if (CustomAccumulated > 0):
				if (frame + 1 == framecount):
					frame = 0
				else:
					frame += 1
			else: if (CustomAccumulated < 0):
				if (frame == 0):
					frame = framecount - 1
				else:
					frame -= 1

func AddCustomMovement(value : float) -> void:
	CustomAccumulated += value
	set_physics_process(true)

func _on_control_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		var rel = clamp(event.relative / 100, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
		#var rel = event.relative
		accumulatedrel += rel.x
		set_physics_process(true)
	if (event is InputEventScreenDrag):
		var rel = clamp(event.relative / 100, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
		accumulatedrel += rel.x
		set_physics_process(true)
	if (event.is_action_pressed("ZoomOut")):
		accumulatedrel += 0.4
		set_physics_process(true)
	if (event.is_action_pressed("ZoomIn")):
		accumulatedrel -= 0.4
		set_physics_process(true)
		
