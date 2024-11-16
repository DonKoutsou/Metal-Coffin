extends Control
class_name DroneTab


@export var DroneDockEventH : DroneDockEventHandler

var Armed = false

var DockedDrones : Array[Drone] = []

var CurrentlySelectedDrone : Drone

var SteerShowing : bool = false

func _ready() -> void:
	DroneDockEventH.connect("DroneDocked", DroneDocked)
	DroneDockEventH.connect("DroneUndocked", DroneUnDocked)
	DroneDockEventH.connect("DroneDischarged", DroneDisharged)
	$Control/Control/Dissarm.ToggleDissable(true)
	$Control/Control/Launch.ToggleDissable(true)
	#visible = false


func DroneDisharged(Dr : Drone):
	if (DockedDrones.has(Dr)):
		DockedDrones.erase(Dr)
	if (Dr == CurrentlySelectedDrone):
		CurrentlySelectedDrone = null
		UpdateCrewSelect()

func DroneDocked(Dr : Drone) -> void:
	DockedDrones.append(Dr)
	#visible = DockedDrones.size() > 0
	if (CurrentlySelectedDrone == null):
		UpdateCrewSelect()

func DroneUnDocked(Dr : Drone) -> void:

	DockedDrones.erase(Dr)
	#visible = DockedDrones.size() > 0
	
	if (Dr == CurrentlySelectedDrone):
		CurrentlySelectedDrone = null
		UpdateCrewSelect()

func _on_deploy_drone_button_pressed() -> void:
	DroneDockEventH.OnDroneLaunched(CurrentlySelectedDrone)
	_on_dissarm_drone_button_2_pressed()
	
func _on_arm_drone_button_pressed(t : bool) -> void:
	
	if (DockedDrones.size() == 0):
		_on_dissarm_drone_button_2_pressed()
		return
	if (!t):
		_on_dissarm_drone_button_2_pressed()
		return
	Armed = true
	#$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer3/HBoxContainer2/ArmDroneButton.disabled = true
	$Control/Control/Dissarm.ToggleDissable(false)
	$Control/Control/Launch.ToggleDissable(false)
	if (!SteerShowing):
		$AnimationPlayer.play("ShowSteer")
		SteerShowing = true
	DroneDockEventH.DroneArmed()
	
func _on_dissarm_drone_button_2_pressed() -> void:
	Armed = false
	$Control/Control/Arm.button_pressed = false
	$Control/Control/Dissarm.ToggleDissable(true)
	$Control/Control/Launch.ToggleDissable(true)
	if (SteerShowing):
		$AnimationPlayer.play("HideSteer")
		SteerShowing = false
	DroneDockEventH.DroneDissarmed()

func _on_looter_drone_button_pressed() -> void:
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/LooterDroneButton.ToggleDissable(true)
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/ReconDronButton.ToggleDissable(false)
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer3/Label.text = "Armed Drone : Looter"

func _on_recon_dron_button_pressed() -> void:
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/LooterDroneButton.ToggleDissable(false)
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/ReconDronButton.ToggleDissable(true)
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer3/Label.text = "Armed Drone : Recon"

func _on_toggle_drone_tab_pressed() -> void:
	$Control/TouchStopper.mouse_filter = MOUSE_FILTER_IGNORE
	$AnimationPlayer.play("Show")
	UpdateCrewSelect()
		
var SteeringDir : float = 0.0
#signal SteeringDitChanged(NewValue : float)
#signal MouseEntered()
#signal MouseExited()

