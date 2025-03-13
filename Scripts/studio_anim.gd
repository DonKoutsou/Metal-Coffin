extends Control

class_name StudioAnimation

signal Finished

func _ready() -> void:
	$AnimationPlayer.play("LogoDraw")
	await $AnimationPlayer.animation_finished
	Finished.emit()
