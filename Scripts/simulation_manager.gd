extends Node

class_name SimulationManager

@export var _Map : Map

static var Paused : bool = false
static var SimulationSpeed : int = 1

@onready var simulation_notification: SimulationNotification = $"../Map/SubViewportContainer/ViewPort/InScreenUI/Control3/SimulationNotification"


static  var Instance : SimulationManager
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
	simulation_notification.visible = false
	simulation_notification.set_physics_process(false)

static func GetInstance() -> SimulationManager:
	return Instance

static func IsPaused() -> bool:
	return Paused
	
func TogglePause(t : bool) -> void:
	simulation_notification.visible = t
	simulation_notification.set_physics_process(t)
	Paused = t
	get_tree().call_group("Ships", "TogglePause", t)
	#Inventory.GetInstance().OnSimulationPaused(t)
	_Map.GetInScreenUI().GetInventory().OnSimulationPaused(t)
	Commander.GetInstance().OnSimulationPaused(t)
	get_tree().call_group("Pausable", "ToggleSimulation", t)
	

func SetSimulationSpeed(Speed : int) -> void:
	SimulationSpeed = Speed
	get_tree().call_group("Ships", "ChangeSimulationSpeed", SimulationSpeed)
	_Map.GetInScreenUI().GetInventory().OnSimulationSpeedChanged(SimulationSpeed)
	Commander.GetInstance().OnSimulationSpeedChanged(SimulationSpeed)
	get_tree().call_group("Clock", "SimulationSpeedChanged", SimulationSpeed)

func SpeedToggle(t : bool) -> void:
	if (t):
		SimulationSpeed = 10
	else:
		SimulationSpeed = 1
	get_tree().call_group("Ships", "ChangeSimulationSpeed", SimulationSpeed)
	_Map.GetInScreenUI().GetInventory().OnSimulationSpeedChanged(SimulationSpeed)
	get_tree().call_group("Clock", "SimulationSpeedChanged", SimulationSpeed)
