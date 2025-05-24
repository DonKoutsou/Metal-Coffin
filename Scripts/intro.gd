extends Control

class_name Intro

@export_multiline var Text : String

@export var TextLabel : Label

signal IntroFinished

func _ready() -> void:
	$SubViewportContainer/SubViewport/TownBackground.set_physics_process(false)
	$SubViewportContainer/SubViewport/TownBackground.Dissable()
	TextLabel.text = Text
	var Tw = create_tween()
	Tw.tween_property(TextLabel, "position", Vector2(0,-TextLabel.size.y), 2 * TextLabel.get_line_count())
	await Tw.finished
	IntroFinished.emit()
	#queue_free()
