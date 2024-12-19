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
	if (CurrentlySelectedMissile == null):
		UpdateCrewSelect()

func MissileRemoved(MIs : MissileItem) -> void:
	Missiles.erase(MIs)
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

func UpdateSteer(RelativeRot : float):
	if (Armed):
		SteeringDir = RelativeRot
		MissileDockEventH.MissileDirectionChanged(SteeringDir / 50)
	else:
		ProgressCrewSelect()

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
