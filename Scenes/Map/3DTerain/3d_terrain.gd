@tool
extends SubViewportContainer

class_name DTerain

@export var terain : MeshInstance3D
@export var cam : Camera3D

func _physics_process(delta: float) -> void:
	terain.position = Vector3(floor(cam.position.x),0,floor(cam.position.z))

func UpdateCamPos(pos : Vector2) -> void:
	cam.position.z = pos.y
	cam.position.x = pos.x

func GetTerainMat() -> ShaderMaterial:
	return terain.get_surface_override_material(0)
