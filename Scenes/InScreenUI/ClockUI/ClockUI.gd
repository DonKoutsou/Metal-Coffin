extends Control

class_name ClockUI

@export var hour_Label : Label
@export var day_Label : Label

func _ready() -> void:
	var HourString = Clock.CheckNumber(var_to_str(Clock.currentHour)) + " : " + Clock.CheckNumber(var_to_str(roundi(Clock.currentMin)))
	var DayString = Clock.CheckNumber(var_to_str(Clock.CurrentDay)) + " / " + Clock.CheckNumber(var_to_str(Clock.CurrentMonth)) + " / " + var_to_str(Clock.CurrentYear)
	hour_Label.text = HourString
	day_Label.text = DayString
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	var HourString = Clock.CheckNumber(var_to_str(Clock.currentHour)) + " : " + Clock.CheckNumber(var_to_str(roundi(Clock.currentMin)))
	var DayString = Clock.CheckNumber(var_to_str(Clock.CurrentDay)) + " / " + Clock.CheckNumber(var_to_str(Clock.CurrentMonth)) + " / " + var_to_str(Clock.CurrentYear)
	hour_Label.text = HourString
	if (SimulationManager.Paused):
		hour_Label.text += " ||"
	else: if (SimulationManager.SimSpeed() > 1):
		hour_Label.text += " >>"
	else:
		hour_Label.text += " >"
	day_Label.text = DayString
