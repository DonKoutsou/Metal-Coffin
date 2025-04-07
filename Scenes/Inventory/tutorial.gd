extends Control

class_name Tutorial

@export var Pan : VBoxContainer

@export var TitleLabel : Label
@export var TextLabel : RichTextLabel
@export var Line : Line2D
@export var Line2 : Line2D
@export var InSound : AudioStream
@export var OutSound : AudioStream

var Target : Control
var Target2 : Control
var Line1Target : Vector2
var Line2Target : Vector2

var OriginalSize : Vector2

signal Completed

func SetData(Title : String, Text : String, TutorialSubjects : Array[Control]) -> void:
	TitleLabel.text = Title
	TextLabel.text = Text
	if (TutorialSubjects.size() > 0):
		Target = TutorialSubjects[0]
	if (TutorialSubjects.size() > 1):
		Target2 = TutorialSubjects[1]
		
func _ready() -> void:
	UISoundMan.GetInstance().AddSelf($VBoxContainer/Button)
	call_deferred("DoFadeInAnim")

func DoFadeInAnim() -> void:
	TextLabel.visible_ratio = 0
	Pan.size.y = 0
	OriginalSize = Pan.size
	
	$VBoxContainer/PanelContainer/VBoxContainer2.visible = false
	$VBoxContainer/Button.visible = false
	
	Pan.size = Vector2.ZERO
	Pan.position = size/2 - Pan.size/2
	
	var Tw = create_tween()
	Tw.set_ease(Tween.EASE_IN)
	Tw.set_trans(Tween.TRANS_QUAD)
	Tw.tween_method(UpdateSize, Vector2.ZERO, OriginalSize, 1)
	
	var S = DeletableSoundGlobal.new()
	S.stream = InSound
	S.autoplay = true
	add_child(S)
	
	if (Target != null):
		Target.connect("tree_exited", queue_free)
	else:
		Line.visible = false
	
	await Tw.finished
	
	$VBoxContainer/PanelContainer/VBoxContainer2.visible = true
	$VBoxContainer/Button.visible = true
	
	

func UpdateSize(NewSize : Vector2) -> void:
	Pan.size = NewSize
	Pan.position = size/2 - Pan.size/2
	if (Target != null):
		Line1Target = lerp(Line.global_position, Target.global_position, NewSize.x / OriginalSize.x)
		Line.set_point_position(1, Line.to_local(Line1Target))
	if (Target2 != null):
		Line2Target = lerp(Line2.global_position, Target2.global_position, NewSize.x / OriginalSize.x)
		Line2.set_point_position(1, Line2.to_local(Line2Target))

func _physics_process(delta: float) -> void:
	if (Target != null):
		Line.set_point_position(1, Line.to_local(Line1Target))
	if (Target2 != null):
		Line2.set_point_position(1, Line2.to_local(Line2Target))
	
	if (TextLabel.is_visible_in_tree()):
		TextLabel.visible_ratio += delta

func _on_button_pressed() -> void:
	var Tw = create_tween()
	Tw.set_ease(Tween.EASE_OUT)
	Tw.set_trans(Tween.TRANS_QUAD)
	Tw.tween_method(UpdateSize, OriginalSize, Vector2.ZERO, 1)
	
	$VBoxContainer/PanelContainer/VBoxContainer2.visible = false
	$VBoxContainer/Button.visible = false
	
	var S = DeletableSoundGlobal.new()
	S.stream = OutSound
	S.autoplay = true
	add_child(S)
	
	await Tw.finished
	Completed.emit()
	queue_free()
