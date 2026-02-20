extends ColorRect

class_name TopographyMap
@export_file(".tres") var N : String

var Mat : ShaderMaterial

#var CachedPixels : Dictionary[Vector2i, float]
var tex : Image
var Offset : Vector2

static var Instance : TopographyMap


func _ready() -> void:
	Instance = self
	Mat = material
	var newoffset = Mat.get_shader_parameter("offset")
	Offset = newoffset
	#var m : ShaderMaterial = material
	#N = m.get_shader_parameter("NoiseTexture2")
	#set_physics_process(false)
	UpdateData()

func ChangeOffset(NewOffset : Vector2) -> void:
	Mat.set_shader_parameter("offset", NewOffset)
	Offset = NewOffset


func GetWindProtection(Pos : Vector2, Height : float) -> float:
	var WindPos = Pos + (-WeatherManage.WindDirection * 500)
	var LineOfSight = GetCollisionPoint3(WindPos, Height + 200, Pos, Height)
	if (LineOfSight == Vector3(Pos.x, Pos.y, Height)):
		return 1
	else:
		var heightDifference = LineOfSight.z - Height
		var horizontalDistance = Vector2(LineOfSight.x, LineOfSight.y).distance_to(Pos)
		var blockAngle = rad_to_deg(atan(heightDifference / horizontalDistance))
		#var Angle = rad_to_deg(LineOfSight.angle_to(Vector3(Pos.x, Pos.y, Height)))
		return clamp(blockAngle / 80, 0, 1)

func GetWindAtPos(Pos : Vector2, Height : float) ->  float:
	var prot = GetWindProtection(Pos, Height)
	var HeightModifier = 0.3 + 0.7 * (Height / 10000)
	var WindVel = WeatherManage.WindSpeed
	return (WindVel * HeightModifier) * prot

func GetTurbelance(Pos : Vector2) -> float:
	var Grad : Vector2 = GetGradientAtGlobalPosition(Pos)
	var Facing : float = Grad.dot(WeatherManage.WindDirection)
	var Turbelance = max(0, (WeatherManage.WindSpeed * Grad.length()) * Facing)
	return Turbelance
#func _physics_process(delta: float) -> void:
	#var plship : PlayerShip = get_tree().get_nodes_in_group("PlayerShips")[0]
	#var InLineOfSight = radar_line_of_sight_with_height_func(plship.global_position, plship.Altitude, ShipCamera.GetInstance().get_screen_center_position(), 1)
	#print(InLineOfSight)

func UpdateData() -> void:
	var noi : NoiseTexture2D = ResourceLoader.load(N)
	await noi.changed
	tex = noi.get_image()

func GetGradientAtGlobalPosition(pos : Vector2) -> Vector2:
	var RoundedPos = Vector2((pos - global_position) + (Offset * 6000))
	
	var Offsets : PackedVector2Array = [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0,2)]
	var Altitudes : PackedFloat64Array
	for g in Offsets:
		var x = Helper.normalize_value(RoundedPos.x, 0, 12000)
		var y = Helper.normalize_value(RoundedPos.y, 0, 12000)
		var WrapedPos = Vector2(wrap((x * 2048) + g.x, 0, 2048), wrap((y * 2048) + g.y, 0, 2048))
		var Alt = tex.get_pixelv(WrapedPos).r
		#Bring to -1/1 range
		var RangedAlt = (Alt - 0.5) * 2.0
		Altitudes.append(RangedAlt)
	
	var Grad : Vector2 = Vector2(Altitudes[1] - Altitudes[0], Altitudes[3] - Altitudes[2])
	#CachedPixels[WrapedPos] = Alt
	return Grad

func GetAltitudeAtGlobalPosition(pos: Vector2) -> float:
	var RoundedPos = Vector2i((pos - global_position) + (Offset * 6000))
	
		
	var x = Helper.normalize_value(RoundedPos.x, 0, 12000)
	var y = Helper.normalize_value(RoundedPos.y, 0, 12000)
	var WrapedPos = Vector2i(wrap(x * 2048, 0, 2048), wrap(y * 2048, 0, 2048))
	#if (CachedPixels.has(WrapedPos)):
		#return CachedPixels[WrapedPos] * 10000
		
	var Alt = snappedf(tex.get_pixel(WrapedPos.x, WrapedPos.y).r, 0.01)
	#Bring to -1/1 range
	var RangedAlt = (Alt - 0.5) * 2.0
	#CachedPixels[WrapedPos] = Alt
	return RangedAlt * 8000

func WithinLineOfSight(
		radar_pos: Vector2,       # Global position
		radar_height: float,
		ship_pos: Vector2,        # Global position
		ship_height: float,
	) -> bool:
	#queue_redraw()
	#DrawPos.clear()
	var samples : int = roundi(Vector3(radar_pos.x, radar_pos.y, radar_height).distance_to(Vector3(ship_pos.x, ship_pos.y, ship_height)) / 50)
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

func GetCollisionPoint(radar_pos: Vector2,       # Global position
		radar_height: float,
		ship_pos: Vector2,        # Global position
		ship_height: float,
	) -> Vector2:
	#queue_redraw()
	#DrawPos.clear()
	var samples : int = roundi(Vector3(radar_pos.x, radar_pos.y, radar_height).distance_to(Vector3(ship_pos.x, ship_pos.y, ship_height)) / 50)
	var HeightDif : float = ship_height - radar_height
	#print(samples)
	for i in range(samples + 1):
		var t := float(i) / float(samples)
		var pos := radar_pos.lerp(ship_pos, t)
		#DrawPos.append(pos)
		var terrain_height := GetAltitudeAtGlobalPosition(pos)  # Query your height function!
		var expected_height : float = radar_height + (HeightDif / samples) * t
		if terrain_height > expected_height:
			return pos
	return ship_pos

func GetCollisionPoint3(radar_pos: Vector2,       # Global position
		radar_height: float,
		ship_pos: Vector2,        # Global position
		ship_height: float,
	) -> Vector3:
	#queue_redraw()
	#DrawPos.clear()
	var samples : int = roundi(Vector3(radar_pos.x, radar_pos.y, radar_height).distance_to(Vector3(ship_pos.x, ship_pos.y, ship_height)) / 50)
	var HeightDif : float = ship_height - radar_height
	#print(samples)
	for i in range(samples + 1):
		var t := float(i) / float(samples)
		var pos := radar_pos.lerp(ship_pos, t)
		#DrawPos.append(pos)
		var terrain_height := GetAltitudeAtGlobalPosition(pos)  # Query your height function!
		var expected_height : float = radar_height + (HeightDif / samples) * t
		if terrain_height > expected_height:
			return Vector3(pos.x, pos.y, terrain_height)
	return Vector3(ship_pos.x, ship_pos.y, ship_height)
#var DrawPos : Array[Vector2]

#func _draw() -> void:
	#for g in DrawPos:
		#draw_circle(g - global_position, 10, Color(1,0,0), true)
