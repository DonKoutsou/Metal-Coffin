extends Control

class_name ShipMarker

@export var EnemyLocatedNotifScene : PackedScene

@export var EnemyLocatedSound : AudioStream

@export var DroneReturnNotif : PackedScene

@export var LowleftNotif : PackedScene

var camera : Camera2D

var TimeLastSeen : float

var DetailInitialPos : Vector2

signal ShipDeparted

func _ready() -> void:
	DetailInitialPos = $Control/PanelContainer/VBoxContainer.position
	camera = ShipCamera.GetInstance()
	$Control.visible = false
	$Line2D.visible = false
	$Control/PanelContainer/VBoxContainer/TimeSeen .visible = false
	$Control/PanelContainer/VBoxContainer/Threat.visible = false
	set_physics_process(false)
func PlayHostileShipNotif() -> void:

	var notif = EnemyLocatedNotifScene.instantiate()
	var sound = DeletableSoundGlobal.new()
	sound.stream = EnemyLocatedSound
	sound.volume_db = -10
	sound.bus = "UI"
	sound.autoplay = true
	add_child(sound)
	add_child(notif)
	#UpdatePivot()
	
func OnShipDeparted() -> void:
	ShipDeparted.emit()

func DroneReturning() -> void:
	var notif = DroneReturnNotif.instantiate()
	add_child(notif)
	
func ToggleShowRefuel(Stats : String, t : bool, timel : float = 0):
	var notif : LowLeftNotif
	for g in get_children():
		if g is LowLeftNotif:
			g.ToggleStat(Stats, t, timel)
			return
	if (t):
		notif = LowleftNotif.instantiate() as LowLeftNotif
		notif.ToggleStat(Stats, t, timel)
		connect("ShipDeparted", notif.OnShipDeparted)
		add_child(notif)

func ToggleShipDetails(T : bool):
	$Control.visible = T
	$Line2D.visible = T
	set_physics_process(T)

func OnStatLow(StatName : String) -> void:
	var notif = (load("res://Scenes/LowStatNotif.tscn") as PackedScene).instantiate() as LowStatNotif
	notif.SetStatData(StatName)
	notif.rotation = -rotation
	notif.EntityToFollow = self
	#notif.camera = $"../../Camera2D"
	$Notifications.add_child(notif)
	
	#Ingame_UIManager.GetInstance().AddUI(notif)
	
func SetMarkerDetails(ShipName : String, ShipCasllSign : String, ShipSpeed : float):
	$Control/PanelContainer/VBoxContainer/ShipName.text = ShipName
	$Control/PanelContainer/VBoxContainer/ShipName2.text = "Speed " + var_to_str((ShipSpeed * 60) * 3.6) + "km/h"
	$ShipSymbol.text = ShipCasllSign

func _physics_process(_delta: float) -> void:
	#UpdatePivot()
	$Control.scale = Vector2(1,1) / camera.zoom
	UpdateLine()
	$Line2D.width =  2 / camera.zoom.x
	#$Control/PanelContainer.position.y = - (200 * $Control/PanelContainer/VBoxContainer.scale.x)

func UpdateLine()-> void:
	var c = $Control as Control
	var locp = get_closest_point_on_rect($Control/PanelContainer/VBoxContainer.get_global_rect(), c.global_position)
	$Line2D.set_point_position(1, locp - $Line2D.global_position)
	$Line2D.set_point_position(0, global_position.direction_to(locp) * 30)

func UpdateSpeed(Spd : float):
	$Control/PanelContainer/VBoxContainer/ShipName2.text = "Speed " + var_to_str((Spd * 60) * 3.6) + "km/h"

	
func ToggleThreat(T : bool):
	$Control/PanelContainer/VBoxContainer/Threat.visible = T

	
func UpdateThreatLevel(Level : float):
	$Control/PanelContainer/VBoxContainer/Threat.text = "Threat Level : " + var_to_str(Level)

	
func ToggleTimeLastSeend(T : bool):
	if (!T):
		TimeLastSeen = 0
	$Control/PanelContainer/VBoxContainer/TimeSeen.visible = T

func UpdateTime():
	TimeLastSeen += 0.01
	$Control/PanelContainer/VBoxContainer/TimeSeen.text = "Last Seen " + var_to_str(snappedf((TimeLastSeen / 60) , 0.01)) + "h ago"

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	$Control/PanelContainer/VBoxContainer.add_to_group("MapInfo")

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	$Control/PanelContainer/VBoxContainer.remove_from_group("MapInfo")

func UpdateSignRotation() -> void:
	var c = $Control as Control
	c.rotation += 0.1
	$Control/PanelContainer.pivot_offset = $Control/PanelContainer.size / 2
	$Control/PanelContainer.rotation -= 0.1
	#$Control/PanelContainer/VBoxContainer.pivot_offset = get_closest_point_on_rect($Control/PanelContainer/VBoxContainer.get_global_rect(), c.global_position) - $Control/PanelContainer/VBoxContainer.global_position
	var locp = get_closest_point_on_rect($Control/PanelContainer/VBoxContainer.get_global_rect(), c.global_position)
	$Line2D.set_point_position(1, locp - $Line2D.global_position)
	$Line2D.set_point_position(0, global_position.direction_to(locp) * 30)

	
func get_closest_point_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	var closest_x = clamp(point.x, rect.position.x, rect.position.x + rect.size.x)
	var closest_y = clamp(point.y, rect.position.y, rect.position.y + rect.size.y)
	return Vector2(closest_x, closest_y)
