extends Resource
class_name PlayerData

@export var HP = 100
@export var HULLHP = 100
@export var HULL_MAX_HP = 100
@export var FUEL_TANK_SIZE = 80
@export var FUEL = 80
@export var FUEL_EFFICIENCY = 1.0
@export var VIZ_RANGE = 600
@export var ANALYZE_RANGE = 300
@export var OXYGEN = 100
@export var OXYGEN_TANK_SIZE = 100

static var Instance

func _init() -> void:
	Instance = self
	
static func GetInstance() -> PlayerData:
	return Instance
