extends Control

class_name FuelConsumptionVisuals

@export var viz : fuelViz

@export var start_eff : SpinBox
@export var eff_Escalation : SpinBox
@export var start_cap : SpinBox
@export var cap_Escalation : SpinBox
@export var W : SpinBox
@export var w_Escalation : SpinBox

func _ready() -> void:
	start_eff.value = viz.start_eff
	eff_Escalation.value = viz.eff_Escalation
	start_cap.value = viz.start_cap
	cap_Escalation.value = viz.cap_Escalation
	W.value = viz.W
	w_Escalation.value = viz.w_Escalation
	



func _on_eff_start_value_changed(value: float) -> void:
	viz.start_eff = value


func _on_eff_esc_value_changed(value: float) -> void:
	viz.eff_Escalation = value


func _on_cap_start_value_changed(value: float) -> void:
	viz.start_cap = value


func _on_cap_esc_value_changed(value: float) -> void:
	viz.cap_Escalation = value


func _on_w_start_value_changed(value: float) -> void:
	viz.W = value


func _on_w_esc_value_changed(value: float) -> void:
	viz.w_Escalation = value