func UpdateSteer(RelativeRot : Vector2, EvPos : Vector2):
	var rel = clamp(RelativeRot / 100, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
	var prevsteer = SteeringDir
	
	if (EvPos.x < $Control/Node2D.position.x):
		$Control/Node2D/Sprite2D.rotation += rel.x + -rel.y
		SteeringDir += (rel.x + -rel.y) * 10
	else :
		$Control/Node2D/Sprite2D.rotation += rel.x + rel.y
		SteeringDir += (rel.x + rel.y) * 10
	if (SteeringDir != prevsteer):
		DroneDockEventH.DroneDirectionChanged(SteeringDir / 10)
	if (!$Control/Node2D/AudioStreamPlayer.playing):
		$Control/Node2D/AudioStreamPlayer.playing = true
	Input.vibrate_handheld(5)
var RangeDir : float = 0.0
func UpdateRange(RelativeRot : Vector2, EvPos : Vector2):
	var rel = clamp(RelativeRot / 100, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
	var prevrange = RangeDir
	
	if (EvPos.x < $Control/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer/TextureButton.position.x + 64):
		$Control/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer/TextureButton.rotation += rel.x -rel.y
		RangeDir = clamp(RangeDir + ((rel.x -rel.y) * 10), 0 , 100)
	else :
		$Control/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer/TextureButton.rotation += rel.x + rel.y
		RangeDir = clamp(RangeDir + ((rel.x + rel.y) * 10), 0, 100)
	if (RangeDir != prevrange):
		DroneDockEventH.OnDronRangeChanged(roundi(RangeDir))
	if (!$Control/Node2D/AudioStreamPlayer.playing):
		$Control/Node2D/AudioStreamPlayer.playing = true
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer3/HBoxContainer2/PanelContainer/VBoxContainer/Label2.text = var_to_str(roundi(RangeDir / 2))
func UpdateDroneRange(Rang : float):
	if (Armed):
		RangeDir = clamp(RangeDir + Rang, 0, 100)
		DroneDockEventH.OnDronRangeChanged(roundi(RangeDir))
		$Control/Control/Label.text = "Fuel Cost : " + var_to_str(roundi(RangeDir / 2))
	else:
		ProgressCrewSelect()
	
func _on_area_2d_input_event(event: InputEvent) -> void:
	if (event is InputEventScreenDrag):
		UpdateSteer(event.relative, event.position)
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		UpdateSteer(event.relative, event.position)
		
func UpdateCrewSelect(Select : int = 0):
	if (DockedDrones.size() > Select):
		CurrentlySelectedDrone = DockedDrones[Select]
		$Control/TextureRect/Label2.text = CurrentlySelectedDrone.Cpt.CaptainName
		$Control/TextureRect/Light.Toggle(true, true)
	else:
		$Control/TextureRect/Label2.text = "No Drones"
		$Control/TextureRect/Light.Toggle(true)
func ProgressCrewSelect():
	if (DockedDrones.size() == 0):
		$Control/TextureRect/Label2.text = "No Drones"
		$Control/TextureRect/Light.Toggle(true)
		return
	if (CurrentlySelectedDrone == null):
		CurrentlySelectedDrone = DockedDrones[0]
	else:
		var i = DockedDrones.find(CurrentlySelectedDrone) + 1
		if (i >= DockedDrones.size()):
			i = 0
		CurrentlySelectedDrone = DockedDrones[i]
	$Control/TextureRect/Light.Toggle(true, true)
	$Control/TextureRect/Label2.text = CurrentlySelectedDrone.Cpt.CaptainName
func On_Drone_Range_Input(event: InputEvent) -> void:
	if (event is InputEventScreenDrag):
		if (Armed):
			UpdateRange(event.relative, event.position)
		else:
			ProgressCrewSelect()
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		if (Armed):
			UpdateRange(event.relative, event.position)
		else:
			ProgressCrewSelect()
func _on_turn_off_button_pressed() -> void:
	$Control/TouchStopper.mouse_filter = MOUSE_FILTER_STOP
	if (Armed):
		_on_dissarm_drone_button_2_pressed()
		await $AnimationPlayer.animation_finished
	$AnimationPlayer.play("Hide")

func _on_drone_range_slider_value_changed(value: float) -> void:
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer4/Label2.text = var_to_str(value / 2)
	DroneDockEventH.OnDronRangeChanged(value)
