extends Camera2D

class_name ShipCamera

static var Instance : ShipCamera
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self

static func GetInstance() -> ShipCamera:
	return Instance
