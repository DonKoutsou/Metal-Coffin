extends Node

class_name SimulationManager

@export var _Map : Map

static var Paused : bool = false
static var SimulationSpeed : float = 0.2

signal SpeedChanged(t : bool)

static  var Instance : SimulationManager

var SimulationNotif : SimulationNotification
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Instance = self
	Paused = false
	SimulationSpeed = 0.2
	SimulationNotif = SimulationNotification.GetInstance()

static func GetInstance() -> SimulationManager:
	return Instance

static func IsPaused() -> bool:
	return Paused

static func SimSpeed() -> float:
	return SimulationSpeed

func TogglePause(t : bool) -> void:
	SimulationNotification.GetInstance().SimPaused(t)
	Paused = t
	get_tree().call_group("Ships", "TogglePause", t)
	#Inventory.GetInstance().OnSimulationPaused(t)
	_Map.GetInScreenUI().GetInventory().OnSimulationPaused(t)
	#Commander.GetInstance().OnSimulationPaused(t)
	get_tree().call_group("Pausable", "ToggleSimulation", t)
	if (Paused):
		PopUpManager.GetInstance().DoFadeNotif("Simulation paused")
	else:
		PopUpManager.GetInstance().DoFadeNotif("Simulation unpaused")
	
	#get_child(0).TogglePause(t)

func _input(event: InputEvent) -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	if (event.is_action_pressed("PauseSim")):
		TogglePause(!Paused)
	if (event.is_action_pressed("SpeedSim")):
		SpeedToggle(true)
	if (event.is_action_released("SpeedSim")):
		SpeedToggle(false)
	

func SetSimulationSpeed(Speed : float) -> void:
	SimulationNotification.GetInstance().SimSpeedUpdated(Speed > 1)
	SimulationSpeed = Speed
	#get_tree().call_group("Ships", "ChangeSimulationSpeed", SimulationSpeed)
	_Map.GetInScreenUI().GetInventory().OnSimulationSpeedChanged(SimulationSpeed)
	#Commander.GetInstance().OnSimulationSpeedChanged(SimulationSpeed)
	#get_tree().call_group("Clock", "SimulationSpeedChanged", SimulationSpeed)
	PopUpManager.GetInstance().DoFadeNotif("Simulation Speed changed to " + var_to_str(Speed))
	
func SpeedToggle(t : bool) -> void:
	if (t):
		SimulationSpeed = 2
		PopUpManager.GetInstance().DoFadeNotif("Simulation speed enabled")
	else:
		SimulationSpeed = 0.2
		PopUpManager.GetInstance().DoFadeNotif("Simulation speed dissabled")
	SpeedChanged.emit(t)
	#SimulationNotification.GetInstance().SimSpeedUpdated(t)
	#get_child(0).SpeedToggle(t)
	#get_tree().call_group("Ships", "ChangeSimulationSpeed", SimulationSpeed)
	#_Map.GetInScreenUI().GetInventory().OnSimulationSpeedChanged(SimulationSpeed)
	#get_tree().call_group("Clock", "SimulationSpeedChanged", SimulationSpeed)
	#simulation_notification.SimSpeedUpdated(SimulationSpeed)
