extends Control

class_name IntroMenuShips

var CommingFromOut = false
var centerpoint : Vector2

@export var Speed : float = 100

var RotTw : Tween



func _ready() -> void:
	position.x = - 100
	centerpoint = get_viewport_rect().size / 2
	CommingFromOut = true

func _physics_process(delta: float) -> void:
	position += Vector2(delta * Speed, 0).rotated(rotation) 
	$TextureRect3/TrailLine2.Update(delta)
	$TextureRect4/TrailLine2.Update(delta)
	$TextureRect5/TrailLine2.Update(delta)
	if (CommingFromOut):
		if (centerpoint.distance_to(position) < 300):
			if (is_instance_valid(RotTw)):
				RotTw.kill()
			RotTw = create_tween()
			RotTw.set_ease(Tween.EASE_IN)
			RotTw.set_trans(Tween.TRANS_QUAD)
			RotTw.tween_method(UpdateRotation, rotation, randf_range(rotation - deg_to_rad(180), rotation + deg_to_rad(180)), 8)
			CommingFromOut = false
		else:
			return
	if (position.x > get_viewport_rect().size.x + 100 or position.y > get_viewport_rect().size.y + 100 or position.x < -100 or position.y < - 100):

		var spawnpoint = centerpoint + Vector2( get_viewport_rect().size.x, 0).rotated(randf_range(deg_to_rad(-360), deg_to_rad(360)))
		position = spawnpoint
		
		
		CommingFromOut = true
		
		if (is_instance_valid(RotTw)):
			RotTw.kill()
		
		rotation = spawnpoint.angle_to_point(centerpoint)
		AlignShips()
		$TextureRect3/TrailLine2.Init()
		$TextureRect4/TrailLine2.Init()
		$TextureRect5/TrailLine2.Init()


func UpdateRotation(rot : float) -> void:
	rotation = rot
	AlignShips()

func AlignShips() -> void:
	for g in get_children():
		g.get_child(0).rotation = -rotation
		g.get_child(0).get_child(0).rotation = rotation
