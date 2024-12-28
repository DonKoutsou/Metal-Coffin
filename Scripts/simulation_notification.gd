extends Label
class_name SimulationNotification
var In : bool = false
var d : float = 0.1
static var Instance : SimulationNotification
func _ready() -> void:
	Instance = self
static func GetInstance()-> SimulationNotification:
	return Instance
func _physics_process(delta: float) -> void:
	d -= delta
	if (d > 0):
		return
	d = 0.4
	var Tw = create_tween()
	if (In):
		Tw.tween_property(self, "modulate", Color(1,1,1,1), 0.4)
		In = false
	else:
		Tw.tween_property(self, "modulate", Color(1,1,1,0), 0.4)
		In = true
