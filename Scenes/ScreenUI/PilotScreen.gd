extends Control

class_name PilotScreenUI
@export var Thrust : ThrustSlider
@export var Steer : SteeringWheelUI
@export var EventHandler : UIEventHandler
@export var ControllerEventH : ShipControllerEventHandler
@export var PilotScreenSet : PilotScreenSettings
@export_group("Buttons")
@export var SpeedSimulationButton : TextureButton
@export var ZoomDial : Dial
@export var YDial : Dial
@export var XDial : Dial

enum PILOT_UI_ELEMENTS{
	SIMULATION_BUTTON,
	SPEED_SIMULATION_BUTTON,
	MAP_MARKER_TOGGLE,
}

func GetUIElement(Element : PILOT_UI_ELEMENTS) -> Control:
	match(Element):
		PILOT_UI_ELEMENTS.SIMULATION_BUTTON:
			return $SimulationButton
		PILOT_UI_ELEMENTS.SPEED_SIMULATION_BUTTON:
			return $SpeedSimulation
		PILOT_UI_ELEMENTS.MAP_MARKER_TOGGLE:
			return $MapMarkerControls.ToggleButton
	return null
	
	
func _ready() -> void:
	ControllerEventH.OnControlledShipChanged.connect(ControlledShipSwitched)
	ControlledShipSwitched(ControllerEventH.CurrentControlled)
	EventHandler.SpeedForced.connect(ShipSpeedForced)
	EventHandler.SpeedSet.connect(ShipSpeedSet)
	EventHandler.ZoomChangedFromScreen.connect(ZoomDial.AddCustomMovement)
	EventHandler.YChangedFromScreen.connect(YDial.AddCustomMovement)
	EventHandler.XChangedFromScreen.connect(XDial.AddCustomMovement)
	UISoundMan.GetInstance().Refresh()
	
	SpeedSimulationButton.set_pressed_no_signal(SimulationManager.SimSpeed() > 1)
	_on_steer_button_toggled(PilotScreenSet.SteerState)

func SpeedUpdated(t : bool) -> void:
	SpeedSimulationButton.set_pressed_no_signal(t)
	SpeedSimulationButton.button_down.emit()

func ShipSpeedSet(NewSpeed : float) -> void:
	Thrust.UpdateHandle(NewSpeed)

func ShipSpeedForced(NewSpeed : float) -> void:
	Thrust.ForceValue(NewSpeed)

func ControlledShipSwitched(NewShip : MapShip) -> void:
	Thrust.ForceValue(NewShip.GetShipSpeed() / NewShip.GetShipMaxSpeed())
	Steer.ForceSteer(NewShip.rotation)

func Acceleration_Ended(value_changed: float) -> void:
	EventHandler.OnAccelerationEnded(value_changed)

func Acceleration_Changed(value: float) -> void:
	EventHandler.OnAccelerationChanged(value)


func Steering_Direction_Changed(NewValue: float) -> void:
	EventHandler.OnSteeringDirectionChanged(NewValue)


func Steer_Offseted(Offset: float) -> void:
	EventHandler.OnSteerOffseted(Offset)


func _on_speed_simulation_toggled(toggled_on: bool) -> void:
	SimulationManager.GetInstance().SpeedToggle(toggled_on)


func Sim_Pause_Pressed() -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	var simmulationPaused = !SimulationManager.GetInstance().Paused
	SimulationManager.GetInstance().TogglePause(simmulationPaused)


func Inventory_Pressed() -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	EventHandler.OnInventoryPressed()


func Regroup_Pressed() -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	EventHandler.OnRegroupPressed()


func Open_Hatch_Button_Pressed() -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	EventHandler.OnOpenHatchPressed()


func Radar_Button_Pressed() -> void:
	EventHandler.OnRadarButtonPressed()


func Land_Pressed() -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	EventHandler.OnLandPressed()

func Pause_Pressed() -> void:
	EventHandler.OnPausePressed()

########## BUTTON PRESS EVENTS ###########
func Marker_Editor_Button_Pressed() -> void:
	EventHandler.OnMarkerEditorToggled(false)

func Ship_Dock_Button_Pressed() -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	EventHandler.OnFleetSeparationPressed()

func _on_steer_button_toggled(toggled_on: bool) -> void:
	Steer.Toggle(toggled_on)


func _on_forecast_button_toggled(toggled_on: bool) -> void:
	EventHandler.OnForecastPressed(toggled_on)

func _on_grid_button_toggled(toggled_on: bool) -> void:
	EventHandler.OnGridPressed(toggled_on)

func _on_zoom_level_button_toggled(toggled_on: bool) -> void:
	EventHandler.OnZoomTogglePressed(toggled_on)

func _on_team_button_toggled(toggled_on: bool) -> void:
	EventHandler.OnTeamTogglePressed(toggled_on)

func _on_sonar_button_toggled(toggled_on: bool) -> void:
	EventHandler.OnSonarPressed(toggled_on)

func _on_zoom_dial_range_changed(NewVal: float) -> void:
	EventHandler.OnZoomDialMoved(-NewVal / 10)

func _on_y_dial_range_changed(NewVal: float) -> void:
	EventHandler.OnYDialMoved(-NewVal * 10)

func _on_x_dial_range_changed(NewVal: float) -> void:
	EventHandler.OnXDialMoved(-NewVal * 10)
