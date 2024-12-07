extends Control

class_name ShipMarker

var camera : Camera2D
var TimeLastSeen : float

func _ready() -> void:
	camera = ShipCamera.GetInstance()
	$Control.visible = false
	$Control/VBoxContainer/TimeSeen .visible = false
	$Control/VBoxContainer/Threat.visible = false
	set_physics_process(false)

func ToggleShipDetails(T : bool):
	$Control.visible = T
	set_physics_process(T)

func SetMarkerDetails(ShipName : String, ShipSpeed : float):
	$Control/VBoxContainer/ShipName.text = ShipName
	$Control/VBoxContainer/ShipName2.text = "Speed " + var_to_str((ShipSpeed * 60) * 3.6) + "km/h"

func _physics_process(_delta: float) -> void:
	$Control.scale = Vector2(1,1) / camera.zoom

func UpdateSpeed(Spd : float):
	$Control/VBoxContainer/ShipName2.text = "Speed " + var_to_str((Spd * 60) * 3.6) + "km/h"
	
func ToggleThreat(T : bool):
	$Control/VBoxContainer/Threat.visible = T
	
func UpdateThreatLevel(Level : float):
	$Control/VBoxContainer/Threat.text = "Threat Level : " + var_to_str(Level)
	
func ToggleTimeLastSeend(T : bool):
	if (!T):
		TimeLastSeen = 0
	$Control/VBoxContainer/TimeSeen.visible = T

func UpdateTime():
	TimeLastSeen += 0.01
	$Control/VBoxContainer/TimeSeen.text = "Last Seen " + var_to_str(snappedf((TimeLastSeen / 60) , 0.01)) + "h ago"
