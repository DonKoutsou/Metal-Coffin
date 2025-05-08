extends Node2D

class_name CardViz
# Speed of the missile
@export var CardPlecementSound : AudioStream


@export var speed = 200

# Adjust this value for more or less curvature
@export var base_curve_intensity = 0.1

@export var min_distance = 100

var Target : Control
var Going = true
var SpawnPos : Vector2 = Vector2.ZERO
# Wiggle amplitude and speed
@export var wiggle_amplitude = 5.0
@export var wiggle_frequency = 3.0

signal Finished
signal Reached

func _ready() -> void:
	global_position = SpawnPos
	
	$Sprite2D.rotation_degrees = randf_range(0, 360)
	
	$TrailLine.call_deferred("Init")

func _physics_process(delta: float) -> void:
	
	if (!Going or Target == null):
		return
	
	var direction = (Target.global_position + (Target.size / 2)) - global_position
	var distance = direction.length()
	
	$Sprite2D.rotation_degrees += 15
	
	# Only adjust if the missile is more than a tiny distance from the target
	if distance > 1:
		# Normalize the direction
		direction = direction.normalized()

		# Compute the angle towards the mouse
		var target_angle = direction.angle()
		
		# Get the current angle of the missile
		var current_angle = rotation

		# Reduce curve intensity as the missile gets closer
		var curve_intensity = base_curve_intensity
		if distance < 100:
			curve_intensity = base_curve_intensity * (distance / 100)
		
		# Interpolate angle for smooth turning
		current_angle = lerp_angle(current_angle, target_angle, curve_intensity)

		# Add wiggling effect
		current_angle += sin(Time.get_ticks_msec() * wiggle_frequency) * deg_to_rad(wiggle_amplitude)

		# Update rotation
		rotation = current_angle

		# Move the missile forward
		
		position += Vector2(cos(rotation), sin(rotation)) * speed
	
	if (global_position.distance_to(Target.global_position + (Target.size / 2)) < 50):
		global_position = Target.global_position + (Target.size / 2)
		Going = false
		Reached.emit()
		
		var S = DeletableSoundGlobal.new()
		S.stream = CardPlecementSound
		S.autoplay = true
		S.pitch_scale = randf_range(0.8, 1.2)
		#S.bus = "MapSounds"
		get_parent().add_child(S)
		S.volume_db = - 20
		
		queue_free()
		Finished.emit()
	else:
		$TrailLine.Update(delta)
