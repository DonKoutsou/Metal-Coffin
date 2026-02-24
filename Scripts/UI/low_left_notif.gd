extends Control

class_name ResuplyNotification

@export var Line : Line2D
@export var DetailPanel : Control
@export var ShipDetailLabel : Label

var ShowingStats : Dictionary

var EntityToFollow : Node2D
var camera : Camera2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UpdateCameraZoom(Map.GetCameraZoom())

func ToggleStat(Stat: String, t : bool, timel : float = 0):
	if (t):
		ShowingStats[Stat] = timel
	else :
		ShowingStats.erase(Stat)
	
	if (ShowingStats.size() == 0):
		queue_free()
		return
	
	var statstring : String = ""
	for g in ShowingStats:
		if (statstring != ""):
			statstring += "\n"
		var Hours = 0
		var Mins = ShowingStats[g]
		statstring += g + "\n"
		while Mins > 59:
			Hours += 1
			Mins -= 60
		if (Hours > 0):
			statstring += "{0} hour(s) ".format([Hours])
		if (Mins > 0):
			statstring += "{0} minute(s) ".format([roundi(Mins)])
		
	ShipDetailLabel.text = statstring
	
func OnShipDeparted(_DepartedFrom : MapSpot):
	queue_free()

func UpdateCameraZoom(NewZoom : float) -> void:
	DetailPanel.scale = Vector2(1,1) / NewZoom
	UpdateLine(NewZoom)
	Line.width =  1.5 / NewZoom
	rotation = - get_parent().get_parent().rotation

func UpdateLine(Zoom : float)-> void:
	var locp = get_closest_point_on_rect(ShipDetailLabel.get_global_rect(),DetailPanel.global_position)
	Line.set_point_position(1, locp - Line.global_position)
	Line.set_point_position(0, global_position.direction_to(locp) * 30 / Zoom)
	
func UpdateSignRotation() -> void:
	DetailPanel.rotation += 0.01
	ShipDetailLabel.pivot_offset = ShipDetailLabel.size / 2
	$Control/PanelContainer.rotation -= 0.01
	#$Control/PanelContainer/VBoxContainer.pivot_offset = get_closest_point_on_rect($Control/PanelContainer/VBoxContainer.get_global_rect(), c.global_position) - $Control/PanelContainer/VBoxContainer.global_position
	var locp = get_closest_point_on_rect(ShipDetailLabel.get_global_rect(), DetailPanel.global_position)
	Line.set_point_position(1, locp - Line.global_position)
	Line.set_point_position(0, global_position.direction_to(locp) * 30)

	
func get_closest_point_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	var closest_x = clamp(point.x, rect.position.x, rect.position.x + rect.size.x)
	var closest_y = clamp(point.y, rect.position.y, rect.position.y + rect.size.y)
	return Vector2(closest_x, closest_y)
