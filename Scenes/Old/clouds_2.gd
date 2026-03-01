extends ColorRect

class_name Clouds

@export var Nois : NoiseTexture2D

var Mat : ShaderMaterial

func _ready() -> void:
	Mat = material as ShaderMaterial
	Mat.set_shader_parameter("Noise", Nois)

func UpdateZoom(newVal : float) -> void:
	var n = Nois.noise as FastNoiseLite
	n.frequency = 1 / newVal

func UpdateOffset(Offsetvalue : Vector2) -> void:
	Mat.set_shader_parameter("offset", Offsetvalue)
