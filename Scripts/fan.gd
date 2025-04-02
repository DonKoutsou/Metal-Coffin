extends AnimatedSprite2D

class_name Fan


var StartingScale :Vector2

@export var frequency: float = 1.0  # Wiggle speed
@export var phase_offset: float = 0.0  # Phase offset for randomness
@export var max_rotation: float = 0.1  # Maximum angle in radians for rotation
@export var max_scale_x: float = 1  # Maximum angle in radians for rotation

@export var BluredSpriteFrames : SpriteFrames
@export var NonBluredSpriteFrames : SpriteFrames

var On = true

func _ready() -> void:
	play()
	get_child(0).play()

	StartingScale = scale
	phase_offset = randf_range(0.0, TAU)
	#PosToGo = position

func ApplyShake(amm : float = 1) -> void:
	max_rotation = max(max_rotation, 0.03 * amm)
	max_scale_x = max(max_scale_x, 0.01 * amm)

func _physics_process(delta: float) -> void:
	var time = Time.get_ticks_msec() / 1000.0

	# Calculate position offset using sine for smooth back-and-forth motion
	#var y_offset = 0 * sin(frequency * time + phase_offset)
	
	# Calculate a subtle rotation based on the sine wave
	var rotation_angle = max_rotation * sin(frequency * 1.2 * time + phase_offset)  # Slightly different frequency
	
	# Calculate scaling transformation for x-axis
	var scale_x = 1.0 + max_scale_x * sin(frequency * 1.8 * time + phase_offset + 0.5)
	
	#amplitude = max(amplitude - delta, 0)
	#print("amp :" + var_to_str(amplitude))
	max_rotation = max(max_rotation - delta / 60, 0.003)
	max_scale_x = max(max_scale_x - delta / 60, 0.001)
	#print("frequency :" + var_to_str(frequency))
	# Update transformations

	rotation = rotation_angle
	scale.x = StartingScale.x * scale_x

var OnOffTween : Tween

func _on_control_gui_input(event: InputEvent) -> void:
	if (event.is_action_pressed("Click")):
		if (is_instance_valid(OnOffTween)):
			OnOffTween.kill()
		
		OnOffTween = create_tween()
		OnOffTween.set_ease(Tween.EASE_OUT)
		OnOffTween.set_trans(Tween.TRANS_QUAD)
		if (On):
			var currentframe = frame
			var currentframeprog = frame_progress
			sprite_frames = NonBluredSpriteFrames
			play()
			frame = currentframe
			frame_progress = currentframeprog
			On = false
			OnOffTween.tween_method(SetFps, 24, 0, 2)
		else:
			var currentframe = frame
			var currentframeprog = frame_progress
			sprite_frames = BluredSpriteFrames
			
			play()
			frame = currentframe
			frame_progress = currentframeprog
			On = true
			OnOffTween.tween_method(SetFps, 0, 24, 1)

func SetFps(FPS: int) -> void:
	sprite_frames.set_animation_speed("default", FPS)
	$AnimatedSprite2D.sprite_frames.set_animation_speed("default", FPS)
	var pitch = FPS / 24.0
	if (pitch == 0):
		$AudioStreamPlayer2D.stop()
		return
	if (!$AudioStreamPlayer2D.playing):
		$AudioStreamPlayer2D.play()
	$AudioStreamPlayer2D.pitch_scale = pitch


func _on_visibility_changed() -> void:
	$AudioStreamPlayer2D.playing = is_visible_in_tree()
