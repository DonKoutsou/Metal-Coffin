extends CanvasLayer

class_name ScreenUI

@export var _ScreenItems : Control
@export var MarkerEditorControls : MapMarkerControls
@export var Thrust : ThrustSlider
@export var Steer : SteeringWheelUI
@export var MissileUI : MissileTab
@export var LandButton : TextureButton
@export var HatchButton : TextureButton
@export var ShipDockButton : TextureButton
@export var RegroupButton : TextureButton
@export var SimulationButton : TextureButton
@export var SpeedSimulationButton : TextureButton
@export var MapMarkerButton : TextureButton
#@export var DroneUI : DroneTab
#@export var ButtonCover : TextureRect
@export var EventHandler : UIEventHandler
@export var Cam : ScreenCamera
@export_group("Screen")
@export var Cables : Control
@export var DoorSound : AudioStreamPlayer
@export var NormalScreen : Control
@export var FullScreenFrame : TextureRect
@export var ScreenPanel : TextureRect
@export var CardFightUI : ExternalCardFightUI
@export var TownUI : TownExternalUI

signal FullScreenToggleStarted(NewState : ScreenState)
signal FullScreenToggleFinished()

var ShipTradeInProgress : bool = false

func CloseScreen() -> void:
	ScreenPanel.visible = true
	DoorSound.play()
	Cam.EnableFullScreenShake()
	await Helper.GetInstance().wait(0.5)
	var CloseTw = create_tween()
	CloseTw.set_ease(Tween.EASE_OUT)
	CloseTw.set_trans(Tween.TRANS_BOUNCE)
	CloseTw.tween_property(ScreenPanel, "position", Vector2.ZERO, 2)
	await CloseTw.finished
	FullScreenToggleStarted.emit(ScreenState.HALF_SCREEN)

func OpenScreen(NewStat : ScreenState) -> void:
	FullScreenFrame.visible = NewStat == ScreenState.FULL_SCREEN
	NormalScreen.visible = NewStat == ScreenState.HALF_SCREEN

	var OpenTw = create_tween()
	OpenTw.set_ease(Tween.EASE_IN)
	OpenTw.set_trans(Tween.TRANS_QUART)
	OpenTw.tween_property(ScreenPanel, "position", Vector2(0, -ScreenPanel.size.y - 40), 1.6)
	await OpenTw.finished
	ScreenPanel.visible = false
	FullScreenToggleFinished.emit()
	Cam.EnableFullScreenShake()

func DoIntroFullScreen(NewStat : ScreenState) -> void:
	ScreenPanel.visible = true
	Cables.visible = false
	DoorSound.play()
	Cam.EnableFullScreenShake()
	await Helper.GetInstance().wait(0.5)
	var CloseTw = create_tween()
	CloseTw.set_ease(Tween.EASE_OUT)
	CloseTw.set_trans(Tween.TRANS_BOUNCE)
	CloseTw.tween_property(ScreenPanel, "position", Vector2(0,0), 2)
	CloseTw.finished.connect(IntroCloseFinisehd.bind(NewStat))

func IntroCloseFinisehd(NewStat : ScreenState) -> void:
	FullScreenToggleStarted.emit(NewStat)
	
	#await Helper.GetInstance().wait(0.2)
	Cables.visible = true
	FullScreenFrame.visible = NewStat == ScreenState.FULL_SCREEN
	NormalScreen.visible = NewStat == ScreenState.HALF_SCREEN
	
	var OpenTw = create_tween()
	OpenTw.set_ease(Tween.EASE_IN)
	OpenTw.set_trans(Tween.TRANS_QUART)
	OpenTw.tween_property(ScreenPanel, "position", Vector2(0, -ScreenPanel.size.y - 40), 1.6)
	await OpenTw.finished
	ScreenPanel.visible = false
	FullScreenToggleFinished.emit()
	Cam.EnableFullScreenShake()

func ToggleCardFightUI(t : bool) -> void:
	CardFightUI.visible = t

func ToggleTownUI(t : bool) -> void:
	TownUI.visible = t
	TownUI.TimesToPlay = 0

