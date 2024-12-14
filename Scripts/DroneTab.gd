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

func UpdateSteer(RelativeRot : float):
	DroneDockEventH.DroneDirectionChanged(RelativeRot / 10)

	Input.vibrate_handheld(50)
var RangeDir : float = 0.0

func UpdateDroneRange(Rang : float):
	if (Armed):
		#TODO figure out this filthy math
		RangeDir = clamp((RangeDir + Rang), 0, 100)
		DroneDockEventH.OnDronRangeChanged(roundi(RangeDir * 80))
		$Control/Control/Label.text = "Fuel Cost : " + var_to_str(roundi(RangeDir * 80 / 10 / 2))
	else:
		ProgressCrewSelect()
		
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

func _on_turn_off_button_pressed() -> void:
	$Control/TouchStopper.mouse_filter = MOUSE_FILTER_STOP
	if (Armed):
		_on_dissarm_drone_button_2_pressed()
		await $AnimationPlayer.animation_finished
	$AnimationPlayer.play("Hide")

func _on_drone_range_slider_value_changed(value: float) -> void:
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer4/Label2.text = var_to_str(value / 2)
	DroneDockEventH.OnDronRangeChanged(value)
