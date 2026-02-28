extends Control
class_name PilotScreenUI

# --- EXPORTED REFERENCES ---

@export_group("Event_Handlers")
@export var uiEventHandler: UIEventHandler
@export var controllerEventHandler: ShipControllerEventHandler

@export_group("UI_Elements")
@export var elint: ElingUI
@export var mapMarkerControls: MapMarkerControls
@export var thrust: ThrustSlider
@export var elevationThrust: ThrustSlider
@export var steer: SteeringWheelUI
@export var pilotScreenSet: PilotScreenSettings
@export var speedSimulationButton: TextureButton
@export var pauseSimulationButton: Button
@export var regroupButton: Button
@export var shipDockButton: Button
@export var radarButton: Button
@export var zoomDial: Dial
@export var yDial: Dial
@export var xDial: Dial
@export var missileUI: MissileTab

# --- INITIALIZATION ---

func _ready() -> void:
	controllerEventHandler.OnControlledShipChanged.connect(controlledShipSwitched)
	controlledShipSwitched(controllerEventHandler.CurrentControlled)
	
	uiEventHandler.SpeedForced.connect(shipSpeedForced)
	uiEventHandler.SpeedSet.connect(shipSpeedSet)
	
	uiEventHandler.ElevationForced.connect(shipElevationForced)
	# uiEventHandler.ElevationSet.connect(shipElevationSet)

	uiEventHandler.ZoomChangedFromScreen.connect(zoomDial.addCustomMovement)
	uiEventHandler.YChangedFromScreen.connect(yDial.addCustomMovement)
	uiEventHandler.XChangedFromScreen.connect(xDial.addCustomMovement)
	
	UISoundMan.GetInstance().Refresh()
	
	speedSimulationButton.set_pressed_no_signal(SimulationManager.SimSpeed() > 1)
	pauseSimulationButton.set_pressed_no_signal(!SimulationManager.IsPaused())
	_onSteerButtonToggled(pilotScreenSet.SteerState)

# --- INCOMING EVENTS FROM GAME LOGIC ---

func speedUpdated(enabled: bool) -> void:
	speedSimulationButton.set_pressed_no_signal(enabled)
	speedSimulationButton.button_down.emit()

func simulationToggled(paused: bool) -> void:
	pauseSimulationButton.set_pressed_no_signal(!paused)
	pauseSimulationButton.button_down.emit()

func shipSpeedSet(newSpeed: float) -> void:
	thrust.UpdateHandle(newSpeed)

func shipSpeedForced(newSpeed: float) -> void:
	thrust.ForceValue(newSpeed)



func shipElevationSet(newValue: float) -> void:
	elevationThrust.UpdateHandle(newValue)

func shipElevationForced(newValue: float) -> void:
	elevationThrust.ForceValue(newValue)

func controlledShipSwitched(newShip: MapShip) -> void:
	thrust.ForceValue(newShip.GetShipSpeed() / newShip.GetShipMaxSpeed())
	elevationThrust.ForceValue(newShip.TargetAltitude / 10000)  # Assume altitude scaling

# --- OUTGOING EVENTS TO GAME LOGIC/UI DISPATCH ---

func _on_altitude_dial_range_changed(newVal: float) -> void:
	controllerEventHandler.OnTargetAltitudeChanged(newVal)

func _onSteerButtonToggled(toggledOn: bool) -> void:
	steer.Toggle(toggledOn)

func _on_speed_simulation_toggled(toggledOn: bool) -> void:
	SimulationManager.GetInstance().SpeedToggle(toggledOn)

func simPauseToggled(toggledOn: bool) -> void:
	SimulationManager.GetInstance().TogglePause(!toggledOn)

func accelerationEnded(valueChanged: float) -> void:
	uiEventHandler.OnAccelerationEnded(valueChanged)

func accelerationChanged(value: float) -> void:
	uiEventHandler.OnAccelerationChanged(value)

func elevationEnded(valueChanged: float) -> void:
	uiEventHandler.OnElevationEnded(valueChanged)

func elevationChanged(value: float) -> void:
	uiEventHandler.OnElevationChanged(value)
	elevationThrust.UpdateHandle(value)

func inventoryPressed() -> void:
	uiEventHandler.OnInventoryPressed()

func regroupPressed() -> void:
	uiEventHandler.OnRegroupPressed()

func openHatchButtonPressed() -> void:
	uiEventHandler.OnOpenHatchPressed()

func radarButtonPressed() -> void:
	uiEventHandler.OnRadarButtonPressed()

func landPressed() -> void:
	uiEventHandler.OnLandPressed()

func pausePressed() -> void:
	uiEventHandler.OnPausePressed()

func markerEditorButtonPressed() -> void:
	uiEventHandler.OnMarkerEditorToggled(false)

func shipDockButtonPressed() -> void:
	uiEventHandler.OnFleetSeparationPressed()

func _on_forecast_button_toggled(toggledOn: bool) -> void:
	uiEventHandler.OnForecastPressed(toggledOn)

func _on_grid_button_toggled(toggledOn: bool) -> void:
	uiEventHandler.OnGridPressed(toggledOn)

func _on_zoom_level_button_toggled(toggledOn: bool) -> void:
	uiEventHandler.OnZoomTogglePressed(toggledOn)

func _on_altitude_toggled(toggledOn: bool) -> void:
	uiEventHandler.OnAltTogglePressed(toggledOn)

func _on_team_button_toggled(toggledOn: bool) -> void:
	uiEventHandler.OnTeamTogglePressed(toggledOn)

func _on_sonar_button_toggled(toggledOn: bool) -> void:
	uiEventHandler.OnSonarPressed(toggledOn)

func _on_zoom_dial_range_changed(newVal: float) -> void:
	uiEventHandler.OnZoomDialMoved(-newVal / 10)

func _on_y_dial_range_changed(newVal: float) -> void:
	uiEventHandler.OnYDialMoved(-newVal * 10)

func _on_x_dial_range_changed(newVal: float) -> void:
	uiEventHandler.OnXDialMoved(-newVal * 10)

func _on_topo_button_toggled(toggledOn: bool) -> void:
	uiEventHandler.OnTopoPressed(toggledOn)
