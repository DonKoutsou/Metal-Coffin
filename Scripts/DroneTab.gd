extends Control
class_name DroneTab

func _on_deploy_drone_button_pressed() -> void:
	pass # Replace with function body.
	
func _on_arm_drone_button_pressed() -> void:
	$Control/PanelContainer/VBoxContainer/HBoxContainer2/ArmDroneButton.disabled = true
	$Control/PanelContainer/VBoxContainer/HBoxContainer2/DeployDroneButton.disabled = false
	$AnimationPlayer.play("ShowSteer")

func _on_looter_drone_button_pressed() -> void:
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/LooterDroneButton.disabled = true
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/ReconDronButton.disabled = false
	$Control/PanelContainer/VBoxContainer/Label.text = "Armed Drone : Looter"

func _on_recon_dron_button_pressed() -> void:
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/LooterDroneButton.disabled = false
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/ReconDronButton.disabled = true
	$Control/PanelContainer/VBoxContainer/Label.text = "Armed Drone : Recon"

func _on_toggle_drone_tab_pressed() -> void:
	$AnimationPlayer.play("Show")

var MouseIn : bool

var SteeringDir : float = 0.0

var previous_mouse_angle = 0.0

signal SteeringDitChanged(NewValue : float)
signal MouseEntered()
signal MouseExited()

func _on_texture_rect_mouse_entered() -> void:
	MouseIn = true
	MouseEntered.emit()
func _on_texture_rect_mouse_exited() -> void:
	MouseIn = false
	MouseExited.emit()

func UpdateSteer(RelativeRot : Vector2, EvPos : Vector2):
	var rel = clamp(RelativeRot / 100, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
	var prevsteer = SteeringDir

	if (EvPos.x < $Control/Node2D/Area2D.position.x):
		$Control/Node2D/Sprite2D.rotation += rel.x + -rel.y
		SteeringDir += (rel.x + -rel.y) * 10
	else :
		$Control/Node2D/Sprite2D.rotation += rel.x + rel.y
		SteeringDir += (rel.x + rel.y) * 10
	if (SteeringDir != prevsteer):
		SteeringDitChanged.emit(SteeringDir)
	if (!$Control/Node2D/AudioStreamPlayer.playing):
		$Control/Node2D/AudioStreamPlayer.playing = true

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if (!MouseIn):
		return
	if (event is InputEventScreenDrag):
		UpdateSteer(event.relative, event.position)

	if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		UpdateSteer(event.relative, event.position)
