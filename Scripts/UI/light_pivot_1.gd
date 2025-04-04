extends Node2D

var StartingPos : Vector2
var StartingScale :Vector2
#var PosToGo : Vector2
#var AmmWent : float = 0

@export var LeftSound : AudioStream
@export var RightSound : AudioStream
@export var SoundPlayer : AudioStreamPlayer2D

# Variables to control the wiggle effect
#@export var amplitude: float = 1.0  # Maximum vertical movement
@export var frequency: float = 1.0  # Wiggle speed
@export var phase_offset: float = 0.0  # Phase offset for randomness
@export var max_rotation: float = 0.1  # Maximum angle in radians for rotation

var previous_rotation: float = 0.0

func _ready() -> void:
	phase_offset = randf_range(0.0, TAU)
	

func ApplyShake(amm : float = 1) -> void:
	max_rotation = max(max_rotation, 0.06 * amm)


func _physics_process(delta: float) -> void:
	var time = Time.get_ticks_msec() / 1000.0

	# Calculate a subtle rotation based on the sine wave
	var rotation_angle = max_rotation * sin(frequency * 1.2 * time + phase_offset)  # Slightly different frequency

	rotation = rotation_angle
	$LightPivot2.rotation = lerp($LightPivot2.rotation, rotation, 0.5)
	
	# Detect crossing the center and determine direction
	if abs(rotation_angle) > 0.0005 and sign(previous_rotation) != sign(rotation_angle):
		# Swing is crossing the center
		if rotation_angle < 0:
			play_sound(LeftSound)
		else:
			play_sound(RightSound)

	max_rotation = max(max_rotation - delta / 60, 0.003)
	SoundPlayer.volume_db = lerp(-20, -10, abs(max_rotation))
	previous_rotation = rotation_angle
	
func play_sound(sound: AudioStream) -> void:
	SoundPlayer.stream = sound
	SoundPlayer.pitch_scale = randf_range(0.95, 1.05)
	SoundPlayer.play()
