extends CanvasLayer

class_name ScreenUI

@export var _ScreenItems : Control
@export var MarkerEditorControls : MapMarkerControls
@export var Thrust : ThrustSlider
@export var Steer : SteeringWheelUI
@export var MissileUI : MissileTab
@export var LandButton : TextureButton
@export var ShipDockButton : TextureButton
@export var RegroupButton : TextureButton
@export var SimulationButton : TextureButton
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

signal FullScreenToggleStarted(NewState : ScreenState)
signal FullScreenToggleFinished()
#signal FleetSeparationInitiated

var CloseTw : Tween
var OpenTw : Tween

func CloseScreen() -> void:
	ScreenPanel.visible = true
	DoorSound.play()
	Cam.EnableFullScreenShake()
	await wait(0.5)
	CloseTw = create_tween()
	CloseTw.set_ease(Tween.EASE_OUT)
	CloseTw.set_trans(Tween.TRANS_BOUNCE)
	CloseTw.tween_property(ScreenPanel, "position", Vector2.ZERO, 2)
	await CloseTw.finished
	
	FullScreenToggleStarted.emit(ScreenState.HALF_SCREEN)

func DoIntroFullScreen(NewStat : ScreenState) -> void:
	ScreenPanel.visible = true
	Cables.visible = false
	DoorSound.play()
	Cam.EnableFullScreenShake()
	await wait(0.5)
	CloseTw = create_tween()
	CloseTw.set_ease(Tween.EASE_OUT)
	CloseTw.set_trans(Tween.TRANS_BOUNCE)
	CloseTw.tween_property(ScreenPanel, "position", Vector2.ZERO, 2)
	await CloseTw.finished
	
	FullScreenToggleStarted.emit(NewStat)
	
	await wait(0.2)
	Cables.visible = true
	FullScreenFrame.visible = NewStat == ScreenState.FULL_SCREEN
	NormalScreen.visible = NewStat == ScreenState.HALF_SCREEN
	
	
	
	OpenTw = create_tween()
	OpenTw.set_ease(Tween.EASE_IN)
	OpenTw.set_trans(Tween.TRANS_QUART)
	OpenTw.tween_property(ScreenPanel, "position", Vector2(0, -ScreenPanel.size.y - 40), 1.6)
	await OpenTw.finished
	ScreenPanel.visible = false
	FullScreenToggleFinished.emit()
	Cam.EnableFullScreenShake()

func ToggleCardFightUI(t : bool) -> void:
	CardFightUI.visible = t

func ToggleFullScreen(NewStat : ScreenState) -> void:
	#FullScreenToggleStarted.emit()
	#$ScreenFrameLong2.visible = true
	ScreenPanel.visible = true
	DoorSound.play()
	Cam.EnableFullScreenShake()
	await wait(0.5)
	CloseTw = create_tween()
	CloseTw.set_ease(Tween.EASE_OUT)
	CloseTw.set_trans(Tween.TRANS_BOUNCE)
	CloseTw.tween_property(ScreenPanel, "position", Vector2.ZERO, 2)
	await CloseTw.finished
	
	FullScreenToggleStarted.emit(NewStat)
	
	await wait(0.2)

	FullScreenFrame.visible = NewStat == ScreenState.FULL_SCREEN
	NormalScreen.visible = NewStat == ScreenState.HALF_SCREEN
	
	
	
	OpenTw = create_tween()
	OpenTw.set_ease(Tween.EASE_IN)
	OpenTw.set_trans(Tween.TRANS_QUART)
	OpenTw.tween_property(ScreenPanel, "position", Vector2(0, -ScreenPanel.size.y - 40), 1.6)
	await OpenTw.finished
	ScreenPanel.visible = false
	FullScreenToggleFinished.emit()
	Cam.EnableFullScreenShake()
func wait(secs : float) -> Signal:
	return get_tree().create_timer(secs).timeout
	

func _ready() -> void:
	NormalScreen.visible = false
	FullScreenFrame.visible = false
	ScreenPanel.visible = false
	EventHandler.connect("ScreenUIToggled", ToggleScreenUI)
	#EventHandler.connect("AccelerationForced", Acceleration_Forced)
	#EventHandler.connect("SteerDirForced", Steer_Forced)
	EventHandler.connect("ShipUpdated", ControlledShipSwitched)
	#EventHandler.connect("CoverToggled", ToggleControllCover)
	EventHandler.connect("ShipDamaged", OnControlledShipDamaged)
	MissileUI.connect("MissileLaunched", Cam.EnableMissileShake)

	#OnControlledShipDamaged()
#
#func _input(event: InputEvent) -> void:
	#if (event.is_action_pressed("Click")):
		#ToggleFullScreen(true)

func Acceleration_Ended(value_changed: float) -> void:
	EventHandler.OnAccelerationEnded(value_changed)
	#var tw = create_tween()
	#tw.set_trans(Tween.TRANS_BOUNCE)
	#tw.tween_property($ScreenCam, "shakestr", 0, $ScreenCam.shakestr * 3)
	Cam.DissableShake()
	
func Acceleration_Changed(value: float) -> void:
	EventHandler.OnAccelerationChanged(value)
	Cam.EnableShake(value * 1.5)

func Drone_Button_Pressed() -> void:
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

func Ship_Switch_Pressed() -> void:
	EventHandler.OnShipSwitchPressed()

func ControlledShipSwitched(NewShip : MapShip) -> void:
	MissileUI.UpdateConnectedShip(NewShip)
	Thrust.ForceValue(NewShip.GetShipSpeed() / NewShip.GetShipMaxSpeed())
	Steer.ForceSteer(NewShip.rotation)
	#UIEventH.OnAccelerationForced(ControlledShip.GetShipSpeed() / ControlledShip.GetShipMaxSpeed())
	#UIEventH.OnSteerDirForced(ControlledShip.rotation)
	#DroneUI.UpdateConnectedShip(NewShip)

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
	EventHandler.OnRegroupPressed()


func Land_Pressed() -> void:
	EventHandler.OnLandPressed()

#Simulation--------------------------------
func Sim_Pause_Pressed() -> void:
	var simmulationPaused = !SimulationManager.GetInstance().Paused
	SimulationManager.GetInstance().TogglePause(simmulationPaused)

func Simmulation_Step_Changed(NewStep: float) -> void:
	#EventHandler.OnSimmulationStepChanged(NewStep)
	SimulationManager.GetInstance().SetSimulationSpeed(NewStep)

func Sim_Speed_Pressed() -> void:
	SimulationManager.GetInstance().SpeedToggle(true)

func Sim_Speed_Released() -> void:
	SimulationManager.GetInstance().SpeedToggle(false)

func Inventory_Pressed() -> void:
	EventHandler.OnInventoryPressed()

var ScreenItemsStateBeforePause : bool
func Pause_Pressed() -> void:
	if (!get_tree().paused):
		ScreenItemsStateBeforePause = _ScreenItems.visible
		_ScreenItems.visible = false
	else:
		_ScreenItems.visible = ScreenItemsStateBeforePause
	EventHandler.OnPausePressed()
	

func OnControlledShipDamaged(DamageAmm : float) -> void:
	Cam.EnableDamageShake(DamageAmm / 10)


enum ScreenState{
	FULL_SCREEN,
	HALF_SCREEN,
	NO_SCREEN
}
