extends PanelContainer
class_name ThrustSlider

@export var MaxVelocityLoc : float = 0
@export var MinVelocityLoc : float = 0
@export var StepCOunt : int = 10

signal AccelerationChangeEnded(value_changed : float)
signal AccelerationChanged(value : float)

func _ready() -> void:
	$TextureRect/Light.Toggle(true, true)
	#$TextureRect/Light.Toggle(true)
	
func _on_accelleration_slider_drag_ended(value_changed: bool) -> void:
	AccelerationChangeEnded.emit(value_changed)
func _on_accelleration_slider_value_changed(value: float) -> void:
	#var slidersize = accelleration_slider.size.y
	AccelerationChanged.emit(value)
func ZeroAcceleration():
	$TextureRect/Handle.position.y = MinVelocityLoc
	#var slidersize = accelleration_slider.size.y
	#accelleration_slider.set_value_no_signal(0)

func ToggleSlider():
	pass

var accumulatedrelative : float = 0

func _on_handle_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		var step = ( MinVelocityLoc - MaxVelocityLoc ) / StepCOunt
		accumulatedrelative += event.relative.y * 1.5
		if (abs(accumulatedrelative) < step):
			return
		var newpos
		if (accumulatedrelative > 0):
			newpos = clamp($TextureRect/Handle.position.y + step, MaxVelocityLoc, MinVelocityLoc)
		else:
			newpos = clamp($TextureRect/Handle.position.y - step, MaxVelocityLoc, MinVelocityLoc)
		$TextureRect/Handle.position.y = newpos
		accumulatedrelative = 0
		$AudioStreamPlayer.play()
		Input.vibrate_handheld(10)
		var newval = (newpos - MinVelocityLoc) / (MaxVelocityLoc - MinVelocityLoc)
		AccelerationChanged.emit(newval)
		$TextureRect/Light3.Toggle(newval > 0.7)
	if (event is InputEventScreenDrag):
		var step = ( MinVelocityLoc - MaxVelocityLoc ) / StepCOunt
		accumulatedrelative += event.relative.y * 1.5
		if (abs(accumulatedrelative) < step):
			return
		var newpos
		if (accumulatedrelative > 0):
			newpos = clamp($TextureRect/Handle.position.y + step, MaxVelocityLoc, MinVelocityLoc)
		else:
			newpos = clamp($TextureRect/Handle.position.y - step, MaxVelocityLoc, MinVelocityLoc)
		$TextureRect/Handle.position.y = newpos
		accumulatedrelative = 0
		$AudioStreamPlayer.play()
		Input.vibrate_handheld(10)
		var newval = (newpos - MinVelocityLoc) / (MaxVelocityLoc - MinVelocityLoc)
		AccelerationChanged.emit(newval)
		$TextureRect/Light3.Toggle(newval > 0.7)
	if (event.is_action_released("Click")):
		AccelerationChangeEnded.emit(0)
