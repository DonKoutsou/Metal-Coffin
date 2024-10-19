extends Node3D

var MarkedDead = false
var RotationDirection : Vector3

func _ready() -> void:
	var randomscale = randf_range(0.8, 1.2)
	scale = Vector3(randomscale,randomscale,randomscale)
	RotationDirection = Vector3(randf_range(0, 0.01), randf_range(0, 0.01), randf_range(0, 0.01))
	rotation = Vector3(randf_range(0, PI), randf_range(0, PI), randf_range(0, PI))
	pass
func SetMesh(Model : Mesh) -> void:
	$MeshInstance3D.mesh = Model
func _process(_delta: float) -> void:
	rotation += RotationDirection
	position.z += 0.4
	if (position.z > 10):
		if (!MarkedDead):
			get_parent().EnemyKilled()
			MarkedDead = true
	if (position.z > 25):
		queue_free()
	pass

func _on_area_3d_area_entered(_area: Area3D) -> void:
	get_parent().GameFinished(false)
	pass
