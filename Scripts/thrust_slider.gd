extends PanelContainer
class_name ThrustSlider
@onready var accelleration_slider: VSlider = $HBoxContainer/AccellerationSlider
signal AccelerationChangeEnded(value_changed : float)
signal AccelerationChanged(value : float)


func _on_accelleration_slider_drag_ended(value_changed: bool) -> void:
	AccelerationChangeEnded.emit(value_changed)
func _on_accelleration_slider_value_changed(value: float) -> void:
	#var slidersize = accelleration_slider.size.y
	AccelerationChanged.emit(value)
func ZeroAcceleration():
	#var slidersize = accelleration_slider.size.y
	accelleration_slider.set_value_no_signal(0)
