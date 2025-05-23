extends Control
class_name SimulationNotification

@export var SimulationPColor: Color
@export var SimulationRColor: Color

#var CurrentSimSpeed = 1

var In : bool = false
var d : float = 0.1
var Paused : bool = false
var Text : String = ""

var Arrow : bool = false

func _ready() -> void:
	SimPaused(SimulationManager.IsPaused())
#TODO probably a bettr wayto do this
func _physics_process(delta: float) -> void:
	
	#var SpeedText = "[{0}{1}{2}{3}{4}{5}{6}{7}{8}{9}]"
	#var FormatSpeedPlace = []
	#for g in range(10, 0, -1):
		#if (g - 1>= CurrentSimSpeed):
			#FormatSpeedPlace.append(" ")
		#else:
			#FormatSpeedPlace.append("I")
	
	#$VBoxContainer2/HBoxContainer/VBoxContainer/HBoxContainer/SimulationNotification2.text = Text.format([SpeedText.format(FormatSpeedPlace)])
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
		var Tw = create_tween()
		if (In):
			Tw.tween_property($VBoxContainer2/HBoxContainer/VBoxContainer/SimulationNotification, "modulate", Color(1,1,1,1), 0.4)
			In = false
		else:
			Tw.tween_property($VBoxContainer2/HBoxContainer/VBoxContainer/SimulationNotification, "modulate", Color(1,1,1,0), 0.4)
			In = true
	
func SimPaused(t : bool) -> void:
	if (t):
		modulate = SimulationPColor
		$VBoxContainer2/HBoxContainer/VBoxContainer/SimulationNotification.text = "SIMULATION\nPAUSED"
		Text = "SPEED\n{0}"
	else:
		modulate = SimulationRColor
		$VBoxContainer2/HBoxContainer/VBoxContainer/SimulationNotification.text = "SIMULATION\nRUNNING"
		Text = "SPEED\n{0}"
		var Tw = create_tween()
		Tw.tween_property($VBoxContainer2/HBoxContainer/VBoxContainer/SimulationNotification, "modulate", Color(1,1,1,1), 0.4)
	#set_physics_process(t)
	Paused = t
#func SimSpeedUpdated(Speed : int) -> void:
	#CurrentSimSpeed = Speed
