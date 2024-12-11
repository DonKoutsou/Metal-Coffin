extends Control

class_name LowLeftNotif

@export var Rotate : bool = false

var ShowingStats : Dictionary

var EntityToFollow : Node2D
var camera : Camera2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = ShipCamera.GetInstance()

func ToggleStat(Stat: String, t : bool, timel : float = 0):
	if (t):
		ShowingStats[Stat] = timel
	else :
		ShowingStats.erase(Stat)
	
	if (ShowingStats.size() == 0):
		queue_free()
		return
	
	var statstring : String
	for g in ShowingStats:
		statstring += g + " " + var_to_str(ShowingStats[g]).replace(".0", "") + "\n" 
	$Control/Label.text = statstring
	
func OnShipDeparted():
	queue_free()

func _physics_process(_delta: float) -> void:
	rotation = - get_parent().get_parent().rotation
	$Control.scale = Vector2(1,1) / camera.zoom
	UpdateLine()
	$Line2D.width =  2 / camera.zoom.x

func UpdateLine()-> void:
	var c = $Control as Control
	var locp = get_closest_point_on_rect($Control/Label.get_global_rect(), c.global_position)
	$Line2D.set_point_position(1, locp - $Line2D.global_position)
	$Line2D.set_point_position(0, global_position.direction_to(locp) * 30)
	
func UpdateSignRotation() -> void:
	var c = $Control as Control
	c.rotation += 0.1
	$Control/Label.pivot_offset = $Control/Label.size / 2
	$Control/Label.rotation -= 0.1
	#$Control/PanelContainer/VBoxContainer.pivot_offset = get_closest_point_on_rect($Control/PanelContainer/VBoxContainer.get_global_rect(), c.global_position) - $Control/PanelContainer/VBoxContainer.global_position
	var locp = get_closest_point_on_rect($Control/Label.get_global_rect(), c.global_position)
	$Line2D.set_point_position(1, locp - $Line2D.global_position)
	$Line2D.set_point_position(0, global_position.direction_to(locp) * 30)

	
func get_closest_point_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	var closest_x = clamp(point.x, rect.position.x, rect.position.x + rect.size.x)
	var closest_y = clamp(point.y, rect.position.y, rect.position.y + rect.size.y)
	return Vector2(closest_x, closest_y)
