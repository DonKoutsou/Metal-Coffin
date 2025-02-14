extends Control
class_name SimulationNotification

@export var SimulationPColor: Color
@export var SimulationRColor: Color

var CurrentSimSpeed = 1

var In : bool = false
var d : float = 0.1
var Paused : bool = false

#TODO probably a bettr wayto do this
func _physics_process(delta: float) -> void:
	d -= delta
	if (d > 0):
		return
	d = 0.4
	if (Paused):
		$SimulationNotification.text = "SIMULATION\nPAUSED\nSPEED {0}".format([CurrentSimSpeed])
		var Tw = create_tween()
		if (In):
			Tw.tween_property($SimulationNotification, "modulate", Color(1,1,1,1), 0.4)
			In = false
		else:
			Tw.tween_property($SimulationNotification, "modulate", Color(1,1,1,0), 0.4)
			In = true
	else:
		$SimulationNotification.text = "SIMULATION\nRUNNING\nSPEED {0}".format([CurrentSimSpeed])
func SimPaused(t : bool) -> void:
	if (t):
		modulate = SimulationPColor
		$SimulationNotification.text = "SIMULATION\nPAUSED\nSPEED {0}".format([CurrentSimSpeed])
	else:
		modulate = SimulationRColor
		$SimulationNotification.text = "SIMULATION\nRUNNING\nSPEED {0}".format([CurrentSimSpeed])
		var Tw = create_tween()
		Tw.tween_property($SimulationNotification, "modulate", Color(1,1,1,1), 0.4)
	#set_physics_process(t)
	Paused = t
func SimSpeedUpdated(Speed : int) -> void:
	CurrentSimSpeed = Speed
