extends PanelContainer
class_name ThrustSlider
@onready var accelleration_slider: VSlider = $HBoxContainer/AccellerationSlider
@onready var label: Label = $HBoxContainer/AccellerationSlider/Label
signal AccelerationChangeEnded(value_changed : float)
signal AccelerationChanged(value : float)

func _on_accelleration_slider_drag_ended(value_changed: bool) -> void:
	AccelerationChangeEnded.emit(value_changed)
func _on_accelleration_slider_value_changed(value: float) -> void:
	var slidersize = accelleration_slider.size.y
	label.position.y = -(slidersize / 50) * value + (slidersize) - (label.size.y / 2)
	label.text = var_to_str(roundi(value))
	AccelerationChanged.emit(value)
func ZeroAcceleration():
	var slidersize = accelleration_slider.size.y
	accelleration_slider.set_value_no_signal(0)
	label.position.y = -(slidersize / 50) * 0 + (slidersize) - (label.size.y / 2)
	label.text = var_to_str(roundi(0))
