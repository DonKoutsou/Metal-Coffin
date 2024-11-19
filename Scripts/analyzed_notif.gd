extends Control

class_name AnalyzeNotif

var EntityToFollow : Node2D
var camera : Camera2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = ShipCamera.GetInstance()
	$AnimationPlayer.play("Show")
	
func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()

func _physics_process(_delta: float) -> void:
	#rotation = -get_parent().rotation
	scale = Vector2(1,1) / camera.zoom
