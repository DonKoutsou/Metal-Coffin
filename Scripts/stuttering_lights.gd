extends Node2D

class_name StutteringLights


var d = 0.3
func _physics_process(delta: float) -> void:
	d -= delta
	if (d > 0 ):
		return
	d = 0.1
	for g in get_children():
		if (g is PointLight2D):
			g.energy = randf_range(3 ,3.6)
		if (g is DirectionalLight2D):
			g.energy = randf_range(0.8, 1.1)
