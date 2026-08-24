extends Node2D

class_name OrderMarker

@export var Icon : TextureRect
@export var text : Label

var CurrentZoom : float

var Order : Resource

func _process(_delta: float) -> void:
	if (Order is PursuitOrder):
		global_position = Order.Target.global_position

func SetOrder(NewOrder : Resource) -> void:
	Order = NewOrder
	if (NewOrder is InvestigationOrder):
		text.text = "Instastigate"
		global_position = NewOrder.Target
	else: if (NewOrder is PursuitOrder):
		text.text = "Pursuit"

func EnteredScreen() -> void:
	Icon.add_to_group("UnmovableMapInfo")
	text.add_to_group("UnmovableMapInfo")
	#SpotNameLabel.get_parent().add_to_group("UnmovableMapInfo")
	add_to_group("ZoomAffected")
	UpdateCameraZoom(Map.GetCameraZoom())

func LeftScreen() -> void:
	Icon.remove_from_group("UnmovableMapInfo")
	text.remove_from_group("UnmovableMapInfo")
	#SpotNameLabel.get_parent().remove_from_group("UnmovableMapInfo")
	remove_from_group("ZoomAffected")

func UpdateCameraZoom(NewZoom : float) -> void:
	queue_redraw()
	CurrentZoom = NewZoom
	Icon.scale = (Vector2(0.7,0.7) / NewZoom)
