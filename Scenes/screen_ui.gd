extends Control

class_name ScreenUI

@export var _ScreenItems : Control
@export var MarkerEditorControls : Control
@export var Thrust : ThrustSlider
@export var Steer : SteeringWheelUI
@export var MissileUI : MissileTab
@export var DroneUI : DroneTab
@export var ButtonCover : TextureRect
@export var EventHandler : UIEventHandler
@export var Cam : ScreenCamera
@export_group("Screen")
@export var NormalScreen : Control
@export var FullScreenFrame : TextureRect

signal FullScreenToggleStarted
signal FullScreenToggleFinished(t : bool)

func ToggleFullScreen(toggle : bool) -> void:
	FullScreenToggleStarted.emit()
	
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1,1,1,0), 1)
	await tw.finished

	FullScreenFrame.visible = toggle
	NormalScreen.visible = !toggle

	var tw2 = create_tween()
	tw2.tween_property(self, "modulate", Color(1,1,1,1), 1)
	await tw2.finished
	
	FullScreenToggleFinished.emit(toggle)

func _ready() -> void:
	EventHandler.connect("ScreenUIToggled", ToggleScreenUI)
	EventHandler.connect("AccelerationForced", Acceleration_Forced)
	EventHandler.connect("SteerDirForced", Steer_Forced)
	EventHandler.connect("ShipUpdated", ControlledShipSwitched)
	EventHandler.connect("CoverToggled", ToggleControllCover)
	EventHandler.connect("ShipDamaged", OnControlledShipDamaged)
	MissileUI.connect("MissileLaunched", Cam.EnableMissileShake)
	#OnControlledShipDamaged()
	
func Acceleration_Ended(value_changed: float) -> void:
	EventHandler.OnAccelerationEnded(value_changed)
	#var tw = create_tween()
	#tw.set_trans(Tween.TRANS_BOUNCE)
	#tw.tween_property($ScreenCam, "shakestr", 0, $ScreenCam.shakestr * 3)
	Cam.DissableShake()
	
func Acceleration_Changed(value: float) -> void:
	EventHandler.OnAccelerationChanged(value)
	Cam.EnableShake(value * 1.5)

func Acceleration_Forced(NewVal : float) -> void:
	Thrust.ForceValue(NewVal)

func Drone_Button_Pressed() -> void:
	DroneUI._on_toggle_drone_tab_pressed()
	MissileUI.TurnOff()
	#EventHandler.OnDroneButtonPressed()
	ToggleMarkerEditor(false)

func Missile_Button_Pressed() -> void:
	MissileUI._on_toggle_drone_tab_pressed()
	DroneUI.TurnOff()
	ToggleMarkerEditor(false)
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
	
func Steer_Forced(NewVal : float) -> void:
	Steer.ForceSteer(NewVal)

func Ship_Switch_Pressed() -> void:
	EventHandler.OnShipSwitchPressed()

func ControlledShipSwitched(NewShip : MapShip) -> void:
	MissileUI.UpdateConnectedShip(NewShip)
	DroneUI.UpdateConnectedShip(NewShip)

# Marker editor
func Marker_Editor_Pressed() -> void:
	var t = !MarkerEditorControls.visible
	DroneUI.TurnOff()
	MissileUI.TurnOff()
	ToggleMarkerEditor(t)
	
func Exit_Marker_Editor_Pressed() -> void:
	ToggleMarkerEditor(false)

func ToggleMarkerEditor(t : bool) -> void:
	#_ScreenItems.visible = !t
	MarkerEditorControls.visible = t
	EventHandler.OnMarkerEditorToggled(t)
	
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

#Simulation
func Sim_Pause_Pressed() -> void:
	var simmulationPaused = !SimulationManager.GetInstance().Paused
	SimulationManager.GetInstance().TogglePause(simmulationPaused)
	if (simmulationPaused):
		PopUpManager.GetInstance().DoFadeNotif("Simulation paused")
	else:
		PopUpManager.GetInstance().DoFadeNotif("Simulation unpaused")
func Simmulation_Step_Changed(NewStep: int) -> void:
	#EventHandler.OnSimmulationStepChanged(NewStep)
	SimulationManager.GetInstance().SetSimulationSpeed(NewStep)
	

func Inventory_Pressed() -> void:
	EventHandler.OnInventoryPressed()


func Pause_Pressed() -> void:
	EventHandler.OnPausePressed()

func ToggleControllCover(t : bool) -> void:
	ButtonCover.visible = t

func OnControlledShipDamaged() -> void:
	#var tw = create_tween()
	#tw.set_trans(Tween.TRANS_BOUNCE)
	#tw.tween_property($ScreenCam, "shakestr", 0, 8)
	Cam.EnableDamageShake()
	#$ScreenCam.Shake = false
	
	

	
