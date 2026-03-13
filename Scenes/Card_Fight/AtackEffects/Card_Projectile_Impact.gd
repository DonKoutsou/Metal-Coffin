@tool

extends BurstParticleGroup2D

class_name CardProjectileImpact

@export var ImpactIcon : BurstParticles2D

func SetIcon(t : Texture2D) -> void:
	ImpactIcon.texture = t