func ToggleFullScreen(NewStat : ScreenState) -> void:
	#FullScreenToggleStarted.emit()
	#$ScreenFrameLong2.visible = true
	ScreenPanel.visible = true
	DoorSound.play()
	Cam.EnableFullScreenShake()
	await Helper.GetInstance().wait(0.5)
	var CloseTw = create_tween()
	CloseTw.set_ease(Tween.EASE_OUT)
	CloseTw.set_trans(Tween.TRANS_BOUNCE)
	CloseTw.tween_property(ScreenPanel, "position", Vector2.ZERO, 2)
	await CloseTw.finished
	
	FullScreenToggleStarted.emit(NewStat)

	FullScreenFrame.visible = NewStat == ScreenState.FULL_SCREEN
	NormalScreen.visible = NewStat == ScreenState.HALF_SCREEN

	var OpenTw = create_tween()
	OpenTw.set_ease(Tween.EASE_IN)
	OpenTw.set_trans(Tween.TRANS_QUART)
	OpenTw.tween_property(ScreenPanel, "position", Vector2(0, -ScreenPanel.size.y - 40), 1.6)
	await OpenTw.finished
	ScreenPanel.visible = false
	FullScreenToggleFinished.emit()
	Cam.EnableFullScreenShake()


func _ready() -> void:
	NormalScreen.visible = false
	FullScreenFrame.visible = false
	ScreenPanel.visible = false
	EventHandler.connect("ScreenUIToggled", ToggleScreenUI)
	EventHandler.connect("ShipUpdated", ControlledShipSwitched)
	EventHandler.connect("ShipDamaged", OnControlledShipDamaged)
	EventHandler.connect("Storm", Storm)
	MissileUI.connect("MissileLaunched", Cam.EnableMissileShake)
	
	EventHandler.SpeedSet.connect(ShipSpeedSet)
	
	var SimulationMan = SimulationManager.GetInstance()
	if (SimulationMan != null):
		SimulationMan.SpeedChanged.connect(SpeedUpdated)

func Acceleration_Ended(value_changed: float) -> void:
	EventHandler.OnAccelerationEnded(value_changed)
	Cam.DissableShake()
	
func Acceleration_Changed(value: float) -> void:
	EventHandler.OnAccelerationChanged(value)
	Cam.EnableShake(value * 1.5)
	
func Storm(value : float) -> void:
	Cam.EnableStormShake(value)

func Drone_Button_Pressed() -> void:
	if (ShipTradeInProgress):
		PopUpManager.GetInstance().DoFadeNotif("Fleet separation in progress")
		return
	EventHandler.OnFleetSeparationPressed()
	#DroneUI._on_toggle_drone_tab_pressed()
	#MissileUI.TurnOff()
	##EventHandler.OnDroneButtonPressed()
	#ToggleMarkerEditor(false)

func Missile_Button_Pressed() -> void:
	MissileUI.Toggle()
	#DroneUI.TurnOff()
	MarkerEditorControls.TurnOff()
	
func Radar_Button_Pressed() -> void:
	EventHandler.OnRadarButtonPressed()

func ToggleScreenUI(t : bool) -> void:
	_ScreenItems.visible = t

func Steering_Direction_Changed(NewValue: float) -> void:
	EventHandler.OnSteeringDirectionChanged(NewValue)
	Cam.EnableShake(0.5)
	Cam.DissableShake()

func Steer_Offseted(Offset: float) -> void:
	EventHandler.OnSteerOffseted(Offset)
	Cam.EnableShake(0.5)
	Cam.DissableShake()

func ShipSpeedSet(NewSpeed : float) -> void:
	Thrust.ForceValue(NewSpeed)

func Ship_Switch_Pressed() -> void:
	if (ShipTradeInProgress):
		PopUpManager.GetInstance().DoFadeNotif("Fleet separation in progress")
		return
	EventHandler.OnShipSwitchPressed()

func ControlledShipSwitched(NewShip : MapShip) -> void:
	MissileUI.UpdateConnectedShip(NewShip)
	Thrust.ForceValue(NewShip.GetShipSpeed() / NewShip.GetShipMaxSpeed())
	Steer.ForceSteer(NewShip.rotation)

