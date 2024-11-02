extends Node3D
class_name PlanetSurface

@export var N : FastNoiseLite
@export var PosLocs : Array[Vector3] = []

signal TakeoffFinished()

var Exploring = false

func ApplySurfaceColors(Col1 : Color, Col2 : Color) -> void:
	N.offset = PosLocs.pick_random()
	var mat = $MeshInstance3D.get_active_material(0) as ShaderMaterial
	mat.set_shader_parameter("slope_color_remap_top", Col2)
	mat.set_shader_parameter("flat_color_remap_top", Col1)
	var mat2 = ($GPUParticles3D.draw_pass_1 as Mesh).surface_get_material(0) as ShaderMaterial
	mat2.set_shader_parameter("top_color", Col1)
	mat2.set_shader_parameter("bottom_color", Col2)
func SetShipVisuals(ShipScene : PackedScene):
	var ship = ShipScene.instantiate() as Character
	ship.IsDeco = true
	$MeshInstance3D2/ShipPivot.add_child(ship)
	
func Takeoff():
	$AnimationPlayer.play("Takeoff")
	
func AnimFinished(_Name : String):
	if (_Name == "Takeoff"):
		TakeoffFinished.emit()
	else :
		Exploring = false
func MoveLocs():
	Exploring = true
	$AnimationPlayer.play("ChangePos")
func ExploreFurther():
	N.offset = PosLocs.pick_random()
