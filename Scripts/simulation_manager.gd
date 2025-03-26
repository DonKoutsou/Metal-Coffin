extends Node

class_name SimulationManager

@export var _Map : Map

static var Paused : bool = false
static var SimulationSpeed : float = 0.5

@onready var simulation_notification: SimulationNotification = $"../Map/SubViewportContainer/ViewPort/InScreenUI/Control3/SimulationNotification"


static  var Instance : SimulationManager
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
	#simulation_notification.set_physics_process(false)

static func GetInstance() -> SimulationManager:
	return Instance

static func IsPaused() -> bool:
	return Paused

static func SimSpeed() -> float:
	return SimulationSpeed

func TogglePause(t : bool) -> void:
	simulation_notification.SimPaused(t)
	Paused = t
	get_tree().call_group("Ships", "TogglePause", t)
	#Inventory.GetInstance().OnSimulationPaused(t)
	_Map.GetInScreenUI().GetInventory().OnSimulationPaused(t)
	Commander.GetInstance().OnSimulationPaused(t)
	get_tree().call_group("Pausable", "ToggleSimulation", t)
	if (Paused):
		PopUpManager.GetInstance().DoFadeNotif("Simulation paused")
	else:
		PopUpManager.GetInstance().DoFadeNotif("Simulation unpaused")
		
func SetSimulationSpeed(Speed : float) -> void:
	simulation_notification.SimSpeedUpdated(Speed)
	SimulationSpeed = Speed
	get_tree().call_group("Ships", "ChangeSimulationSpeed", SimulationSpeed)
	_Map.GetInScreenUI().GetInventory().OnSimulationSpeedChanged(SimulationSpeed)
	Commander.GetInstance().OnSimulationSpeedChanged(SimulationSpeed)
	get_tree().call_group("Clock", "SimulationSpeedChanged", SimulationSpeed)
	PopUpManager.GetInstance().DoFadeNotif("Simulation Speed changed to " + var_to_str(Speed))
func SpeedToggle(t : bool) -> void:
	if (t):
		SimulationSpeed = 5
	else:
		SimulationSpeed = 0.2
	#get_tree().call_group("Ships", "ChangeSimulationSpeed", SimulationSpeed)
	#_Map.GetInScreenUI().GetInventory().OnSimulationSpeedChanged(SimulationSpeed)
	#get_tree().call_group("Clock", "SimulationSpeedChanged", SimulationSpeed)
	#simulation_notification.SimSpeedUpdated(SimulationSpeed)
