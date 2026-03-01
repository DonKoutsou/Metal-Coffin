extends Control

class_name ShipMarkerNotif

@export var anim : AnimationPlayer
@export var blinkSound : AudioStreamPlayer
@export var Line : Line2D
@export var DetailPanel : Control
@export var ShipDetailLabel : Label

var Blink : bool = true
var Fast : bool = false

var CurrentZoom : float

func ToggleSimulation(t : bool) -> void:
	if (Blink):
		if (!t):
			anim.play()
		else:
			anim.pause()
			blinkSound.stop()
			$Control/PanelContainer.visible = true
			
			
func _ready() -> void:
	if (Blink):
		anim.play("Show")
		if (Fast):
			anim.play("Show_2")
			
	UpdateCameraZoom(Map.GetCameraZoom())
	
func SetText(Txt : String) -> void:
	ShipDetailLabel.text = Txt
	
func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()

func UpdateCameraZoom(NewZoom : float) -> void:
	DetailPanel.scale = Vector2(1,1) / NewZoom
	UpdateLine(NewZoom)
	Line.width =  1.5 / NewZoom
	CurrentZoom = NewZoom
	
func UpdateLine(Zoom : float)-> void:
	var locp = get_closest_point_on_rect(ShipDetailLabel.get_global_rect(), DetailPanel.global_position)
	Line.set_point_position(1, locp - Line.global_position)
	Line.set_point_position(0, global_position.direction_to(locp) * 30 / Zoom)
	
func UpdateSignRotation() -> void:
	DetailPanel.rotation += 0.01
	ShipDetailLabel.pivot_offset = ShipDetailLabel.size / 2
	$Control/PanelContainer.rotation -= 0.01
	#$Control/PanelContainer/VBoxContainer.pivot_offset = get_closest_point_on_rect($Control/PanelContainer/VBoxContainer.get_global_rect(), c.global_position) - $Control/PanelContainer/VBoxContainer.global_position
	var locp = get_closest_point_on_rect(ShipDetailLabel.get_global_rect(), DetailPanel.global_position)
	Line.set_point_position(1, locp - Line.global_position)
	Line.set_point_position(0, global_position.direction_to(locp) * 30 / CurrentZoom)

	
func get_closest_point_on_rect(rect: Rect2, point: Vector2) -> Vector2:
	var closest_x = clamp(point.x, rect.position.x, rect.position.x + rect.size.x)
	var closest_y = clamp(point.y, rect.position.y, rect.position.y + rect.size.y)
	return Vector2(closest_x, closest_y)
