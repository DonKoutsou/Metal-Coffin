extends Enemy

class_name Airplane

@export var Speed : float

func Init(PossibleTargets : Array[Desctructable]) -> void:
	global_position = Vector2(-10, randf_range(get_viewport_rect().size.y / 4, (get_viewport_rect().size.y / 4) * 3))

func _physics_process(delta: float) -> void:
	global_position += Vector2.RIGHT * (Speed * delta)
	if (global_position.x > get_viewport_rect().size.x):
		EnemyKilled.emit(self, false)
		queue_free()
