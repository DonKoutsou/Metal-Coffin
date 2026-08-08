extends Node2D

class_name MC_Missile

@export var Speed : float
@export var Text : Node2D
@export var Area : Area2D
@export var MissileSound : AudioStreamPlayer2D
@export var ExplosionSound : AudioStreamPlayer2D

@export var ExplosionParticle : GPUParticles2D

var Location : Vector2
var OriginalPosition : Vector2

func _ready() -> void:
	Text.look_at(Location)
	MissileSound.pitch_scale = randf_range(1.95, 2.05)
	ExplosionSound.pitch_scale = randf_range(0.95, 1.05)

func _draw() -> void:
	draw_line(Vector2.ZERO, OriginalPosition - global_position , Color(0,0,1))
	draw_circle(Location - global_position, 2, Color(1,0,0))
	#draw_line(Location - global_position , Location - global_position , Color(1,0,0))

func _physics_process(delta: float) -> void:
	queue_redraw()
	global_position = global_position.move_toward(Location, delta * Speed)
	if (global_position.is_equal_approx(Location)):
		Explode()
	
func Explode() -> void:
	MissileSound.queue_free()
	ExplosionSound.play()
	set_physics_process(false)
	Text.queue_free()
	ExplosionParticle.emitting = true
	Area.monitoring = true

func _on_gpu_particles_2d_finished() -> void:
	queue_free()


func _on_area_2d_area_entered(body: Area2D) -> void:
	if (body.get_parent() is Enemy):
		#body.get_parent().queue_free()
		body.get_parent().Kill()
		#Explode()
