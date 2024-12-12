extends Control

var CurrentDay : int = 1
var currentHour : int = 13
var currentMin : float = 0

var SimulationSpeed : int = 1
var SimulationPaused : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var rot = (360.0/12.0)*currentHour
	$Hour.rotation = deg_to_rad(rot)
	$Label.text = "Day : " + var_to_str(CurrentDay)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if (SimulationPaused):
		return
	currentMin += (delta * 10) * SimulationSpeed
	if (currentMin >= 60):
		currentHour += 1
		if (currentHour >= 24):
			currentHour = 0
			CurrentDay += 1
			$Label.text = "Day : " + var_to_str(CurrentDay)
		currentMin = 0
		
	var rot = (360.0/60.0)*currentMin
	$Min.rotation = deg_to_rad(rot)
	var Hrot = (360.0/12.0)* currentHour
	$Hour.rotation = deg_to_rad(Hrot + (rot / 12))

func ToggleSimulation(t : bool) -> void:
	SimulationPaused = t
func SimulationSpeedChanged(i : int) -> void:
	SimulationSpeed = i
