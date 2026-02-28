extends Control

class_name PilotScreenUI

@export_group("Event_Handlers")
@export var ui_event_handler : UIEventHandler
@export var controller_event_handler : ShipControllerEventHandler

@export_group("UI_Elements")
@export var elint : ElingUI
@export var map_marker_controls : MapMarkerControls
@export var Thrust : ThrustSlider
@export var ElevationThrust : ThrustSlider
@export var Steer : SteeringWheelUI
@export var PilotScreenSet : PilotScreenSettings
@export var SpeedSimulationButton : TextureButton
@export var PauseSimulationButton : Button
@export var regroup_button : Button
@export var ship_dock_button : Button
@export var radar_button : Button
@export var ZoomDial : Dial
@export var YDial : Dial
@export var XDial : Dial
@export var MisisleUI : MissileTab
	
	
func _ready() -> void:
	controller_event_handler.OnControlledShipChanged.connect(ControlledShipSwitched)
	
	ControlledShipSwitched(controller_event_handler.CurrentControlled)
	
	ui_event_handler.SpeedForced.connect(ShipSpeedForced)
	ui_event_handler.SpeedSet.connect(ShipSpeedSet)
	ui_event_handler.SteerForced.connect(ShipSteerForced)
	ui_event_handler.SteerSet.connect(ShipSteerSet)
	ui_event_handler.ElevationForced.connect(ShipElevationForced)
	#ui_event_handler.ElevationSet.connect(ShipElevationSet)

	ui_event_handler.ZoomChangedFromScreen.connect(ZoomDial.addCustomMovement)
	ui_event_handler.YChangedFromScreen.connect(YDial.addCustomMovement)
	ui_event_handler.XChangedFromScreen.connect(XDial.addCustomMovement)
	UISoundMan.GetInstance().Refresh()
	
	SpeedSimulationButton.set_pressed_no_signal(SimulationManager.SimSpeed() > 1)
	PauseSimulationButton.set_pressed_no_signal(!SimulationManager.IsPaused())
	_on_steer_button_toggled(PilotScreenSet.SteerState)

#--------------------------------------------------
#INCOMMING

func SpeedUpdated(t : bool) -> void:
	SpeedSimulationButton.set_pressed_no_signal(t)
	SpeedSimulationButton.button_down.emit()

func SimulationToggled(t : bool) -> void:
	PauseSimulationButton.set_pressed_no_signal(!t)
	PauseSimulationButton.button_down.emit()

func ShipSpeedSet(NewSpeed : float) -> void:
	Thrust.UpdateHandle(NewSpeed)


func ShipSpeedForced(NewSpeed : float) -> void:
	Thrust.ForceValue(NewSpeed)


func ShipSteerSet(NewSpeed : float) -> void:
	Steer.ForceSteer(NewSpeed)


func ShipSteerForced(NewSpeed : float) -> void:
	Steer.ForceSteer(NewSpeed)

	
func ShipElevationSet(NewSpeed : float) -> void:
	ElevationThrust.UpdateHandle(NewSpeed)


func ShipElevationForced(NewSpeed : float) -> void:
	ElevationThrust.ForceValue(NewSpeed)


func ControlledShipSwitched(NewShip : MapShip) -> void:
	Thrust.ForceValue(NewShip.GetShipSpeed() / NewShip.GetShipMaxSpeed())
	ElevationThrust.ForceValue(NewShip.TargetAltitude / 10000)
	Steer.SyncSteer(NewShip.rotation + NewShip.StoredSteer)
	
#--------------------------------------------------
#OUTGOING

func _on_altitude_dial_range_changed(NewVal: float) -> void:
	controller_event_handler.OnTargetAltitudeChanged(NewVal)

func _on_steer_button_toggled(toggled_on: bool) -> void:
	Steer.Toggle(toggled_on)

func _on_speed_simulation_toggled(toggled_on: bool) -> void:
	SimulationManager.GetInstance().SpeedToggle(toggled_on)

func Sim_Pause_Toggled(toggled_on: bool) -> void:
	SimulationManager.GetInstance().TogglePause(!toggled_on)

func Acceleration_Ended(value_changed: float) -> void:
	ui_event_handler.OnAccelerationEnded(value_changed)

func Acceleration_Changed(value: float) -> void:
	ui_event_handler.OnAccelerationChanged(value)

func Elevation_Ended(value_changed: float) -> void:
	ui_event_handler.OnElevationEnded(value_changed)
	#ElevationThrust.UpdateHandle(value_changed)

func Elevation_Changed(value: float) -> void:
	ui_event_handler.OnElevationChanged(value)
	ElevationThrust.UpdateHandle(value)

func Steering_Direction_Changed(NewValue: float) -> void:
	ui_event_handler.OnSteeringDirectionChanged(NewValue)

func Steer_Offseted(Offset: float) -> void:
	ui_event_handler.OnSteerOffseted(Offset)

func Inventory_Pressed() -> void:
	ui_event_handler.OnInventoryPressed()

func Regroup_Pressed() -> void:
	ui_event_handler.OnRegroupPressed()

func Open_Hatch_Button_Pressed() -> void:
	ui_event_handler.OnOpenHatchPressed()

func Radar_Button_Pressed() -> void:
	ui_event_handler.OnRadarButtonPressed()

func Land_Pressed() -> void:
	ui_event_handler.OnLandPressed()

func Pause_Pressed() -> void:
	ui_event_handler.OnPausePressed()

func Marker_Editor_Button_Pressed() -> void:
	ui_event_handler.OnMarkerEditorToggled(false)

func Ship_Dock_Button_Pressed() -> void:
	ui_event_handler.OnFleetSeparationPressed()

func _on_forecast_button_toggled(toggled_on: bool) -> void:
	ui_event_handler.OnForecastPressed(toggled_on)

func _on_grid_button_toggled(toggled_on: bool) -> void:
	ui_event_handler.OnGridPressed(toggled_on)

func _on_zoom_level_button_toggled(toggled_on: bool) -> void:
	ui_event_handler.OnZoomTogglePressed(toggled_on)

func _on_altitude_toggled(toggled_on: bool) -> void:
	ui_event_handler.OnAltTogglePressed(toggled_on)
	
func _on_team_button_toggled(toggled_on: bool) -> void:
	ui_event_handler.OnTeamTogglePressed(toggled_on)
	
func _on_sonar_button_toggled(toggled_on: bool) -> void:
	ui_event_handler.OnSonarPressed(toggled_on)
func _on_zoom_dial_range_changed(NewVal: float) -> void:
	ui_event_handler.OnZoomDialMoved(-NewVal / 10)
	
func _on_y_dial_range_changed(NewVal: float) -> void:
	ui_event_handler.OnYDialMoved(-NewVal * 10)

func _on_x_dial_range_changed(NewVal: float) -> void:
	ui_event_handler.OnXDialMoved(-NewVal * 10)

func _on_topo_button_toggled(toggled_on: bool) -> void:
	ui_event_handler.OnTopoPressed(toggled_on)
