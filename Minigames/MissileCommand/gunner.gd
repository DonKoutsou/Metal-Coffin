extends HBoxContainer

class_name Gunner

var Guns : Array[Gun]

func _ready() -> void:
	for g in get_children():
		if (g is Gun):
			Guns.append(g)
			g.Destroyed.connect(GunDestroyed.bind(g))
func GunDestroyed(G : Gun) -> void:
	Guns.erase(G)

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Click")):
		var pos = get_global_mouse_position()
		TryShotAtPosition(pos)

	else : if (event is InputEventScreenTouch):
		var pos = event.position
		TryShotAtPosition(pos)

func TryShotAtPosition(Pos : Vector2) -> void:
	var Closest : Gun
	var Dist : float = INF
	for g in Guns:
		if (g.CanShoot()):
			var CurrentGunDist = g.global_position.distance_squared_to(Pos)
			if (CurrentGunDist < Dist):
				Closest = g
				Dist = CurrentGunDist
	if (is_instance_valid(Closest)):
		Closest.Shoot(Pos)
