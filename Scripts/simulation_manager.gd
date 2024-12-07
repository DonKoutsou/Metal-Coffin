extends Control

class_name SimulationManager

static var Paused : bool = false

static  var Instance : SimulationManager
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
	$Label.visible = false

static func GetInstance() -> SimulationManager:
	return Instance

static func IsPaused() -> bool:
	return Paused
	
func TogglePause(t : bool) -> void:
	$Label.visible = t
	Paused = t
	get_tree().call_group("Ships", "TogglePause", t)
	$"../VBoxContainer/Inventory".OnSimulationPaused(t)