# Marker editor
func Marker_Editor_Pressed() -> void:
	#DroneUI.TurnOff()
	MissileUI.TurnOff()
	MarkerEditorControls.Toggle()
	EventHandler.OnMarkerEditorToggled(MarkerEditorControls.Showing)
	
func Exit_Marker_Editor_Pressed() -> void:
	MarkerEditorControls.TurnOff()
	EventHandler.OnMarkerEditorToggled(false)
	
func Clear_Lines_Pressed() -> void:
	EventHandler.OnMarkerEditorClearLinesPressed()

func Draw_Line_Pressed() -> void:
	EventHandler.OnMarkerEditorDrawLinePressed()


func Draw_Text_Pressed() -> void:
	EventHandler.OnMarkerEditorDrawTextPressed()

func MarkerEditorYRangeChanged(NewVal: float) -> void:
	EventHandler.OnMarkerEditorYRangeChanged(NewVal)

func MarkerEditorXRangeChanged(NewVal: float) -> void:
	EventHandler.OnMarkerEditorXRangeChanged(NewVal)
#
#

func Regroup_Pressed() -> void:
	if (ShipTradeInProgress):
		PopUpManager.GetInstance().DoFadeNotif("Fleet separation in progress")
		return
	EventHandler.OnRegroupPressed()


func Land_Pressed() -> void:
	if (ShipTradeInProgress):
		PopUpManager.GetInstance().DoFadeNotif("Fleet separation in progress")
		return
	EventHandler.OnLandPressed()

func _on_open_hatch_button_pressed() -> void:
	if (ShipTradeInProgress):
		PopUpManager.GetInstance().DoFadeNotif("Fleet separation in progress")
		return
	EventHandler.OnOpenHatchPressed()

#Simulation--------------------------------
func Sim_Pause_Pressed() -> void:
	if (ShipTradeInProgress):
		PopUpManager.GetInstance().DoFadeNotif("Fleet separation in progress")
		return
	var simmulationPaused = !SimulationManager.GetInstance().Paused
	SimulationManager.GetInstance().TogglePause(simmulationPaused)

func Simmulation_Step_Changed(NewStep: float) -> void:
	#EventHandler.OnSimmulationStepChanged(NewStep)
	SimulationManager.GetInstance().SetSimulationSpeed(NewStep)

func Sim_Speed_Pressed() -> void:
	SimulationManager.GetInstance().SpeedToggle(true)

func Sim_Speed_Released() -> void:
	SimulationManager.GetInstance().SpeedToggle(false)

func _on_forecast_button_pressed() -> void:
	EventHandler.OnForecastPressed()

func _on_grid_button_pressed() -> void:
	EventHandler.OnGridPressed()

func _on_speed_simulation_toggled(toggled_on: bool) -> void:
	SimulationManager.GetInstance().SpeedToggle(toggled_on)

func SpeedUpdated(t : bool) -> void:
	SpeedSimulationButton.set_pressed_no_signal(t)
	SpeedSimulationButton.button_down.emit()

func Inventory_Pressed() -> void:
	if (ShipTradeInProgress):
		PopUpManager.GetInstance().DoFadeNotif("Fleet separation in progress")
		return
	EventHandler.OnInventoryPressed()

var ScreenItemsStateBeforePause : bool
func Pause_Pressed() -> void:
	if (!get_tree().paused):
		ScreenItemsStateBeforePause = _ScreenItems.visible
		_ScreenItems.visible = false
	else:
		_ScreenItems.visible = ScreenItemsStateBeforePause
	EventHandler.OnPausePressed()
	
func TownVisited(t : bool) -> void:
	if (t):
		ScreenItemsStateBeforePause = _ScreenItems.visible
		_ScreenItems.visible = false
	else:
		_ScreenItems.visible = ScreenItemsStateBeforePause

func OnControlledShipDamaged(DamageAmm : float) -> void:
	Cam.EnableDamageShake(DamageAmm / 10)


enum ScreenState{
	FULL_SCREEN,
	HALF_SCREEN,
	NO_SCREEN
}


func _on_steer_button_pressed() -> void:
	Steer.Toggle()
