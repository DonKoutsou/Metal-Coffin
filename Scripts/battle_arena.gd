extends Node2D
class_name BattleArena

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TouchScreenButton.visible = OS.get_name() != "Windows"
	$TouchScreenButton2.visible = OS.get_name() != "Windows"
	$TouchScreenButton3.visible = OS.get_name() != "Windows"
