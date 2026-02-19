extends ColorRect

class_name TopographyMap
@export var N : NoiseTexture2D

var Mat : ShaderMaterial

static var CachedPixels : Dictionary[Vector2i, float]
static var tex : Image
static var Offset : Vector2

static var Instance : TopographyMap


func _ready() -> void:
	Instance = self
	Mat = material
	var newoffset = Mat.get_shader_parameter("offset")
	Offset = newoffset
	#var m : ShaderMaterial = material
	#N = m.get_shader_parameter("NoiseTexture2")
	#set_physics_process(false)
	call_deferred("UpdateData")

func ChangeOffset(NewOffset : Vector2) -> void:
	Mat.set_shader_parameter("offset", NewOffset)
	Offset = NewOffset

#func _physics_process(delta: float) -> void:
	#var plship : PlayerShip = get_tree().get_nodes_in_group("PlayerShips")[0]
	#var InLineOfSight = radar_line_of_sight_with_height_func(plship.global_position, plship.Altitude, ShipCamera.GetInstance().get_screen_center_position(), 1)
	#print(InLineOfSight)

func UpdateData() -> void:
	tex = N.get_image()
	#set_physics_process(true)

func GetAltitudeAtGlobalPosition(pos: Vector2) -> float:
	var RoundedPos = Vector2i((pos - global_position) + (Offset * 6000))
	var x = Helper.normalize_value(RoundedPos.x, 0, 12000)
	var y = Helper.normalize_value(RoundedPos.y, 0, 12000)
	var WrapedPos = Vector2i(wrap(x * 2048, 0, 2048), wrap(y * 2048, 0, 2048))
	var color = tex.get_pixel(WrapedPos.x, WrapedPos.y).r
	
	if (CachedPixels.has(RoundedPos)):
		return CachedPixels[RoundedPos] * 10000

	CachedPixels[RoundedPos] = color
	return color * 10000

func WithinLineOfSight(
		radar_pos: Vector2,       # Global position
		radar_height: float,
		ship_pos: Vector2,        # Global position
		ship_height: float,
	) -> bool:
	#queue_redraw()
	#DrawPos.clear()
	var samples : int = roundi(radar_pos.distance_to(ship_pos) / 50)
	var HeightDif : float = ship_height - radar_height
	#print(samples)
	for i in range(samples + 1):
		var t := float(i) / float(samples)
		var pos := radar_pos.lerp(ship_pos, t)
		#DrawPos.append(pos)
		var terrain_height := GetAltitudeAtGlobalPosition(pos)  # Query your height function!
		var expected_height : float = radar_height + (HeightDif / samples) * t
		if terrain_height > expected_height:
			return false
	return true

#var DrawPos : Array[Vector2]

#func _draw() -> void:
	#for g in DrawPos:
		#draw_circle(g - global_position, 10, Color(1,0,0), true)
