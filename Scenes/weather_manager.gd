extends Node2D

class_name WeatherManage

@export var N : FastNoiseLite
@export var LighAmm : Curve
@export var Debug : bool = false

static var WorldBounds : Vector2

static var Instance : WeatherManage

static func GetInstance() -> WeatherManage:
	return Instance

func _ready() -> void:
	Instance = self

func _physics_process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if (!Debug):
		return
	var t = Clock.GetInstance().TimePassedInMinutes()
	N.offset.y = -t
	for g : float in range(-10, 10):
		var locx = WorldBounds.x * (g / 10.0)
		for z in range(-10, 10):
			var loc = Vector2(locx, WorldBounds.y * (z / 10.0))
			
			var Col = Color(1,1,1)
			Col *= N.get_noise_2d(loc.x, loc.y)
			draw_circle(loc, 500, Col)

func GetVisibilityInPosition(pos : Vector2) -> float:
	N.offset.y = -Clock.GetInstance().TimePassedInMinutes()
	var t = Clock.GetInstance().GetHours()
	var Maxv = LighAmm.sample(t)
	#if (t < 20 and t > 6):
		#Maxv = 1
	var value = Helper.mapvalue((N.get_noise_2d(pos.x, pos.y) + 1) / 2, 0.5, Maxv)
	return value
