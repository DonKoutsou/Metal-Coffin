@tool
extends Node2D

class_name MissileViz
# Speed of the missile
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

@export var ExplosionSound : AudioStream

signal Finished
signal Reached

func _ready() -> void:
	global_position = SpawnPos
	$TrailLine.Init()
	#$MissileCruise.play(1)

func _process(delta: float) -> void:
	
	if (!Going or Target == null):
		return
	
	var direction = (Target.global_position + (Target.size / 2)) - global_position
	var distance = direction.length()

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
		
		position += Vector2(cos(rotation), sin(rotation)) * speed * delta
	
	if (global_position.distance_to(Target.global_position + (Target.size / 2)) < 30):
		$MultiParticleExample2.global_position = global_position
		$MultiParticleExample2.burst()
		$TrailLine.queue_free()
		Going = false
		Reached.emit()
		$MissileCruise.stop()
		var S = DeletableSoundGlobal.new()
		S.stream = ExplosionSound
		get_parent().add_child(S)
		S.play()
		await $MultiParticleExample2.Finished
		queue_free()
		Finished.emit()
