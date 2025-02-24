extends TextureRect

var StartingPos : Vector2
var StartingScale :Vector2
#var PosToGo : Vector2
#var AmmWent : float = 0


# Variables to control the wiggle effect
#@export var amplitude: float = 1.0  # Maximum vertical movement
@export var frequency: float = 1.0  # Wiggle speed
@export var phase_offset: float = 0.0  # Phase offset for randomness
@export var max_rotation: float = 0.1  # Maximum angle in radians for rotation
@export var max_scale_x: float = 1  # Maximum angle in radians for rotation
#@export var min_scale: float = 0.1  # Maximum angle in radians for rotation
#@export var skew_factor: float = 0.1  # Maximum skew factor, adjust as needed

func _ready() -> void:
	StartingPos = position
	StartingScale = scale
	phase_offset = randf_range(0.0, TAU)
	#PosToGo = position

func ApplyShake(amm : float = 1) -> void:
	max_rotation = 0.04 * amm
	max_scale_x = 0.01 * amm

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
	position = StartingPos
	rotation = rotation_angle
	scale.x = StartingScale.x * scale_x
