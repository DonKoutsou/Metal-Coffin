extends Control
class_name DroneTab


@export var DroneDockEventH : DroneDockEventHandler

var Armed = false

var ConnectedShip : MapShip

var DockedDrones : Dictionary

var CurrentlySelectedDrone : Drone

var SteerShowing : bool = false

func _ready() -> void:
	DroneDockEventH.connect("DroneDocked", DroneDocked)
	DroneDockEventH.connect("DroneUndocked", DroneUnDocked)
	DroneDockEventH.connect("DroneDischarged", DroneDisharged)
	$Control/Control/Dissarm.ToggleDissable(true)
	$Control/Control/Launch.ToggleDissable(true)
	#visible = false

func UpdateConnectedShip(Ship : MapShip) -> void:
	ConnectedShip = Ship
	if (!DockedDrones.keys().has(Ship)):
		DockedDrones[Ship] = []

func DroneDisharged(Dr : Drone):
	if (DockedDrones.has(Dr)):
		DockedDrones.erase(Dr)
	if (Dr == CurrentlySelectedDrone):
		CurrentlySelectedDrone = null
		UpdateCrewSelect()

func DroneDocked(Dr : Drone, Target : MapShip) -> void:
	DockedDrones[Target].append(Dr)
	#DockedDrones.append(Dr)
	#visible = DockedDrones.size() > 0
	if (CurrentlySelectedDrone == null):
		UpdateCrewSelect()

func DroneUnDocked(Dr : Drone, Target : MapShip) -> void:
	DockedDrones[Target].erase(Dr)
	#visible = DockedDrones.size() > 0
	
	if (Dr == CurrentlySelectedDrone):
		CurrentlySelectedDrone = null
		UpdateCrewSelect()

func _on_deploy_drone_button_pressed() -> void:
	DroneDockEventH.OnDroneLaunched(CurrentlySelectedDrone, ConnectedShip)
	_on_dissarm_drone_button_2_pressed()
	
func _on_arm_drone_button_pressed(t : bool) -> void:
	
	if (DockedDrones[ConnectedShip].size() == 0):
		_on_dissarm_drone_button_2_pressed()
		return
	if (!t):
		_on_dissarm_drone_button_2_pressed()
		return
	Armed = true
	var eff = CurrentlySelectedDrone.Cpt.GetStatValue("FUEL_EFFICIENCY")
	var fuel = CurrentlySelectedDrone.Cpt.GetStat("FUEL_TANK").CurrentVelue
	RangeDir = clamp(RangeDir, fuel * 10 * eff, CurrentlySelectedDrone.Cpt.GetStatValue("FUEL_TANK") * 10 * eff)
	
	DroneDockEventH.OnDronRangeChanged(roundi(RangeDir), ConnectedShip)
	$Control/Control/Label.text = "Fuel Cost : " + var_to_str(roundi(RangeDir / 10 / eff))
	#$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer3/HBoxContainer2/ArmDroneButton.disabled = true
	$Control/Control/Dissarm.ToggleDissable(false)
	$Control/Control/Launch.ToggleDissable(false)
	if (!SteerShowing):
		$AnimationPlayer.play("ShowSteer")
		SteerShowing = true
	DroneDockEventH.DroneArmed(ConnectedShip)
	
func _on_dissarm_drone_button_2_pressed() -> void:
	Armed = false
	$Control/Control/Arm.button_pressed = false
	$Control/Control/Dissarm.ToggleDissable(true)
	$Control/Control/Launch.ToggleDissable(true)
	if (SteerShowing):
		$AnimationPlayer.play("HideSteer")
		SteerShowing = false
	DroneDockEventH.DroneDissarmed(ConnectedShip)

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
	DroneDockEventH.DroneDirectionChanged(RelativeRot / 10, ConnectedShip)

	Input.vibrate_handheld(50)
var RangeDir : float = 0.0

func UpdateDroneRange(Rang : float):
	if (Armed):
		#TODO figure out this filthy math
		var eff = CurrentlySelectedDrone.Cpt.GetStatValue("FUEL_EFFICIENCY")
		var fuel = CurrentlySelectedDrone.Cpt.GetStat("FUEL_TANK").CurrentVelue
		RangeDir = clamp((RangeDir + (Rang * 20)), fuel * 10 * eff, CurrentlySelectedDrone.Cpt.GetStatValue("FUEL_TANK") * 10 * eff)
		
		DroneDockEventH.OnDronRangeChanged(roundi(RangeDir), ConnectedShip)
		$Control/Control/Label.text = "Fuel Cost : " + var_to_str(roundi(RangeDir / 10 / eff))
	else:
		ProgressCrewSelect()
		
func UpdateCrewSelect(Select : int = 0):
	if (DockedDrones[ConnectedShip].size() > Select):
		CurrentlySelectedDrone = DockedDrones[ConnectedShip][Select]
		$Control/TextureRect/Label2.text = CurrentlySelectedDrone.Cpt.CaptainName
		$Control/TextureRect/Light.Toggle(true, true)
	else:
		$Control/TextureRect/Label2.text = "No Drones"
		$Control/TextureRect/Light.Toggle(true)
func ProgressCrewSelect():
	if (DockedDrones[ConnectedShip].size() == 0):
		$Control/TextureRect/Label2.text = "No Drones"
		$Control/TextureRect/Light.Toggle(true)
		return
	if (CurrentlySelectedDrone == null):
		CurrentlySelectedDrone = DockedDrones[ConnectedShip][0]
	else:
		var i = DockedDrones[ConnectedShip].find(CurrentlySelectedDrone) + 1
		if (i >= DockedDrones.size()):
			i = 0
		CurrentlySelectedDrone = DockedDrones[ConnectedShip][i]
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
	DroneDockEventH.OnDronRangeChanged(value, ConnectedShip)
