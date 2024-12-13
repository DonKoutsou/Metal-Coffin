extends Control

class_name ShipMarker

#@export var EnemyLocatedNotifScene : PackedScene

@export var EnemyLocatedSound : AudioStream

#@export var DroneReturnNotif : PackedScene

@export var ResuplyNotificationScene : PackedScene

@export var NotificationScene : PackedScene

var camera : Camera2D

var TimeLastSeen : float

var DetailInitialPos : Vector2

var Showspeed : bool = false

signal ShipDeparted

func _ready() -> void:
	DetailInitialPos = $Control/PanelContainer/VBoxContainer.position
	camera = ShipCamera.GetInstance()
	$Control.visible = false
	$Line2D.visible = false
	$Control/PanelContainer/VBoxContainer/TimeSeen .visible = false
	$Control/PanelContainer/VBoxContainer/Threat.visible = false
	$Control/PanelContainer/VBoxContainer/Fuel.visible = false
	$Control/PanelContainer/VBoxContainer/Hull.visible = false
	set_physics_process(false)
func PlayHostileShipNotif() -> void:
	var notif = NotificationScene.instantiate() as ShipMarkerNotif
	notif.SetText("Hostile Ship Located")
	var sound = DeletableSoundGlobal.new()
	sound.stream = EnemyLocatedSound
	sound.volume_db = -10
	sound.bus = "UI"
	sound.autoplay = true
	add_child(sound)
	add_child(notif)
	
func OnShipDeparted() -> void:
	ShipDeparted.emit()

func DroneReturning() -> void:
	var notif = NotificationScene.instantiate() as ShipMarkerNotif
	notif.SetText("Drone Returning To Base")
	add_child(notif)
	
func ToggleShowRefuel(Stats : String, t : bool, timel : float = 0):
	var notif : ResuplyNotification
	for g in get_children():
		if g is ResuplyNotification:
			g.ToggleStat(Stats, t, timel)
			return
	if (t):
		notif = ResuplyNotificationScene.instantiate() as ResuplyNotification
		notif.ToggleStat(Stats, t, timel)
		connect("ShipDeparted", notif.OnShipDeparted)
		add_child(notif)

func ToggleShipDetails(T : bool):
	$Control.visible = T
	$Line2D.visible = T
	set_physics_process(T)
func ToggleFriendlyShipDetails(T : bool):
	$Control/PanelContainer/VBoxContainer/Fuel.visible = T
	$Control/PanelContainer/VBoxContainer/Hull.visible = T
func OnStatLow(StatName : String) -> void:
	var notif = NotificationScene.instantiate() as ShipMarkerNotif
	notif.SetText(StatName + " bellow 20%")
	#notif.SetStatData(StatName)
	#notif.rotation = -rotation
	#notif.EntityToFollow = self
	add_child(notif)
	
func SetMarkerDetails(ShipName : String, ShipCasllSign : String, ShipSpeed : float):
	$Control/PanelContainer/VBoxContainer/ShipName.text = ShipName
	$Control/PanelContainer/VBoxContainer/ShipName2.text = "Speed " + var_to_str((ShipSpeed * 60) * 3.6) + "km/h"
	$ShipSymbol.text = ShipCasllSign
	
func _physics_process(_delta: float) -> void:
	$Control.scale = Vector2(1,1) / camera.zoom
	#$Panel.scale = Vector2(1,1) / camera.zoom
	#$ShipSymbol.scale = Vector2(1,1) / camera.zoom
	UpdateLine()
	$Line2D.width =  2 / camera.zoom.x

func UpdateLine()-> void:
	var c = $Control as Control
	var locp = get_closest_point_on_rect($Control/PanelContainer/VBoxContainer.get_global_rect(), c.global_position)
	$Line2D.set_point_position(1, locp - $Line2D.global_position)
	$Line2D.set_point_position(0, global_position.direction_to(locp) * 30)

func UpdateSpeed(Spd : float):
	var spd = roundi((Spd * 60) * 3.6)
	$Control/PanelContainer/VBoxContainer/ShipName2.text = "Speed " + var_to_str(spd) + "km/h"
func UpdateFuel():
	var curfuel = roundi(ShipData.GetInstance().GetStat("FUEL").GetCurrentValue())
	var maxf = ShipData.GetInstance().GetStat("FUEL").GetStat()
	$Control/PanelContainer/VBoxContainer/Fuel.text = "Fuel: {0} / {1} Tons".format([curfuel, maxf])
func UpdateDroneFuel(amm : float):
	$Control/PanelContainer/VBoxContainer/Fuel.text = "Fuel: {0} Tons".format([amm])
func UpdateHull():
	$Control/PanelContainer/VBoxContainer/Hull.text = "Hull: {0} / {1}".format([roundi(ShipData.GetInstance().GetStat("HULL").GetCurrentValue()), ShipData.GetInstance().GetStat("HULL").GetStat()])
func UpdateDroneHull(amm : float, maxamm : float):
	$Control/PanelContainer/VBoxContainer/Hull.text = "Hull: {0} / {1}".format([amm, maxamm])
func ToggleThreat(T : bool):
	$Control/PanelContainer/VBoxContainer/Threat.visible = T

	
func UpdateThreatLevel(Level : float):
	$Control/PanelContainer/VBoxContainer/Threat.text = "Threat Level : " + var_to_str(roundi(Level))

	
func ToggleTimeLastSeend(T : bool):
	if (!T):
		TimeLastSeen = 0
	$Control/PanelContainer/VBoxContainer/TimeSeen.visible = T

func UpdateTime():
	TimeLastSeen += 0.01
	$Control/PanelContainer/VBoxContainer/TimeSeen.text = "Last Seen " + var_to_str(snappedf((TimeLastSeen / 60) , 0.01)) + "h ago"

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	$Control/PanelContainer/VBoxContainer.add_to_group("MapInfo")
	$Panel.add_to_group("UnmovableMapInfo")

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	$Control/PanelContainer/VBoxContainer.remove_from_group("MapInfo")
	$Panel.remove_from_group("UnmovableMapInfo")

func UpdateSignRotation() -> void:
	var c = $Control as Control
	c.rotation += 0.01
	$Control/PanelContainer.pivot_offset = $Control/PanelContainer.size / 2
	$Control/PanelContainer.rotation -= 0.01
	var locp = get_closest_point_on_rect($Control/PanelContainer/VBoxContainer.get_global_rect(), c.global_position)
	$Line2D.set_point_position(1, locp - $Line2D.global_position)
	$Line2D.set_point_position(0, global_position.direction_to(locp) * 30)

	
func get_closest_point_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	var closest_x = clamp(point.x, rect.position.x, rect.position.x + rect.size.x)
	var closest_y = clamp(point.y, rect.position.y, rect.position.y + rect.size.y)
	return Vector2(closest_x, closest_y)
