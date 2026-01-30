extends CanvasLayer

class_name ScreenUI

@export var _ScreenItems : Control
@export var MarkerEditorControls : MapMarkerControls
@export var Thrust : ThrustSlider
@export var Steer : SteeringWheelUI
@export var MissileUI : MissileTab
@export var EventHandler : UIEventHandler
@export var Cam : ScreenCamera

@export_group("Buttons")
@export var LandButton : TextureButton
@export var HatchButton : TextureButton
@export var ShipDockButton : TextureButton
@export var RegroupButton : TextureButton
@export var SimulationButton : TextureButton
@export var SpeedSimulationButton : TextureButton
@export var MapMarkerButton : TextureButton

@export_group("Screen")
@export var Cables : Control
@export var DoorSound : AudioStreamPlayer
@export var NormalScreen : Control
@export var MeduimScreen : Control
@export var FullScreenFrame : TextureRect
@export var ScreenPanel : TextureRect
@export var CardFightUI : ExternalCardFightUI
@export var TownUI : TownExternalUI
@export var Sonar : AeroSonar


signal FullScreenToggleStarted(NewState : ScreenState)
signal FullScreenToggleFinished()


func _ready() -> void:
	NormalScreen.visible = false
	FullScreenFrame.visible = false
	ScreenPanel.visible = false
	EventHandler.ScreenUIToggled.connect(ToggleScreenUI)
	EventHandler.ShipUpdated.connect(ControlledShipSwitched)
	EventHandler.ShipDamaged.connect(OnControlledShipDamaged)
	EventHandler.Storm.connect(Storm)
	MissileUI.MissileLaunched.connect(Cam.EnableMissileShake)
	EventHandler.SpeedSet.connect(ShipSpeedSet)
	EventHandler.SpeedForced.connect(ShipSpeedForced)
	
	var SimulationMan = SimulationManager.GetInstance()
	if (SimulationMan != null):
		SimulationMan.SpeedChanged.connect(SpeedUpdated)

func Storm(value : float) -> void:
	Cam.EnableStormShake(value)
	
	
func ToggleCardFightUI(t : bool) -> void:
	CardFightUI.visible = t


func ToggleTownUI(t : bool) -> void:
	TownUI.visible = t
	TownUI.TimesToPlay = 0


func ToggleScreenUI(t : bool) -> void:
	_ScreenItems.visible = t
	

func Acceleration_Ended(value_changed: float) -> void:
	EventHandler.OnAccelerationEnded(value_changed)
	Cam.DissableShake()
	
	
func Acceleration_Changed(value: float) -> void:
	EventHandler.OnAccelerationChanged(value)
	Cam.EnableShake(value * 1.5)
	

func Steering_Direction_Changed(NewValue: float) -> void:
	EventHandler.OnSteeringDirectionChanged(NewValue)
	Cam.EnableShake(0.5)
	Cam.DissableShake()


func Steer_Offseted(Offset: float) -> void:
	EventHandler.OnSteerOffseted(Offset)
	Cam.EnableShake(0.5)
	Cam.DissableShake()


func ShipSpeedSet(NewSpeed : float) -> void:
	Thrust.UpdateHandle(NewSpeed)

func ShipSpeedForced(NewSpeed : float) -> void:
	Thrust.ForceValue(NewSpeed)

func ControlledShipSwitched(NewShip : MapShip) -> void:
	MissileUI.UpdateConnectedShip(NewShip)
	Thrust.ForceValue(NewShip.GetShipSpeed() / NewShip.GetShipMaxSpeed())
	Steer.ForceSteer(NewShip.rotation)


########## BUTTON PRESS EVENTS ###########
func Marker_Editor_Button_Pressed() -> void:
	MissileUI.TurnOff()
	MarkerEditorControls.Toggle()
	EventHandler.OnMarkerEditorToggled(MarkerEditorControls.Showing)


func Ship_Dock_Button_Pressed() -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	EventHandler.OnFleetSeparationPressed()


func Missile_Button_Pressed() -> void:
	MissileUI.Toggle()
	MarkerEditorControls.TurnOff()
	
	
func Radar_Button_Pressed() -> void:
	EventHandler.OnRadarButtonPressed()
	
	
func Regroup_Pressed() -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	EventHandler.OnRegroupPressed()


func Land_Pressed() -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	EventHandler.OnLandPressed()


func Open_Hatch_Button_Pressed() -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	EventHandler.OnOpenHatchPressed()


func Sim_Pause_Pressed() -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
		return
	var simmulationPaused = !SimulationManager.GetInstance().Paused
	SimulationManager.GetInstance().TogglePause(simmulationPaused)


########## BUTTON TOGGLE EVENTS ###########

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
	Sonar.Toggle(toggled_on)

func _on_speed_simulation_toggled(toggled_on: bool) -> void:
	SimulationManager.GetInstance().SpeedToggle(toggled_on)

func SpeedUpdated(t : bool) -> void:
	SpeedSimulationButton.set_pressed_no_signal(t)
	SpeedSimulationButton.button_down.emit()

func Inventory_Pressed() -> void:
	if (World.WORLDST != World.WORLDSTATE.NORMAL):
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


func _on_steer_button_toggled(toggled_on: bool) -> void:
	Steer.Toggle(toggled_on)

################## SCREEN TRANSITION ########################

enum ScreenState{
	FULL_SCREEN,
	HALF_SCREEN,
	NORMAL_SCREEN,
	NO_SCREEN
}

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

func ToggleFullScreen(NewStat : ScreenState) -> void:
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
	NormalScreen.visible = NewStat == ScreenState.NORMAL_SCREEN
	MeduimScreen.visible = NewStat == ScreenState.HALF_SCREEN

	var OpenTw = create_tween()
	OpenTw.set_ease(Tween.EASE_IN)
	OpenTw.set_trans(Tween.TRANS_QUART)
	OpenTw.tween_property(ScreenPanel, "position", Vector2(0, -ScreenPanel.size.y - 40), 1.6)
	await OpenTw.finished
	ScreenPanel.visible = false
	FullScreenToggleFinished.emit()
	Cam.EnableFullScreenShake()
