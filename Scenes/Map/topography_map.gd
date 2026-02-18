extends ColorRect

class_name TopographyMap
@export var N : NoiseTexture2D

var Mat : ShaderMaterial

static var CachedPixels : Dictionary[Vector2i, float]
static var tex : Image
static var Offset : Vector2

func _ready() -> void:
	Mat = material
	var newoffset = Mat.get_shader_parameter("offset")
	Offset = newoffset
	#var m : ShaderMaterial = material
	#N = m.get_shader_parameter("NoiseTexture2")
	set_physics_process(false)
	call_deferred("UpdateData")

func ChangeOffset(NewOffset : Vector2) -> void:
	Mat.set_shader_parameter("offset", NewOffset)
	Offset = NewOffset

func _physics_process(delta: float) -> void:
	var p = ShipCamera.GetInstance().get_screen_center_position()
	print(snappedf(get_color_at_global_position(p - global_position), 0.1))

func UpdateData() -> void:
	tex = N.get_image()
	set_physics_process(true)

func get_color_at_global_position(pos: Vector2) -> float:
	var RoundedPos = Vector2i(pos + (Offset * 6000))
	var x = Helper.normalize_value(RoundedPos.x, 0, 12000)
	var y = Helper.normalize_value(RoundedPos.y, 0, 12000)
	var WrapedPos = Vector2i(wrap(x * 2048, 0, 2048), wrap(y * 2048, 0, 2048))
	var color = tex.get_pixel(WrapedPos.x, WrapedPos.y).r
	
	if (CachedPixels.has(RoundedPos)):
		return CachedPixels[RoundedPos]

	CachedPixels[RoundedPos] = color
	return color
