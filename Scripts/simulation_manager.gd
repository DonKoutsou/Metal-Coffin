extends Control

class_name SimulationManager

static var Paused : bool = false
static var SimulationSpeed : int = 1

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
	get_tree().call_group("Clock", "ToggleSimulation", t)

func SpeedToggle(t : bool) -> void:
	if (t):
		SimulationSpeed = 10
	else:
		SimulationSpeed = 1
	get_tree().call_group("Ships", "ChangeSimulationSpeed", SimulationSpeed)
	$"../VBoxContainer/Inventory".OnSimulationSpeedChanged(SimulationSpeed)
	get_tree().call_group("Clock", "SimulationSpeedChanged", SimulationSpeed)
