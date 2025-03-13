extends Control
class_name ThrustSlider

@export var Handle : TextureRect
var MaxVelocityLoc : float = 0
var MinVelocityLoc : float = 0
@export var StepCOunt : int = 10

var accumulatedrelative : float = 0

signal AccelerationChangeEnded(value_changed : float)
signal AccelerationChanged(value : float)

func _ready() -> void:
	MinVelocityLoc = size.y - (Handle.size.y / 2)
	ZeroAcceleration()

func ZeroAcceleration():
	Handle.position.y = MinVelocityLoc

func ForceValue(val : float) ->void:
	var newpos = val * (MaxVelocityLoc - MinVelocityLoc) + MinVelocityLoc;
	Handle.position.y = newpos
	#var newval = (newpos - MinVelocityLoc) / (MaxVelocityLoc - MinVelocityLoc)
	#AccelerationChanged.emit(newval)
func HandleInput(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click") or event is InputEventScreenDrag):
		var step = ( MinVelocityLoc - MaxVelocityLoc ) / StepCOunt
		accumulatedrelative += event.relative.y * 1.5
		
		if (abs(accumulatedrelative) < step):
			return
		var newpos
		if (accumulatedrelative > 0):
			newpos = clamp(Handle.position.y + step, MaxVelocityLoc, MinVelocityLoc)
		else:
			newpos = clamp(Handle.position.y - step, MaxVelocityLoc, MinVelocityLoc)
		if (newpos == Handle.position.y):
			return
		Handle.position.y = newpos
		accumulatedrelative = 0
		$AudioStreamPlayer.play()
		Input.vibrate_handheld(30)
		var newval = snapped((newpos - MinVelocityLoc) / (MaxVelocityLoc - MinVelocityLoc), 0.01)
		AccelerationChanged.emit(newval)

	if (event.is_action_released("Click")):
		AccelerationChangeEnded.emit(0)
