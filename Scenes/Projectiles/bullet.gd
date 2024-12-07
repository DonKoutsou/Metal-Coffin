extends Area2D
class_name Bullet
@export var BulletSound : AudioStream
@export var BulletDamage : float
func _ready() -> void:
	var stream = DeletableSound.new()
	stream.autoplay = true
	stream.stream = BulletSound
	get_parent().add_child(stream)
	stream.pitch_scale = randf_range(0.9, 1.1)

func _physics_process(_delta: float) -> void:
	global_position = $Node2D.global_position

func _on_area_entered(area: Area2D) -> void:
	area.Damage(BulletDamage)
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
