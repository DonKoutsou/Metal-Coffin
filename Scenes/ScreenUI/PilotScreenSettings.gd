extends PanelContainer

class_name PilotScreenSettings

@export var ForecastButton : Button
static var ForecastState : bool = false
@export var GridButton : Button
static var GridState : bool = true
@export var SteerButton : Button
static var SteerState : bool = true
@export var ZoomButton : Button
@export var ZoomState : bool = true

func _ready() -> void:
	ForecastButton.set_pressed_no_signal(ForecastState)
	GridButton.set_pressed_no_signal(GridState)
	SteerButton.set_pressed_no_signal(SteerState)


func _on_forecast_button_toggled(toggled_on: bool) -> void:
	ForecastState = toggled_on


func _on_grid_button_toggled(toggled_on: bool) -> void:
	GridState = toggled_on


func _on_steer_button_toggled(toggled_on: bool) -> void:
	SteerState = toggled_on
