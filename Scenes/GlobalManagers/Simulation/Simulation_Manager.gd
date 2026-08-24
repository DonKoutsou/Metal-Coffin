extends Node

class_name SimulationManager

signal SpeedChanged(t : bool)
signal SimulationToggled(t : bool)

static var Paused : bool = true
static var SimulationSpeed : float = 0.2
static  var Instance : SimulationManager

#----------------------------------------------------------
func _ready() -> void:
	Instance = self
	Paused = false
	SimulationSpeed = 0.2

#----------------------------------------------------------
static func GetInstance() -> SimulationManager:
	return Instance

#----------------------------------------------------------
static func IsPaused() -> bool:
	return Paused

#----------------------------------------------------------
static func SimSpeed() -> float:
	return SimulationSpeed

#----------------------------------------------------------
func TogglePause(t : bool) -> void:
	Paused = t

	if (Paused):
		PopUpManager.GetInstance().DoFadeNotif("Simulation paused")
	else:
		PopUpManager.GetInstance().DoFadeNotif("Simulation unpaused")
		
	get_tree().call_group("Ships", "TogglePause", t)
	get_tree().call_group("Pausable", "ToggleSimulation", t)
	SimulationToggled.emit(t)

#----------------------------------------------------------
func _input(event: InputEvent) -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	if (CommandLine.Typing):
		return
	if (event.is_action_pressed("PauseSim")):
		TogglePause(!Paused)
	if (event.is_action_pressed("SpeedSim")):
		SpeedToggle(true)
	if (event.is_action_released("SpeedSim")):
		SpeedToggle(false)

#----------------------------------------------------------
func SpeedToggle(t : bool) -> void:
	if (t):
		SimulationSpeed = 2
		PopUpManager.GetInstance().DoFadeNotif("Simulation speed enabled")
	else:
		SimulationSpeed = 0.2
		PopUpManager.GetInstance().DoFadeNotif("Simulation speed dissabled")
		
	SpeedChanged.emit(t)
