extends Control
class_name SimulationNotification

@export var SimulationPColor: Color
@export var SimulationRColor: Color

var CurrentSimSpeed = 1

var In : bool = false
var d : float = 0.1
var Paused : bool = false
var Text : String = ""
#TODO probably a bettr wayto do this
func _physics_process(delta: float) -> void:
	var SpeedText = "[{0}{1}{2}{3}{4}{5}{6}{7}{8}{9}]"
	var FormatSpeedPlace = []
	for g in range(10, 0, -1):
		if (g - 1>= CurrentSimSpeed):
			FormatSpeedPlace.append(" ")
		else:
			FormatSpeedPlace.append("I")
	
	$SimulationNotification2.text = Text.format([SpeedText.format(FormatSpeedPlace)])
	d -= delta
	if (d > 0):
		return
	d = 0.4
	if (Paused):
		var Tw = create_tween()
		if (In):
			Tw.tween_property($SimulationNotification, "modulate", Color(1,1,1,1), 0.4)
			In = false
		else:
			Tw.tween_property($SimulationNotification, "modulate", Color(1,1,1,0), 0.4)
			In = true
	
func SimPaused(t : bool) -> void:
	if (t):
		modulate = SimulationPColor
		$SimulationNotification.text = "SIMULATION\nPAUSED"
		Text = "SPEED\n{0}"
	else:
		modulate = SimulationRColor
		$SimulationNotification.text = "SIMULATION\nRUNNING"
		Text = "SPEED\n{0}"
		var Tw = create_tween()
		Tw.tween_property($SimulationNotification, "modulate", Color(1,1,1,1), 0.4)
	#set_physics_process(t)
	Paused = t
func SimSpeedUpdated(Speed : int) -> void:
	CurrentSimSpeed = Speed
