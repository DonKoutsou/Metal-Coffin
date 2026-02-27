extends PanelContainer

class_name PilotScreenSettings

@export var ForecastButton : Button
static var ForecastState : bool = false
@export var GridButton : Button
static var GridState : bool = true
@export var SteerButton : Button
static var SteerState : bool = true
@export var ZoomButton : Button
var ZoomState : bool = true
@export var TopoButton : Button
static var TopoState : bool = false

signal ForecastToggled(t : bool)
signal GridToggled(t : bool)
signal TopologyTogled(t : bool)
signal ZoomToggled(t : bool)
signal SteerToggled(t : bool)

func _ready() -> void:
	ForecastButton.set_pressed_no_signal(ForecastState)
	ForecastToggled.emit(ForecastState)
	GridButton.set_pressed_no_signal(GridState)
	GridToggled.emit(GridState)
	SteerButton.set_pressed_no_signal(SteerState)
	SteerToggled.emit(SteerState)
	TopoButton.set_pressed_no_signal(TopoState)
	TopologyTogled.emit(TopoState)
	ZoomButton.set_pressed_no_signal(ZoomState)
	ZoomToggled.emit(ZoomState)
	

func _on_forecast_button_toggled(toggled_on: bool) -> void:
	ForecastState = toggled_on
	ForecastToggled.emit(toggled_on)


func _on_grid_button_toggled(toggled_on: bool) -> void:
	GridState = toggled_on
	GridToggled.emit(toggled_on)


func _on_steer_button_toggled(toggled_on: bool) -> void:
	SteerState = toggled_on
	SteerToggled.emit(toggled_on)


func _on_topo_button_toggled(toggled_on: bool) -> void:
	TopoState = toggled_on
	TopologyTogled.emit(toggled_on)


func _on_zoom_level_button_toggled(toggled_on: bool) -> void:
	ZoomState = toggled_on
	ZoomToggled.emit(toggled_on)
