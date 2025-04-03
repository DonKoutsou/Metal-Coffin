extends Node2D

var StartingPos : Vector2
var StartingScale :Vector2
#var PosToGo : Vector2
#var AmmWent : float = 0


# Variables to control the wiggle effect
#@export var amplitude: float = 1.0  # Maximum vertical movement
@export var frequency: float = 1.0  # Wiggle speed
@export var phase_offset: float = 0.0  # Phase offset for randomness
@export var max_rotation: float = 0.1  # Maximum angle in radians for rotation


func _ready() -> void:
	phase_offset = randf_range(0.0, TAU)
	

func ApplyShake(amm : float = 1) -> void:
	max_rotation = max(max_rotation, 0.06 * amm)


func _physics_process(delta: float) -> void:
	var time = Time.get_ticks_msec() / 1000.0

	# Calculate a subtle rotation based on the sine wave
	var rotation_angle = max_rotation * sin(frequency * 1.2 * time + phase_offset)  # Slightly different frequency

	
	#amplitude = max(amplitude - delta, 0)
	#print("amp :" + var_to_str(amplitude))
	max_rotation = max(max_rotation - delta / 60, 0.003)

	#print("frequency :" + var_to_str(frequency))
	# Update transformations
	#position = StartingPos
	rotation = rotation_angle
	$LightPivot2.rotation = lerp($LightPivot2.rotation, rotation, 0.5)
