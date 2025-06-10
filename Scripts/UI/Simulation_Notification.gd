extends Control
class_name SimulationNotification

@export var SimulationPColor: Color
@export var SimulationSpeedColor : Color
@export var SimulationRColor: Color

var Arrow : bool = false
var In : bool = false

var Paused : bool = false
var Sped : bool = false

static var Instance : SimulationNotification

static func GetInstance() -> SimulationNotification:
	return Instance

func _ready() -> void:
	Instance = self
	SimPaused(SimulationManager.IsPaused())
	SimSpeedUpdated(SimulationManager.SimSpeed() > 1)

var d : float = 0.1
func _physics_process(delta: float) -> void:
	d -= delta
	if (d > 0):
		return
	d = 0.4
	if (Arrow):
		$VBoxContainer2/HBoxContainer2/Label4.text = "SIM PAUSE\nTO TOGGLE\n>>>>>>>>"
		Arrow = false
	else:
		$VBoxContainer2/HBoxContainer2/Label4.text = "SIM PAUSE\nTO TOGGLE\n>>>>>>>>  "
		Arrow = true
	if (Paused):
		modulate = SimulationPColor
		
		var Tw = create_tween()
		if (In):
			Tw.tween_property($VBoxContainer2/HBoxContainer/VBoxContainer/SimulationNotification, "modulate", Color(1,1,1,1), 0.4)
			In = false
		else:
			Tw.tween_property($VBoxContainer2/HBoxContainer/VBoxContainer/SimulationNotification, "modulate", Color(1,1,1,0), 0.4)
			In = true
	else:
		if (Sped):
			modulate = SimulationSpeedColor
		else:
			modulate = SimulationRColor
	
func SimPaused(t : bool) -> void:
	if (t):
		$VBoxContainer2/HBoxContainer/VBoxContainer/SimulationNotification.text = "SIMULATION\nPAUSED"
	else:
		$VBoxContainer2/HBoxContainer/VBoxContainer/SimulationNotification.text = "SIMULATION\nRUNNING"
		var Tw = create_tween()
		Tw.tween_property($VBoxContainer2/HBoxContainer/VBoxContainer/SimulationNotification, "modulate", Color(1,1,1,1), 0.4)
	Paused = t
	
func SimSpeedUpdated(SpedUp : bool) -> void:
	Sped = SpedUp
