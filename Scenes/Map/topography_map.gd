extends ColorRect

class_name TopographyMap
##Class containing the terain information of the world


##Resolution of the texture used to recover data from
const GROUND_TEXTURE_RESOLUTION : int = 256
##Size of map
const SIZE : Vector2 = Vector2(9000,9000)
##Data texture
@export_file("*.tres") var DataTextureFile : String

static var DataTexture : Image
var Mat : ShaderMaterial

#-----------------------------------------------------------------------------------------------------------------
func _ready() -> void:
	DataTexture = ResourceLoader.load(DataTextureFile)
	Mat = material

#-----------------------------------------------------------------------------------------------------------------
func ChangeOffset(NewOffset : Vector2) -> void:
	Mat.set_shader_parameter("offset", NewOffset)

#-----------------------------------------------------------------------------------------------------------------
static func GetWindProtection(Pos : Vector2, Height : float) -> float:
	var WindPos = Pos + (-WeatherManage.WindDirection * 500)
	var traceData : TraceData = Trace(WindPos, Height + 200, Pos, Height)
	
	if (!traceData.Collided):
		return 1
	else:
		var heightDifference = traceData.CollisionHeight - Height
		var horizontalDistance = traceData.CollisionPos.distance_to(Pos)
		var blockAngle = rad_to_deg(atan(heightDifference / horizontalDistance))
		return clamp(blockAngle / 80, 0, 1)

#-----------------------------------------------------------------------------------------------------------------
static func GetWindAtPos(Pos : Vector2, Height : float) ->  float:
	var prot = GetWindProtection(Pos, Height)
	var HeightModifier = 0.3 + 0.7 * (Height / 10000)
	var WindVel = WeatherManage.WindSpeed
	return (WindVel * HeightModifier) * prot

#-----------------------------------------------------------------------------------------------------------------
static func GetTurbelance(Pos : Vector2) -> float:
	var Grad : Vector2 = GetGradientAtGlobalPosition(Pos)
	var Facing : float = Grad.dot(WeatherManage.WindDirection)
	var Turbelance = max(0, (WeatherManage.WindSpeed * Grad.length()) * Facing)
	return Turbelance

#-----------------------------------------------------------------------------------------------------------------
static func GetGradientAtGlobalPosition(pos : Vector2) -> Vector2:
	var RoundedPos = Vector2i(pos + Vector2(4500, 4500))
	
	var Offsets : PackedVector2Array = [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0,2)]
	var Altitudes : PackedFloat64Array
	for g in Offsets:
		var Normalisedx = Helper.normalize_value(wrap(RoundedPos.x, 0, 36000), 0, 36000)
		var Normalisedy = Helper.normalize_value(wrap(RoundedPos.y, 0, 36000), 0, 36000)
		var WrapedX = wrap((Normalisedx * GROUND_TEXTURE_RESOLUTION) + g.x, 0, GROUND_TEXTURE_RESOLUTION)
		var WrapedY = wrap((Normalisedy * GROUND_TEXTURE_RESOLUTION) + g.y, 0, GROUND_TEXTURE_RESOLUTION)
		var PixelCoords = Vector2i(WrapedX, WrapedY)
		var Alt = DataTexture.get_pixelv(PixelCoords).r
		#Bring to -1/1 range
		var RangedAlt = (Alt - 0.5) * 2.0
		Altitudes.append(RangedAlt)
	
	var Grad : Vector2 = Vector2(Altitudes[1] - Altitudes[0], Altitudes[3] - Altitudes[2])
	#CachedPixels[WrapedPos] = Alt
	return Grad

#-----------------------------------------------------------------------------------------------------------------
static func GetAltitudeAtGlobalPosition(pos: Vector2) -> float:
	var RoundedPos = Vector2i(pos + (SIZE / 2))
	
	#bring to 0-1 range
	var Normalisedx = Helper.normalize_value(wrap(RoundedPos.x, 0, 36000), 0, 36000)
	var Normalisedy = Helper.normalize_value(wrap(RoundedPos.y, 0, 36000), 0, 36000)
	
	#turn it into pixel coords
	var pixelX = floori(Normalisedx * GROUND_TEXTURE_RESOLUTION)
	var pixelY = floori(Normalisedy * GROUND_TEXTURE_RESOLUTION)
	var PixelCoords = Vector2i(pixelX, pixelY)
	
	#grab value from texture
	var Alt = DataTexture.get_pixelv(PixelCoords).r
	#Bring to -1/1 range
	var RangedAlt = (Alt - 0.5) * 2.0
	
	return RangedAlt * 8000

#-----------------------------------------------------------------------------------------------------------------
##runs a trace to check the line of sight, positions in global
static func Trace(radar_pos: Vector2,radar_height: float,ship_pos: Vector2,ship_height: float) -> TraceData:
	#figure out the ammount of samples based on distance
	var samples : int = roundi(Vector2(radar_pos.x, radar_pos.y).distance_to(Vector2(ship_pos.x, ship_pos.y)) / 20)
	#get the height dif of the 2 points
	var HeightDif : float = ship_height - radar_height
	
	#check each sample pos
	for i in range(samples + 1):
		var t := float(i) / float(samples)
		#get sample pos
		var pos := radar_pos.lerp(ship_pos, t)
		#sample the height of the position
		var terrain_height := GetAltitudeAtGlobalPosition(pos)
		#calculate height trace will have at sample pos
		var expected_height : float = radar_height + (HeightDif / samples) * t
		#check for collision
		if terrain_height > expected_height:
			return TraceData.NewData(true, pos, terrain_height)
			
	#if we did not collide anywhere, we have line of sight
	return TraceData.NewData(false, ship_pos, ship_height)

#DRAWING USED FOR DEBUG
#var DrawPos : Array[Vector2]

#func _draw() -> void:
	#for g in DrawPos:
		#draw_circle(g - global_position, 10, Color(1,0,0), true)
