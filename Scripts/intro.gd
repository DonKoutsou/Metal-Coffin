extends Control

class_name Intro

@export_multiline var Text : String

@export var TextLabel : Label

signal IntroFinished

var Tw : Tween

func _ready() -> void:
	$SubViewportContainer/SubViewport/TownBackground.set_physics_process(false)
	$SubViewportContainer/SubViewport/TownBackground.Dissable()
	TextLabel.text = Text
	Tw = create_tween()
	Tw.tween_property(TextLabel, "position", Vector2(TextLabel.position.x,-TextLabel.size.y - get_viewport_rect().size.y), 2.5 * TextLabel.get_line_count())
	await Tw.finished
	IntroFinished.emit()
	#queue_free()


func _on_skip_button_pressed() -> void:
	#Tw.kill()
	Tw.finished.emit()
