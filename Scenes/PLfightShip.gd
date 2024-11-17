extends Area2D

@export var BulletScene : PackedScene
@export var FireRpm = 0.05
var rpm = 0.0

var Guns : Array[Node2D]

func _ready() -> void:
	for g in $Guns.get_children():
		Guns.append(g)

func _physics_process(delta: float) -> void:
	global_position = $Node2D.global_position
	if (Input.is_action_pressed("MoveLeft")) :
		rotation -= 0.05
	if (Input.is_action_pressed("MoveRight")) :
		rotation += 0.05
	rpm -= delta
	if (rpm > 0):
		return
	rpm = FireRpm
	if (Input.is_action_pressed("Fire")) :
		for g in Guns:
			var bul = BulletScene.instantiate() as Node2D
			get_parent().add_child(bul)
			bul.global_position = g.global_position
			bul.global_rotation = g.global_rotation
			bul.global_rotation += randf_range(-0.1,0.1)

func Damage():
	$GPUParticles2D.emitting = true
func _on_pl_locator_area_entered(area: Area2D) -> void:
	pass # Replace with function body.



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
