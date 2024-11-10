extends Control
class_name DroneTab


@export var DroneDockEventH : DroneDockEventHandler

var Armed = false

var DockedDrones : Array[Drone] = []

func _ready() -> void:
	DroneDockEventH.connect("DroneDocked", DroneDocked)
	DroneDockEventH.connect("DroneUndocked", DroneUnDocked)
	$Control/Control/Dissarm.ToggleDissable(true)
	$Control/Control/Launch.ToggleDissable(true)

func DroneDocked(Dr : Drone) -> void:
	DockedDrones.append(Dr)

func DroneUnDocked(Dr : Drone) -> void:
	DockedDrones.erase(Dr)

func _on_deploy_drone_button_pressed() -> void:
	DroneDockEventH.OnDroneLaunched()
	_on_dissarm_drone_button_2_pressed()
	
func _on_arm_drone_button_pressed(t : bool) -> void:
	
	if (DockedDrones.size() == 0):
		return
	if (!t):
		_on_dissarm_drone_button_2_pressed()
		return
	Armed = true
	#$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer3/HBoxContainer2/ArmDroneButton.disabled = true
	$Control/Control/Dissarm.ToggleDissable(false)
	$Control/Control/Launch.ToggleDissable(false)
	$AnimationPlayer.play("ShowSteer")
	DroneDockEventH.DroneArmed()
	
func _on_dissarm_drone_button_2_pressed() -> void:
	Armed = false
	$Control/Control/Arm.button_pressed = false
	$Control/Control/Dissarm.ToggleDissable(true)
	$Control/Control/Launch.ToggleDissable(true)
	$AnimationPlayer.play("HideSteer")
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
		DroneDockEventH.DroneDirectionChanged(SteeringDir)
	if (!$Control/Node2D/AudioStreamPlayer.playing):
		$Control/Node2D/AudioStreamPlayer.playing = true

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
	print(RangeDir)
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer3/HBoxContainer2/PanelContainer/VBoxContainer/Label2.text = var_to_str(roundi(RangeDir / 2))
func UpdateDroneRange(Rang : float):
	RangeDir = clamp(RangeDir + Rang, 0, 100)
	DroneDockEventH.OnDronRangeChanged(roundi(RangeDir))
	$Control/Control/Label.text = "Fuel Cost : " + var_to_str(roundi(RangeDir / 2))
func _on_area_2d_input_event(event: InputEvent) -> void:
	if (event is InputEventScreenDrag):
		UpdateSteer(event.relative, event.position)
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		UpdateSteer(event.relative, event.position)
		
func On_Drone_Range_Input(event: InputEvent) -> void:
	if (event is InputEventScreenDrag):
		UpdateRange(event.relative, event.position)
	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		UpdateRange(event.relative, event.position)
		
func _on_turn_off_button_pressed() -> void:
	$Control/TouchStopper.mouse_filter = MOUSE_FILTER_STOP
	if (Armed):
		_on_dissarm_drone_button_2_pressed()
		await $AnimationPlayer.animation_finished
	$AnimationPlayer.play("Hide")

func _on_drone_range_slider_value_changed(value: float) -> void:
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer4/Label2.text = var_to_str(value / 2)
	DroneDockEventH.OnDronRangeChanged(value)
