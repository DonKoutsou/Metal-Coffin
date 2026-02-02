extends Control

class_name PilotScreenUI

@export var ScreenItems : Control
@export var MarkerEditorControls : MapMarkerControls
@export var Thrust : ThrustSlider
@export var Steer : SteeringWheelUI
@export var MissileUI : MissileTab
@export var EventHandler : UIEventHandler
@export_group("Buttons")
@export var LandButton : TextureButton
@export var HatchButton : TextureButton
@export var ShipDockButton : TextureButton
@export var RegroupButton : TextureButton
@export var SimulationButton : TextureButton
@export var SpeedSimulationButton : TextureButton
@export var MapMarkerButton : TextureButton


func _ready() -> void:
	#MissileUI.MissileLaunched.connect(Cam.EnableMissileShake)
	EventHandler.ScreenUIToggled.connect(ToggleScreenUI)
	EventHandler.ShipUpdated.connect(ControlledShipSwitched)
	EventHandler.SpeedSet.connect(ShipSpeedSet)
	EventHandler.SpeedForced.connect(ShipSpeedForced)

var ScreenItemsStateBeforePause : bool

func SpeedUpdated(t : bool) -> void:
	SpeedSimulationButton.set_pressed_no_signal(t)
	SpeedSimulationButton.button_down.emit()

func ShipSpeedSet(NewSpeed : float) -> void:
	Thrust.UpdateHandle(NewSpeed)

func ShipSpeedForced(NewSpeed : float) -> void:
	Thrust.ForceValue(NewSpeed)

func ControlledShipSwitched(NewShip : MapShip) -> void:
	MissileUI.UpdateConnectedShip(NewShip)
	Thrust.ForceValue(NewShip.GetShipSpeed() / NewShip.GetShipMaxSpeed())
	Steer.ForceSteer(NewShip.rotation)

func ToggleScreenUI(t : bool) -> void:
	ScreenItems.visible = t

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

func TownVisited(t : bool) -> void:
	if (t):
		ScreenItemsStateBeforePause = ScreenItems.visible
		ScreenItems.visible = false
	else:
		ScreenItems.visible = ScreenItemsStateBeforePause

func Pause_Pressed() -> void:
	if (!get_tree().paused):
		ScreenItemsStateBeforePause = ScreenItems.visible
		ScreenItems.visible = false
	else:
		ScreenItems.visible = ScreenItemsStateBeforePause
	EventHandler.OnPausePressed()

########## BUTTON PRESS EVENTS ###########
func Marker_Editor_Button_Pressed() -> void:
	MissileUI.TurnOff()
	EventHandler.OnMarkerEditorToggled(false)

func Ship_Dock_Button_Pressed() -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	EventHandler.OnFleetSeparationPressed()


func Missile_Button_Pressed() -> void:
	MissileUI.Toggle()
	#MarkerEditorControls.TurnOff()

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
