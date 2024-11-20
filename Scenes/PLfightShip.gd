extends Area2D

class_name DF_PlayerShip

@export var SpaceshipNorm : Texture
@export var SpaceshipR : Texture
@export var SpaceshipL : Texture
@export var BulletScene : PackedScene
@export var FireRpm = 0.05
@export var HP = 20
@export var Ammo : int = 10
var rpm = 0.0
var currentAmmo = Ammo
var Guns : Array[Node2D]

var Enem : Area2D

signal OnShipDestroyed(ship : DF_PlayerShip)

func SetShipStats(Stats : BattleShipStats) -> void:
	$Control/ProgressBar.max_value = Stats.Hull
	$Control/ProgressBar.value = Stats.Hull
	HP = Stats.Hull
	$Control/ProgressBar2.max_value = Ammo
	
	if (Stats.FirePower == 1):
		$Guns.get_child(2).free()
		$Guns.get_child(1).free()
		
	else :if (Stats.FirePower == 2):
		$Guns.get_child(0).free()
		
	for g in $Guns.get_children():
		Guns.append(g)

func _physics_process(delta: float) -> void:
	
	if (Input.is_action_pressed("MoveLeft")) :
		$Sprite2D.texture = SpaceshipR
		rotation -= 0.06
		
	else: if (Input.is_action_pressed("MoveRight")) :
		$Sprite2D.texture = SpaceshipL
		rotation += 0.06
	
	else:
		$Sprite2D.texture = SpaceshipNorm
	$Control.rotation = - global_rotation
	global_position = $Node2D.global_position
	rpm -= delta
	if (rpm > 0):
		return
	rpm = FireRpm
	
	if (Input.is_action_pressed("Fire")) :
		if (currentAmmo == 0):
			return
		currentAmmo -= 1
		$Control/ProgressBar2.value = currentAmmo
		for g in Guns:
			if (Enem != null):
				g.look_at(Enem.global_position)
			else:
				g.rotation = 0
			var bul = BulletScene.instantiate() as Node2D
			get_parent().add_child(bul)
			bul.global_position = g.global_position
			bul.global_rotation = g.global_rotation
			bul.global_rotation += randf_range(-0.1,0.1)
	else :
		currentAmmo = min(Ammo, currentAmmo + 1)
		$Control/ProgressBar2.value = currentAmmo

func Damage():
	HP -= 1
	$Control/ProgressBar.value = HP
	if (HP <= 0):
		queue_free()
		OnShipDestroyed.emit(self)
	$GPUParticles2D.emitting = true
func _on_pl_locator_area_entered(_area: Area2D) -> void:
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


func _on_enemy_locator_area_entered(area: Area2D) -> void:
	Enem = area


func _on_enemy_locator_area_exited(_area: Area2D) -> void:
	Enem = null
