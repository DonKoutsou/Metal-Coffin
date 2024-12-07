extends Control
class_name MissileTab

var Armed = false
@export var MissileDockEventH : MissileDockEventHandler
var Missiles : Array[MissileItem]
var CurrentlySelectedMissile 

func _ready() -> void:
	MissileDockEventH.connect("MissileAdded", MissileAdded)
	MissileDockEventH.connect("MissileRemoved", MissileRemoved)
	$Control/Control/Dissarm.ToggleDissable(true)
	$Control/Control/Launch.ToggleDissable(true)
	#visible = false

func MissileAdded(MIs : MissileItem) -> void:
	Missiles.append(MIs)
	#visible = DockedDrones.size() > 0
	if (CurrentlySelectedMissile == null):
		UpdateCrewSelect()

func MissileRemoved(MIs : MissileItem) -> void:

	Missiles.erase(MIs)
	#visible = DockedDrones.size() > 0
	
	if (MIs == CurrentlySelectedMissile):
		CurrentlySelectedMissile = null
		UpdateCrewSelect()

func _on_deploy_drone_button_pressed() -> void:
	MissileDockEventH.OnMissileLaunched(CurrentlySelectedMissile)
	_on_dissarm_drone_button_2_pressed()
	
func _on_arm_drone_button_pressed(t : bool) -> void:
	
	if (Missiles.size() == 0):
		_on_dissarm_drone_button_2_pressed()
		return
	if (!t):
		_on_dissarm_drone_button_2_pressed()
		return
	Armed = true
	#$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer3/HBoxContainer2/ArmDroneButton.disabled = true
	$Control/Control/Dissarm.ToggleDissable(false)
	$Control/Control/Launch.ToggleDissable(false)

	MissileDockEventH.MissileArmed(CurrentlySelectedMissile)
	
func _on_dissarm_drone_button_2_pressed() -> void:
	Armed = false
	$Control/Control/Arm.button_pressed = false
	$Control/Control/Dissarm.ToggleDissable(true)
	$Control/Control/Launch.ToggleDissable(true)
	MissileDockEventH.MissileDissarmed()

func _on_toggle_drone_tab_pressed() -> void:
	$Control/TouchStopper.mouse_filter = MOUSE_FILTER_IGNORE
	$AnimationPlayer.play("Show")
	UpdateCrewSelect()
		
var SteeringDir : float = 0.0
#signal SteeringDitChanged(NewValue : float)
#signal MouseEntered()
#signal MouseExited()

func UpdateSteer(RelativeRot : float):
	if (Armed):
		#var rel = clamp(RelativeRot / 100, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
		#var prevsteer = SteeringDir
		SteeringDir = RelativeRot
		
		#if (EvPos.x < $Control/Node2D.position.x):
		#	$Control/Node2D/Sprite2D.rotation += rel.x + -rel.y
		#	SteeringDir += (rel.x + -rel.y) * 10
		#else :
		#	$Control/Node2D/Sprite2D.rotation += rel.x + rel.y
		#	SteeringDir += (rel.x + rel.y) * 10
		#if (SteeringDir != prevsteer):
		MissileDockEventH.MissileDirectionChanged(SteeringDir / 50)
		#if (!$Control/Node2D/AudioStreamPlayer.playing):
			#$Control/Node2D/AudioStreamPlayer.playing = true
		#Input.vibrate_handheld(5)
	
	else:
		ProgressCrewSelect()
#var RangeDir : float = 0.0
#func UpdateRange(RelativeRot : Vector2, EvPos : Vector2):
	#var rel = clamp(RelativeRot / 100, Vector2(-0.3, -0.3), Vector2(0.3, 0.3))
	#var prevrange = RangeDir
	#
	#if (EvPos.x < $Control/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer/TextureButton.position.x + 64):
		#$Control/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer/TextureButton.rotation += rel.x -rel.y
		#RangeDir = clamp(RangeDir + ((rel.x -rel.y) * 10), 0 , 100)
	#else :
		#$Control/PanelContainer/VBoxContainer/HBoxContainer/PanelContainer/TextureButton.rotation += rel.x + rel.y
		#RangeDir = clamp(RangeDir + ((rel.x + rel.y) * 10), 0, 100)
	#if (RangeDir != prevrange):
		#DroneDockEventH.OnDronRangeChanged(roundi(RangeDir))
	#if (!$Control/Node2D/AudioStreamPlayer.playing):
		#$Control/Node2D/AudioStreamPlayer.playing = true
	#$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer3/HBoxContainer2/PanelContainer/VBoxContainer/Label2.text = var_to_str(roundi(RangeDir / 2))
#func UpdateDroneRange(Rang : float):
	#if (Armed):
		#RangeDir = clamp(RangeDir + Rang, 0, 100)
		#DroneDockEventH.OnDronRangeChanged(roundi(RangeDir))
		#$Control/Control/Label.text = "Fuel Cost : " + var_to_str(roundi(RangeDir / 2))
	#else:
		#ProgressCrewSelect()
	
#func _on_area_2d_input_event(event: InputEvent) -> void:
	#if (event is InputEventScreenDrag):
		#UpdateSteer(event.relative, event.position)
	#if (event is InputEventMouseMotion and Input.is_action_pressed("Click")):
		#UpdateSteer(event.relative, event.position)
		
func UpdateCrewSelect(Select : int = 0):
	if (Missiles.size() > Select):
		CurrentlySelectedMissile = Missiles[Select]
		$Control/TextureRect/Label2.text = CurrentlySelectedMissile.MissileName
		$Control/Control/Label.text = "Range : " + var_to_str(CurrentlySelectedMissile.Distance) + "km"
		$Control/TextureRect/Light.Toggle(true, true)
	else:
		$Control/TextureRect/Label2.text = "No Missiles"
		$Control/TextureRect/Light.Toggle(true)
func ProgressCrewSelect():
	if (Missiles.size() == 0):
		$Control/TextureRect/Label2.text = "No Missiles"
		$Control/TextureRect/Light.Toggle(true)
		return
	if (CurrentlySelectedMissile == null):
		CurrentlySelectedMissile = Missiles[0]
	else:
		var i = Missiles.find(CurrentlySelectedMissile) + 1
		if (i >= Missiles.size()):
			i = 0
		CurrentlySelectedMissile = Missiles[i]
	$Control/TextureRect/Light.Toggle(true, true)
	$Control/TextureRect/Label2.text = CurrentlySelectedMissile.MissileName

func _on_turn_off_button_pressed() -> void:
	$Control/TouchStopper.mouse_filter = MOUSE_FILTER_STOP
	if (Armed):
		_on_dissarm_drone_button_2_pressed()
	$AnimationPlayer.play("Hide")

func _on_drone_range_slider_value_changed(value: float) -> void:
	$Control/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer4/Label2.text = var_to_str(value / 2)
	#DroneDockEventH.OnDronRangeChanged(value)
