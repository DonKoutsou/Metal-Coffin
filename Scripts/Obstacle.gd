extends Node3D
class_name Obstacle
var MarkedDead = false
var RotationDirection : Vector3

signal PlayerTouched()

func _ready() -> void:
	var randomscale = randf_range(0.8, 1.2)
	scale = Vector3(randomscale,randomscale,randomscale)
	RotationDirection = Vector3(randf_range(0, 0.01), randf_range(0, 0.01), randf_range(0, 0.01))
	rotation = Vector3(randf_range(0, PI), randf_range(0, PI), randf_range(0, PI))

func SetMesh(Model : Mesh) -> void:
	$MeshInstance3D.mesh = Model
	
func _physics_process(_delta: float) -> void:
	rotation += RotationDirection
	position.z += 0.4
	if (position.z > 50):
		if (!MarkedDead):
			get_parent().EnemyKilled()
			MarkedDead = true
			queue_free()

func _on_area_3d_area_entered(_area: Area3D) -> void:
	PlayerTouched.emit()
	$GPUParticles3D.emitting = true
	$Area3D.set_deferred("monitoring", false)
	$MeshInstance3D.visible = false
	$AudioStreamPlayer3D.play()
