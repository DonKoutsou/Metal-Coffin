extends Control

class_name LowStatNotif

var EntityToFollow : Node2D
var camera : Camera2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = ShipCamera.GetInstance()
	$AnimationPlayer.play("Show")
func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()

func SetStatData(Stat : String) -> void:
	var col
	if (Stat == "HP"):
		col = Color(0.051, 0.533, 0.09)
	#else :if (Stat == "OXYGEN"):
		#col = Color(0.317, 0.353, 0.75)
	else :if (Stat == "HULL"):
		col = Color(0.169, 0.428, 0.621)
	else :if (Stat == "FUEL"):
		col = Color(0.781, 0.651, 0)
	
	$Label.text = Stat + " bellow 20%"
	$Line2D.default_color = col
	$Label.modulate = col
func _physics_process(delta: float) -> void:
	rotation = -EntityToFollow.rotation
	scale = Vector2(1,1) / camera.zoom
