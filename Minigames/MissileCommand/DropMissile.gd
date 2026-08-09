extends Enemy

class_name DropMissile

@export var Speed : float
@export var CurveOff : bool = false
@export var Text : Node2D
@export var Area : Area2D
@export var ExplosionParticle : GPUParticles2D


var Direction : Vector2
var OriginalPosition : Vector2

var LinePoints : PackedVector2Array

func Init(PossibleTargets : Array[Desctructable]) -> void:
	super(PossibleTargets)
	
	
	OriginalPosition = Vector2(randf_range(0, get_viewport_rect().size.x),0)
	global_position = OriginalPosition
	LinePoints.append(global_position)
	
	Direction = global_position.direction_to(TargetPosition)
	if (CurveOff):
		Direction = Direction.rotated(randf_range(-PI, PI))

func _draw() -> void:
	if (CurveOff):
		if (LinePoints.size() < 2):
			return
		draw_set_transform(-global_position)
		draw_polyline(LinePoints, Color(1,0,0), 1)
	else:
		draw_line(Vector2.ZERO, OriginalPosition - global_position , Color(1,0,0), 1)
		
var d : float = 0.1

func _physics_process(delta: float) -> void:
	if (CurveOff):
		d -= delta
		if (d < 0):
			LinePoints.append(global_position)
			d = 0.1
	queue_redraw()
	global_position += Direction * (Speed * delta)
	if (CurveOff):
		Direction = Direction.rotated((global_position.direction_to(TargetPosition).angle() - Direction.angle()) / 100)
	if (position.y > get_viewport_rect().size.y):
		Explode()
	#Direction.move_toward(global_position.direction_to(Target.global_position), 1000)
	#global_position = global_position.move_toward(Target.global_position, delta * Speed)
	#if (global_position == Target.global_position):
		#Explode()
	
func Explode() -> void:
	set_physics_process(false)
	#Text.queue_free()
	ExplosionParticle.emitting = true
	#Area.monitoring = true
	EnemyKilled.emit(self, false)


func _on_gpu_particles_2d_finished() -> void:
	queue_free()



func _on_area_2d_area_entered(area: Area2D) -> void:
	if (area.get_parent() is Desctructable):
		area.get_parent().Kill()
		Explode()
