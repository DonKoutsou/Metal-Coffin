extends ColorRect

class_name WeatherManage

@export var EventHandler : UIEventHandler
@export var WindChangeMinimumTime_Minutes : float = 20.0
#@export var N : Image
#@export_file(".tres") var NoiseFile : String

@export var G : Gradient
@export var tx : Image
#var N : NoiseTexture2D

const TEXTURE_SIZE : int = 256

const MAX_WIND_SPEED : int = 200

static var Instance : WeatherManage
static var WindDirection : Vector2
static var WindSpeed : float = 50

static var LighAmm : Curve = preload("res://Resources/LightCurve.tres")
static var ShipsToUpdate : Array[MapShip]

var Mat : ShaderMaterial
var CurrentOffset : Vector2
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
	Mat = material
	
	#Init wind direction, setting it to random dir
	WindDirection = Vector2.RIGHT.rotated(randf_range(-2 * PI, 2 * PI))
	WindSpeed = randf_range(0, MAX_WIND_SPEED)
	EventHandler.ForecastToggled.connect(ToggleWeatherMan)
	Instance = self
	LastTimeWindChanged = 0
	WindDirectionOffset = 1
	
	#Prepare noise
	#N = ResourceLoader.load(NoiseFile)

	CurrentOffset = Vector2(randf_range(-10000, 10000), randf_range(-10000, 10000))
	#N.noise.offset = Vector3(randf_range(-10000, 10000), randf_range(-10000, 10000), 0)
	
	Mat.set_shader_parameter("offset", CurrentOffset)
	#tx = N.get_image()
	#N.changed.connect(NoiseChanged)
	
	#tx = N.get_image()
	
	
	
	#await N.changed
	#Update(0)

func UpdateCameraOffset(CamOffset : Vector2) -> void:
	CurrentCamOffset = CamOffset
	Mat.set_shader_parameter("offset", CurrentCamOffset + CurrentOffset)

func ToggleWeatherMan(t : bool) -> void:
	visible = t

func Update(delta: float) -> void:
	
	var TimePased = Clock.Instance.TimePassedInMinutes() - LastTimeWindChanged
	if (TimePased > WindChangeMinimumTime_Minutes):
		LastTimeWindChanged = Clock.Instance.TimePassedInMinutes()
		if (randi_range(0, 1) > 0):
			WindDirectionOffset = -1
		else:
			WindDirectionOffset = 1
			
	#Update wind direction and speed
	var WindRotation = randf_range(0, 0.01) * WindDirectionOffset
	WindDirection = WindDirection.rotated(WindRotation * (delta * 10))
	WindSpeed = clamp(WindSpeed + randf_range(-0.2, 0.2), 0, MAX_WIND_SPEED)
	
	#Update noise
	CurrentOffset -= Vector2(WindDirection.x, WindDirection.y) * (delta * 0.01) * (WindSpeed * 0.005)
	Mat.set_shader_parameter("offset", CurrentOffset + CurrentCamOffset)
	#N.noise.offset -= Vector3(WindDirection.x, WindDirection.y, 0) * delta * (WindSpeed * 0.005)
	#N.noise.fractal_gain = clamp(N.noise.fractal_gain + randf_range(-0.02, 0.02) * (delta * 0.1), -10, 10)
	#N.noise.fractal_lacunarity = clamp(N.noise.fractal_gain + randf_range(-0.02, 0.02) * (delta * 0.1), 2, 4)
	
	var L = GetLightAmm()
	
	for g in ShipsToUpdate:
		var viz = GetVisibilityInPosition(g.global_position, L)
		g.VisibilityValue = viz
		g.StormValue = StormValueInPosition(g.global_position)
		if (g is PlayerDrivenShip):
			g.UpdateLight(L, viz)
		g.RephreshVisRange()

#func NoiseChanged() -> void:
	#tx = N.get_image()
	#tx.resize(TEXTURE_SIZE, TEXTURE_SIZE, Image.INTERPOLATE_NEAREST)

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
	var RoundedPos = Vector2i((pos - global_position) + ((CurrentCamOffset + CurrentOffset) * 6000))

	var x = Helper.normalize_value(RoundedPos.x, 0, 48000)
	var y = Helper.normalize_value(RoundedPos.y, 0, 48000)
	var WrapedPos = Vector2i(wrap(x * TEXTURE_SIZE, 0, TEXTURE_SIZE), wrap(y * TEXTURE_SIZE, 0, TEXTURE_SIZE))
		
	var col = tx.get_pixel(WrapedPos.x, WrapedPos.y)
	
	return col * G.sample(col.r)

func GetSaveData() -> SaveData:
	var Sav = SaveData.new()
	Sav.DataName = "Weather"
	
	var Data = SD_WeatherMan.new()
	Data.WindDirection = WindDirection
	Data.WindSpeed = WindSpeed
	Data.Offset = CurrentOffset
	Data.WindDirectionOffset = WindDirectionOffset
	Data.LastTimeWindChanged = LastTimeWindChanged
	Sav.Datas.append(Data)
	return Sav

func LoadSaveData(Data : SD_WeatherMan) -> void:
	WindDirection = Data.WindDirection
	WindSpeed = Data.WindSpeed
	WindDirectionOffset = Data.WindDirectionOffset
	LastTimeWindChanged = Data.LastTimeWindChanged
	CurrentOffset = Data.Offset
	#tx = texture.get_image()
