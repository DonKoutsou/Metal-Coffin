extends Control

class_name Tutorial

@export var TitleLabel : Label
@export var TextLabel : RichTextLabel
@export var Line : Line2D

var Target : Control

func SetData(Title : String, Text : String, TutorialSubject : Control) -> void:
	TitleLabel.text = Title
	TextLabel.text = Text
	TextLabel.visible_ratio = 0
	Target = TutorialSubject

func _ready() -> void:
	if (Target != null):
		Target.connect("tree_exited", queue_free)
	else:
		Line.visible = false
func _physics_process(delta: float) -> void:
	if (Target != null):
		Line.set_point_position(1, Line.to_local(Target.global_position))
	
	TextLabel.visible_ratio += delta

func _on_button_pressed() -> void:
	queue_free()
