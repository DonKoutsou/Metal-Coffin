extends ColorRect

class_name WeatherManage

@export var EventHandler : UIEventHandler
@export var WindChangeMinimumTime_Minutes : float = 20.0
@export var N : NoiseTexture2D

const MAX_WIND_SPEED : int = 200

static var Instance : WeatherManage
static var WindDirection : Vector2
static var WindSpeed : float = 50
static var tx : Image
static var LighAmm : Curve = preload("res://Resources/LightCurve.tres")
static var ShipsToUpdate : Array[MapShip]

static var CachedPixels : Dictionary[Vector2i, Color]

var Mat : ShaderMaterial
var CurrentCamOffset : Vector2
var LastTimeWindChanged : float
var WindDirectionOffset : int = 1

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
	
	#CurrentOffset = Vector2(randf_range(-10000, 10000), randf_range(-10000, 10000))
	N.noise.offset = Vector3(randf_range(-10000, 10000), randf_range(-10000, 10000), 0)
	Mat = material
	#Mat.set_shader_parameter("offset", CurrentOffset)
	tx = N.get_image()
	await N.changed
	tx = N.get_image()
	
	LastTimeWindChanged = 0
	WindDirectionOffset = 1

func UpdateCameraOffset(CamOffset : Vector2) -> void:
	CurrentCamOffset = CamOffset
	Mat.set_shader_parameter("offset", CurrentCamOffset)

func ToggleWeatherMan(t : bool) -> void:
	visible = t

var d = 0.2
func Update(delta: float) -> void:
	d -= delta
	if (d <= 0):
		#clead cache since we are changing the offset of the storms
		CachedPixels.clear()
		
		d = 0.2
		
		var simspeed = SimulationManager.SimSpeed()
		
		var TimePased = Clock.Instance.TimePassedInMinutes() - LastTimeWindChanged
		if (TimePased > WindChangeMinimumTime_Minutes):
			LastTimeWindChanged = Clock.Instance.TimePassedInMinutes()
			if (randi_range(0, 1) > 0):
				WindDirectionOffset = -1
			else:
				WindDirectionOffset = 1
			#Update wind direction
		var WindRotation = randf_range(0, 0.01) * WindDirectionOffset
		WindDirection = WindDirection.rotated(WindRotation * simspeed)
		WindSpeed = clamp(WindSpeed + randf_range(-0.2, 0.2), 0, MAX_WIND_SPEED)
		#Add the new offset of the weather to the noise and produce the new texture
		#CurrentOffset -= Vector2(WindDirection.x, WindDirection.y) * (simspeed / 5000) * (WindSpeed * 0.01)
		#Mat.set_shader_parameter("offset", CurrentOffset + CurrentCamOffset)
		N.noise.offset -= Vector3(WindDirection.x, WindDirection.y, 0) * (simspeed / 10) * (WindSpeed * 0.01)
		N.noise.fractal_gain = clamp(N.noise.fractal_gain + randf_range(-0.02, 0.02) * simspeed / 10, -10, 10)
		tx = N.get_image()
		
		var L = GetLightAmm()
		
		for g in ShipsToUpdate:
			var viz = GetVisibilityInPosition(g.global_position, L)
			g.VisibilityValue = viz
			g.StormValue = StormValueInPosition(g.global_position)
			if (g is PlayerDrivenShip):
				g.UpdateLight(L, viz)
			g.RephreshVisRange()



static func GetWindVelocity() -> Vector2:
	return WindDirection * (WindSpeed / (MAX_WIND_SPEED / 2.0))

func GetVisibilityInPosition(pos : Vector2, LightValue : float) -> float:
	var value = Helper.mapvalue(1 - get_color_at_global_position(pos).r, 0.5, LightValue)
	return value

func StormValueInPosition(pos : Vector2) -> float:
	var value = get_color_at_global_position(pos).r
	return value

static func GetLightAmm() -> float:
	var t = Clock.GetHours()
	return LighAmm.sample(t)

func get_color_at_global_position(pos: Vector2) -> Color:
	var RoundedPos = Vector2i((pos - global_position) + ((CurrentCamOffset) * 6000))

	var x = Helper.normalize_value(RoundedPos.x, 0, 24000)
	var y = Helper.normalize_value(RoundedPos.y, 0, 24000)
	var WrapedPos = Vector2i(wrap(x * 512, 0, 512), wrap(y * 512, 0, 512))
		
	var col = tx.get_pixel(WrapedPos.x, WrapedPos.y)

	return col
#
#static func get_color_at_global_position(pos: Vector2) -> Color:
	#var RoundedPos = Vector2i(pos)
	#if (CachedPixels.has(RoundedPos)):
		#return CachedPixels[RoundedPos]
	## Step 3: Use the inverse transform to get the local position
	#var local_position = (inverse_transform * Vector2(RoundedPos.x, RoundedPos.y))
	#
	## Step 3: Ensure the position is within the bounds of the TextureRect
	#if local_position.x < 0 or local_position.x > rect_size.x or local_position.y < 0 or local_position.y > rect_size.y:
		#return Color(0, 0, 0, 0)  # Return transparent color if out of bounds
#
	 ## Step 5: Calculate UV coordinates based on Keep Aspect Covered
	#var texture_size = tx.get_size()
	#var rect_aspect_ratio = rect_size.x / rect_size.y
	#var texture_aspect_ratio = texture_size.x / texture_size.y
#
	#var Scl = 1.0
	#if texture_aspect_ratio > rect_aspect_ratio:
		#Scl = rect_size.x / texture_size.x  # Scale by the width
	#else:
		#Scl = rect_size.y / texture_size.y  # Scale by the height
#
	## Scaled dimensions
	#var scaled_width = texture_size.x * Scl
	#var scaled_height = texture_size.y * Scl
#
	## Offsets to center the texture based on the clipping
	#var offset_x = (rect_size.x - scaled_width) / 2.0
	#var offset_y = (rect_size.y - scaled_height) / 2.0
#
	## Map local position to UV coordinates
	#var uv = Vector2((local_position.x - offset_x) / scaled_width, 
					 #(local_position.y - offset_y) / scaled_height)
#
	##tx.lock()  # Lock the image for pixel access
	#var color = tx.get_pixel(clamp(uv.x * texture_size.x, 0, texture_size.x - 1), clamp(uv.y * texture_size.y, 0, texture_size.y - 1))
	##tx.unlock()  # Unlock after accessing
	#CachedPixels[RoundedPos] = color
	#return color


func GetSaveData() -> SaveData:
	var Sav = SaveData.new()
	Sav.DataName = "Weather"
	
	var Data = SD_WeatherMan.new()
	Data.WindDirection = WindDirection
	Data.WindSpeed = WindSpeed
	Data.Offset = N.offset
	Data.WindDirectionOffset = WindDirectionOffset
	Data.LastTimeWindChanged = LastTimeWindChanged
	Sav.Datas.append(Data)
	return Sav

func LoadSaveData(Data : SD_WeatherMan) -> void:
	WindDirection = Data.WindDirection
	WindSpeed = Data.WindSpeed
	WindDirectionOffset = Data.WindDirectionOffset
	LastTimeWindChanged = Data.LastTimeWindChanged
	N.offset = Data.Offset
	#tx = texture.get_image()
