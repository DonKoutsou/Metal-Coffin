extends Area2D

@onready var pl_ship: Node2D = $"../PlShip"
@export var BulletScene : PackedScene

@export var FireRpm = 0.05
var rpm = 0.0
var plin = false
func _physics_process(delta: float) -> void:
	global_position = $Node2D.global_position
	$Orientator.look_at(pl_ship.global_position)
	global_rotation += clamp($Orientator.global_rotation -global_rotation , -0.05, 0.05)
	rpm -= delta
	if (rpm > 0):
		return
	rpm = FireRpm
	if (plin):
		
		var bul = BulletScene.instantiate() as Node2D
		get_parent().add_child(bul)
		bul.global_position = $Gun.global_position
		bul.global_rotation = $Gun.global_rotation 
		bul.global_rotation += randf_range(-0.1,0.1)
func Damage():
	$GPUParticles2D.emitting = true
func _on_pl_locator_area_entered(area: Area2D) -> void:
	plin = true
func _on_pl_locator_area_exited(area: Area2D) -> void:
	plin = false
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	var screensize = get_viewport_rect().size
	if (position.x < 0):
		position.x = screensize.x
		position.y = screensize.y- position.y
	if (position.x > screensize.x):
		position.x = 0
		position.y = screensize.y- position.y
	if (position.y < 0):
		position.y = screensize.y
		position.x = screensize.x- position.x
	if (position.y > screensize.y):
		position.y = 0
		position.x = screensize.x- position.x
