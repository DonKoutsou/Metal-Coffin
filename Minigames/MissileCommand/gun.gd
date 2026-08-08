extends Desctructable

class_name Gun

@export var MaxBullets : int
@export var MissileScene : PackedScene
@export var BulletLabel : Label

var CurrentBullets : int = 0

func _ready() -> void:
	CurrentBullets = MaxBullets
	BulletsUpdated()

func BulletsUpdated() -> void:
	BulletLabel.text = "{0}/{1}".format([CurrentBullets, MaxBullets])

func CanShoot() -> bool:
	return CurrentBullets > 0

func Shoot(Location : Vector2) -> void:
	var m = MissileScene.instantiate() as MC_Missile
	m.Location = Location
	
	get_parent().add_child(m)
	m.global_position = $Node2D.global_position
	m.OriginalPosition = $Node2D.global_position
	CurrentBullets -= 1
	BulletsUpdated()

#func _input(event: InputEvent) -> void:
	#if (CurrentBullets == 0):
		#return
	#if (event.is_action_pressed("Click")):
		#var m = MissileScene.instantiate() as Missile
		#m.Location = get_global_mouse_position()
		#
		#get_parent().add_child(m)
		#m.global_position = $Node2D.global_position
		#m.OriginalPosition = $Node2D.global_position
		#CurrentBullets -= 1
		#BulletsUpdated()
	#else : if (event is InputEventScreenTouch):
		#var m = MissileScene.instantiate() as Missile
		#m.Location = event.position
		#
		#get_parent().add_child(m)
		#m.global_position = $Node2D.global_position
		#m.OriginalPosition = $Node2D.global_position
		#CurrentBullets -= 1
		#BulletsUpdated()

func _on_reload_timer_timeout() -> void:
	CurrentBullets = min(MaxBullets, CurrentBullets + 1)
	BulletsUpdated()
