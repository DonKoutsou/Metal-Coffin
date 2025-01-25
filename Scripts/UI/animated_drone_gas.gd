extends AnimatedSprite2D

signal RangeChanged(NewVal : float)
signal RangeSnapedChaned(Dir : bool)

var framecount : int
var accumulatedrel : float

var DistanceTraveled = 0

func _ready() -> void:
	framecount = sprite_frames.get_frame_count("default")
	set_physics_process(false)

func _physics_process(_delta: float) -> void:
	DistanceTraveled += abs(accumulatedrel)
	accumulatedrel = lerp(accumulatedrel, 0.0, 0.2)
	#SteeringDitChanged.emit($TextureRect.rotation)
	if (abs(accumulatedrel) < 0.0001):
		set_physics_process(false)
		accumulatedrel = 0
		return
	RangeChanged.emit(accumulatedrel * 2)
	
	if (DistanceTraveled > 1):
		DistanceTraveled = 0
		
		$AudioStreamPlayer.play()
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
		
