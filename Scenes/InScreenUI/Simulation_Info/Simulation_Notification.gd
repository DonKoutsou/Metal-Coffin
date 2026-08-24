extends Control
class_name SimulationNotification

@export var SimText : Label

var In : bool = false
var Paused : bool = false
var d : float = 0.1

static var Instance : SimulationNotification

#---------------------------------------------
static func GetInstance() -> SimulationNotification:
	return Instance

#---------------------------------------------
func _ready() -> void:
	Instance = self
	TogglePause(SimulationManager.IsPaused())

#---------------------------------------------
func _physics_process(delta: float) -> void:
	d -= delta
	if (d > 0):
		return
	d = 0.4
	if (Paused):
		var Tw = create_tween()
		if (In):
			Tw.tween_property(self, "modulate", Color(1,1,1,1), 0.4)
			In = false
		else:
			Tw.tween_property(self, "modulate", Color(1,1,1,0), 0.4)
			In = true

#---------------------------------------------
func TogglePause(t : bool) -> void:
	if (t):
		visible = true
	else:
		visible = false
	Paused = t
