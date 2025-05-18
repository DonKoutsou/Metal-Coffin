extends Node2D

class_name MissileViz
# Speed of the missile
@export var speed = 200

# Adjust this value for more or less curvature
@export var base_curve_intensity = 0.1
# Wiggle amplitude and speed
@export var wiggle_amplitude = 5.0
@export var wiggle_frequency = 3.0

@export var ExplosionSound : AudioStream
@export var FireSound : AudioStream

@export_group("Nodes")
@export var InitialParticle : BurstParticleGroup2D
@export var EndingParticle : BurstParticleGroup2D
@export var SoundNode : AudioStreamPlayer
@export var Trail : TrailLine

signal Finished
signal Reached

var Target : Control
var Going = false
var SpawnPos : Vector2 = Vector2.ZERO

func _ready() -> void:
	global_position = SpawnPos

	Trail.Init()
	
	Going = true
	
	SoundNode.pitch_scale = randf_range(0.8, 1.2)
	
	var S = DeletableSoundGlobal.new()
	S.stream = FireSound
	get_parent().get_parent().add_child(S)
	S.volume_db = - 20
	S.play()
	S.pitch_scale = randf_range(0.8, 1.2)
	
	set_physics_process(false)
	InitialParticle.burst()
	await InitialParticle.Finished
	SoundNode.play()
	look_at(Target.global_position + (Target.size / 2))
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	
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
		
		position += Vector2(cos(rotation), sin(rotation)) * speed
	
	if (global_position.distance_to(Target.global_position + (Target.size / 2)) < 50):
		global_position = Target.global_position + (Target.size / 2)
		EndingParticle.global_position = global_position
		EndingParticle.global_rotation = 0
		EndingParticle.burst()
		Trail.free()
		Going = false
		Reached.emit()
		SoundNode.stop()
		var S = DeletableSoundGlobal.new()
		S.stream = ExplosionSound
		get_parent().get_parent().add_child(S)
		S.play()
		S.pitch_scale = randf_range(0.8, 1.2)
		await EndingParticle.Finished
		queue_free()
		Finished.emit()
	else:
		Trail.Update(delta)
