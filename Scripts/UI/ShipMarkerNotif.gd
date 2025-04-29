extends Control

class_name ShipMarkerNotif

var EntityToFollow : Node2D

var Blink : bool = true
var Fast : bool = false

var CurrentZoom : float

func ToggleSimulation(t : bool) -> void:
	if (Blink):
		if (!t):
			$AnimationPlayer.play()
		else:
			$AnimationPlayer.pause()
			$AudioStreamPlayer.stop()
func _ready() -> void:
	if (Blink):
		$AnimationPlayer.play("Show")
		if (Fast):
			$AnimationPlayer.play("Show_2")
	UpdateCameraZoom(Map.GetCameraZoom())
	
func SetText(Txt : String) -> void:
	$Control/PanelContainer/Label.text = Txt
	
func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()

func UpdateCameraZoom(NewZoom : float) -> void:
	$Control.scale = Vector2(1,1) / NewZoom
	UpdateLine(NewZoom)
	$Line2D.width =  2 / NewZoom
	CurrentZoom = NewZoom
func UpdateLine(Zoom : float)-> void:
	var c = $Control as Control
	var locp = get_closest_point_on_rect($Control/PanelContainer/Label.get_global_rect(), c.global_position)
	$Line2D.set_point_position(1, locp - $Line2D.global_position)
	$Line2D.set_point_position(0, global_position.direction_to(locp) * 30 / Zoom)
	
func UpdateSignRotation() -> void:
	var c = $Control as Control
	c.rotation += 0.01
	$Control/PanelContainer/Label.pivot_offset = $Control/PanelContainer/Label.size / 2
	$Control/PanelContainer.rotation -= 0.01
	#$Control/PanelContainer/VBoxContainer.pivot_offset = get_closest_point_on_rect($Control/PanelContainer/VBoxContainer.get_global_rect(), c.global_position) - $Control/PanelContainer/VBoxContainer.global_position
	var locp = get_closest_point_on_rect($Control/PanelContainer/Label.get_global_rect(), c.global_position)
	$Line2D.set_point_position(1, locp - $Line2D.global_position)
	$Line2D.set_point_position(0, global_position.direction_to(locp) * 30 / CurrentZoom)

	
func get_closest_point_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	var closest_x = clamp(point.x, rect.position.x, rect.position.x + rect.size.x)
	var closest_y = clamp(point.y, rect.position.y, rect.position.y + rect.size.y)
	return Vector2(closest_x, closest_y)
