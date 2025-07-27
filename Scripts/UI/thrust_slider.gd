extends Control
class_name ThrustSlider

@export var Handle : TextureRect
var MaxVelocityLoc : float = 0
var MinVelocityLoc : float = 0
@export var StepCOunt : int = 10

var accumulatedrelative : float = 0

signal AccelerationChangeEnded(value_changed : float)
signal AccelerationChanged(value : float)

var step

func _ready() -> void:
	MinVelocityLoc = size.y - (Handle.size.y / 2)
	ZeroAcceleration()
	step = ( MinVelocityLoc - MaxVelocityLoc ) / StepCOunt

func ZeroAcceleration():
	Handle.position.y = MinVelocityLoc

var forceTw : Tween
func ForceValue(val : float) ->void:
	var ForcedValue = clamp(val, 0, 1)
	var newpos = ForcedValue * (MaxVelocityLoc - MinVelocityLoc) + MinVelocityLoc
	if (forceTw != null):
		forceTw.kill()
	
	forceTw = create_tween()
	
	var NewPositio = Vector2(Handle.position.x, newpos)
	
	forceTw.tween_property(Handle, "position", NewPositio, NewPositio.distance_squared_to(Handle.position) / 1000000)
	
	#Handle.position.y = newpos
	#var newval = (newpos - MinVelocityLoc) / (MaxVelocityLoc - MinVelocityLoc)
	#AccelerationChanged.emit(newval)

func GetThrustPosition() -> Vector2:
	return Handle.global_position

func _physics_process(_delta: float) -> void:
	if (abs(accumulatedrelative) < step):
		AccelerationChangeEnded.emit(0)
		set_physics_process(false)
		return
	var newpos
	if (accumulatedrelative > 0):
		newpos = clamp(Handle.position.y + step, MaxVelocityLoc, MinVelocityLoc)
		accumulatedrelative -= step
	else:
		newpos = clamp(Handle.position.y - step, MaxVelocityLoc, MinVelocityLoc)
		accumulatedrelative += step

	#Handle.position.y = newpos
	$AudioStreamPlayer.play()
	Input.vibrate_handheld(30)
	var newval = snapped((newpos - MinVelocityLoc) / (MaxVelocityLoc - MinVelocityLoc), 0.01)
	AccelerationChanged.emit(newval)

func HandleInput(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click") or event is InputEventScreenDrag):
		accumulatedrelative += event.relative.y
		if (abs(accumulatedrelative) > step):
			set_physics_process(true)
		

	if (event.is_action_released("Click")):
		AccelerationChangeEnded.emit(0)
