extends Area2D

class_name DF_EnemyShip


var pl_ship: DF_PlayerShip
@export var BulletScene : PackedScene
@export var BulletScene2 : PackedScene
@export var BulletScene3 : PackedScene
@export var HP = 20
@export var FireRpm = 0.05
@export var Ammo : int = 10

var currentAmmo = Ammo
var rpm = 0.0
var plin = false
var Guns : Array[Node2D]
var bulletscene : PackedScene
signal OnShipDestroyed(ship : DF_EnemyShip)


func SetShipStats(Stats : BattleShipStats) -> void:
	$Control/ProgressBar.max_value = Stats.Hull
	$Control/ProgressBar.value = Stats.Hull
	HP = Stats.Hull
	$Control/ProgressBar2.max_value = Ammo
	
	var firep = Stats.FirePower
	
	if (firep > 6):
		bulletscene = BulletScene3
		firep -= 6
	else : if (firep > 3):
		bulletscene = BulletScene2
		firep -= 3
	else :
		bulletscene = BulletScene
	if (firep == 1):
		$Guns.get_child(2).free()
		$Guns.get_child(1).free()
		
	else :if (firep == 2):
		$Guns.get_child(0).free()
		
	for g in $Guns.get_children():
		Guns.append(g)

func _physics_process(delta: float) -> void:
	
	global_rotation += clamp($Orientator.global_rotation -global_rotation , -0.06, 0.06)
	
	$Control.rotation = - global_rotation
	global_position = $Node2D.global_position
	rpm -= delta
	if (rpm > 0):
		return
	rpm = FireRpm
	$Orientator.look_at(pl_ship.global_position)
	if (plin and currentAmmo > 0):
		currentAmmo -= 1
		$Control/ProgressBar2.value = currentAmmo
		for g in Guns:
			g.look_at(pl_ship.global_position)
			var bul = bulletscene.instantiate() as Bullet
			bul.set_collision_mask_value(5, true)
			get_parent().add_child(bul)
			bul.global_position = g.global_position
			bul.global_rotation = g.global_rotation 
			bul.global_rotation += randf_range(-0.1,0.1)
	else:
		currentAmmo = min(Ammo, currentAmmo + 1)
		$Control/ProgressBar2.value = currentAmmo
func Damage(amm : float):
	HP -= amm
	$Control/ProgressBar.value = HP
	if (HP <= 0):
		queue_free()
		OnShipDestroyed.emit(self)
	$GPUParticles2D.emitting = true
func _on_pl_locator_area_entered(_area: Area2D) -> void:
	plin = true
func _on_pl_locator_area_exited(_area: Area2D) -> void:
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
