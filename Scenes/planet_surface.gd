extends Node3D
class_name PlanetSurface

signal TakeoffFinished()

func ApplySurfaceColors(Col1 : Color, Col2 : Color) -> void:
	var mat = $MeshInstance3D.get_active_material(0) as ShaderMaterial
	mat.set_shader_parameter("slope_color_remap_top", Col2)
	mat.set_shader_parameter("flat_color_remap_top", Col1)
	var mat2 = ($GPUParticles3D.draw_pass_1 as Mesh).surface_get_material(0) as ShaderMaterial
	mat2.set_shader_parameter("top_color", Col1)
	mat2.set_shader_parameter("bottom_color", Col2)
func SetShipVisuals(ShipScene : PackedScene):
	$MeshInstance3D2/ShipPivot.add_child(ShipScene.instantiate())
func Takeoff():
	$AnimationPlayer.play("Takeoff")
	
func AnimFinished(_Name : String):
	TakeoffFinished.emit()
