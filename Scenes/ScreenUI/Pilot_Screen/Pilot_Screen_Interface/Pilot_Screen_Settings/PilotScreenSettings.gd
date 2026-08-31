extends Control

class_name PilotScreenSettings

@export var ForecastButton : BaseButton
static var ForecastState : bool = false
@export var GridButton : BaseButton
static var GridState : bool = false
#@export var SteerButton : BaseButton
#static var SteerState : bool = true
@export var ZoomButton : BaseButton
var ZoomState : bool = false
@export var TopoButton : BaseButton
static var TopoState : bool = false
@export var WindCorrectionButton : BaseButton
static var WindCorrectionState : bool = true

@export var RadarButton : BaseButton
static var RadarState : bool = true

signal ForecastToggled(t : bool)
signal GridToggled(t : bool)
signal TopologyTogled(t : bool)
signal ZoomToggled(t : bool)
signal SteerToggled(t : bool)
signal WindCorrectionToggled(t : bool)
signal RadarToggled(t : bool)

func _ready() -> void:
	ForecastButton.set_pressed_no_signal(ForecastState)
	ForecastToggled.emit(ForecastState)
	GridButton.set_pressed_no_signal(GridState)
	GridToggled.emit(GridState)
	#SteerButton.set_pressed_no_signal(SteerState)
	#SteerToggled.emit(SteerState)
	TopoButton.set_pressed_no_signal(TopoState)
	TopologyTogled.emit(TopoState)
	ZoomButton.set_pressed_no_signal(ZoomState)
	ZoomToggled.emit(ZoomState)
	WindCorrectionButton.set_pressed_no_signal(WindCorrectionState)
	WindCorrectionToggled.emit(WindCorrectionState)
	
	RadarButton.set_pressed_no_signal(RadarState)
	

func _on_forecast_button_toggled(toggled_on: bool) -> void:
	ForecastState = toggled_on
	ForecastToggled.emit(toggled_on)


func _on_grid_button_toggled(toggled_on: bool) -> void:
	GridState = toggled_on
	GridToggled.emit(toggled_on)


#func _on_steer_button_toggled(toggled_on: bool) -> void:
	#SteerState = toggled_on
	#SteerToggled.emit(toggled_on)


func _on_topo_button_toggled(toggled_on: bool) -> void:
	TopoState = toggled_on
	TopologyTogled.emit(toggled_on)


func _on_zoom_level_button_toggled(toggled_on: bool) -> void:
	ZoomState = toggled_on
	ZoomToggled.emit(toggled_on)


func _on_wind_correction_toggled(toggled_on: bool) -> void:
	WindCorrectionState = toggled_on
	WindCorrectionToggled.emit(toggled_on)

func set_Radar(t : bool) ->void:
	RadarState = t
	RadarButton.set_pressed_no_signal(t)

func _on_radar_button_toggled(toggled_on: bool) -> void:
	RadarState = toggled_on
	RadarToggled.emit(toggled_on)
