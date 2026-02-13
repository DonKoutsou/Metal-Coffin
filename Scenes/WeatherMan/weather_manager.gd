extends TextureRect

class_name WeatherManage

@export var N : FastNoiseLite
@export var EventHandler : UIEventHandler

const MAX_WIND_SPEED : int = 400

static var WorldBounds : Vector2
static var Instance : WeatherManage
static var WindDirection : Vector2
static var WindSpeed : float = 50
static var tx : Image
static var LighAmm : Curve = preload("res://Resources/LightCurve.tres")
static var inverse_transform : Transform2D
static var rect_size : Vector2
static var ShipsToUpdate : Array[MapShip]

static func RegisterShip(Ship : MapShip) -> void:
	ShipsToUpdate.append(Ship)

static func UnregisterShip(Ship : MapShip) -> void:
	ShipsToUpdate.erase(Ship)

static func GetInstance() -> WeatherManage:
	return Instance

func _ready() -> void:
	#Init wind direction, setting it to random dir
	WindDirection = Vector2.RIGHT.rotated(randf_range(-2 * PI, 2 * PI))
	WindSpeed = randf_range(0, MAX_WIND_SPEED)
	EventHandler.ForecastToggled.connect(ToggleWeatherMan)
	Instance = self
	
	N.offset = Vector3(randf_range(-10000, 10000), randf_range(-10000, 10000), 0)
	tx = texture.get_image()
	
	var global_transform = get_global_transform()
	inverse_transform = global_transform.affine_inverse()
	rect_size = get_rect().size
	
	SetWorldBounds(WorldBounds)

func ToggleWeatherMan(t : bool) -> void:
	visible = t

func SetWorldBounds(WB : Vector2) -> void:
	WorldBounds = WB
	position = Vector2(-WorldBounds.x, WorldBounds.y * 2)
	set_deferred("size", Vector2(WorldBounds.x * 2, -WorldBounds.y * 3))
	
	var global_transform = get_global_transform()
	inverse_transform = global_transform.affine_inverse()
	rect_size = get_rect().size

func UpdateData() -> void:
	var global_transform = get_global_transform()
	inverse_transform = global_transform.affine_inverse()
	rect_size = get_rect().size

var d = 0.2
func Update(delta: float) -> void:
	d -= delta
	if (d <= 0):
		d = 0.2
		
		var simspeed = SimulationManager.SimSpeed()
		#Update wind direction
		WindDirection = WindDirection.rotated(randf_range(-0.001, 0.001) * simspeed)
		WindSpeed = clamp(WindSpeed + randf_range(-0.2, 0.2), 0, MAX_WIND_SPEED)
		#Add the new offset of the weather to the noise and produce the new texture
		N.offset -= Vector3(WindDirection.x, WindDirection.y, 0) * (simspeed / 30) * (WindSpeed * 0.01)
		
		
		
		N.fractal_gain = clamp(N.fractal_gain + randf_range(-0.02, 0.02) * simspeed, -10, 10)
		tx = texture.get_image()
		
		var L = GetLightAmm()
		
		for g in ShipsToUpdate:
			var viz = GetVisibilityInPosition(g.global_position, L)
			g.VisibilityValue = viz
			g.StormValue = 1 - (viz - 0.5)
			if (g is PlayerDrivenShip):
				g.UpdateLight(L, viz)
			g.RephreshVisRange(viz)

static func GetWindVelocity() -> Vector2:
	return WindDirection * (WindSpeed / (MAX_WIND_SPEED / 2.0))

static func GetVisibilityInPosition(pos : Vector2, LightValue : float) -> float:
	var value = Helper.mapvalue(1 - get_color_at_global_position(pos).r, 0.5, LightValue)
	return value

static func GetLightAmm() -> float:
	var t = Clock.GetHours()
	return LighAmm.sample(t)

static func get_color_at_global_position(pos: Vector2) -> Color:
	# Step 3: Use the inverse transform to get the local position
	var local_position = (inverse_transform * Vector2(pos.x, pos.y))
	
	# Step 3: Ensure the position is within the bounds of the TextureRect
	if local_position.x < 0 or local_position.x > rect_size.x or local_position.y < 0 or local_position.y > rect_size.y:
		return Color(0, 0, 0, 0)  # Return transparent color if out of bounds

	 # Step 5: Calculate UV coordinates based on Keep Aspect Covered
	var texture_size = tx.get_size()
	var rect_aspect_ratio = rect_size.x / rect_size.y
	var texture_aspect_ratio = texture_size.x / texture_size.y

	var Scl = 1.0
	if texture_aspect_ratio > rect_aspect_ratio:
		Scl = rect_size.x / texture_size.x  # Scale by the width
	else:
		Scl = rect_size.y / texture_size.y  # Scale by the height

	# Scaled dimensions
	var scaled_width = texture_size.x * Scl
	var scaled_height = texture_size.y * Scl

	# Offsets to center the texture based on the clipping
	var offset_x = (rect_size.x - scaled_width) / 2.0
	var offset_y = (rect_size.y - scaled_height) / 2.0

	# Map local position to UV coordinates
	var uv = Vector2((local_position.x - offset_x) / scaled_width, 
					 (local_position.y - offset_y) / scaled_height)

	#tx.lock()  # Lock the image for pixel access
	var color = tx.get_pixel(clamp(uv.x * texture_size.x, 0, texture_size.x - 1), clamp(uv.y * texture_size.y, 0, texture_size.y - 1))
	#tx.unlock()  # Unlock after accessing

	return color


func GetSaveData() -> SaveData:
	var Sav = SaveData.new()
	Sav.DataName = "Weather"
	
	var Data = SD_WeatherMan.new()
	Data.WindDirection = WindDirection
	Data.WindSpeed = WindSpeed
	Data.Offset = N.offset
	
	Sav.Datas.append(Data)
	return Sav

func LoadSaveData(Data : SD_WeatherMan) -> void:
	WindDirection = Data.WindDirection
	WindSpeed = Data.WindSpeed
	N.offset = Data.Offset
	tx = texture.get_image()
