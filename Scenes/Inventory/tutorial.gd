extends Control

class_name Tutorial

@export var Pan : VBoxContainer

@export var TitleLabel : Label
@export var TextLabel : RichTextLabel
@export var Line : Line2D
@export var Line2 : Line2D
@export var InSound : AudioStream
@export var OutSound : AudioStream

var Target : Node
var Target2 : Node
var Line1Target : Vector2
var Line2Target : Vector2

var MyOriginalSize : Vector2
var OriginalSize : Vector2

signal Completed

func SetData(Title : String, Text : String, TutorialSubjects : Array[Map.UI_ELEMENT]) -> void:
	TitleLabel.text = Title
	TextLabel.text = Text
	if (TutorialSubjects.size() > 0):
		Target = Map.GetInstance().GetUIElement(TutorialSubjects[0])
		
		
		
	if (TutorialSubjects.size() > 1):
		Target2 = Map.GetInstance().GetUIElement(TutorialSubjects[1])
	

func _ready() -> void:
	set_physics_process(false)
	UISoundMan.GetInstance().AddSelf($VBoxContainer/Button)
	call_deferred("DoFadeInAnim")
	
	var R1 = Rect2(0,0,0,0)
	var R2 = Rect2(0,0,0,0)
	
	if (Target2 != null):
		R2 = Target2.get_global_rect()
			
	if (Target != null):
		R1 = Target.get_global_rect()
	
	SetTargetRect(R1, R2)
	

func DoFadeInAnim() -> void:
	TextLabel.visible_ratio = 0
	Pan.size.y = 0
	#MyOriginalSize = size
	OriginalSize = Pan.size
	
	$VBoxContainer/PanelContainer/VBoxContainer2.visible = false
	$VBoxContainer/Button.visible = false
	
	Pan.size = Vector2.ZERO
	Pan.position = size/2 - Pan.size/2
	
	#size = Vector2.ZERO
	#position = get_viewport_rect().size / 2
	
	var Tw = create_tween()
	Tw.set_ease(Tween.EASE_OUT)
	Tw.set_trans(Tween.TRANS_BACK)
	Tw.tween_method(UpdateSize, Vector2.ZERO, OriginalSize, 1)
	Tw.set_parallel(true)
	Tw.tween_method(UpdateDarkness, 0.0, 0.8, 1)
	
	var S = DeletableSoundGlobal.new()
	S.stream = InSound
	S.autoplay = true
	add_child(S)
	
	#if (Target != null):
		#Target.connect("tree_exited", queue_free)
	#else:
		#Line.visible = false
	
	await Tw.finished
	
	InScreenCursor.Instance.ToggleMouse(false)
	Input.mouse_mode =  Input.MOUSE_MODE_VISIBLE
	
	set_physics_process(true)
	$VBoxContainer/PanelContainer/VBoxContainer2.visible = true
	$VBoxContainer/Button.visible = true
	
func SetTargetRect(r : Rect2 = Rect2(0,0,0,0), r2 : Rect2 = Rect2(0,0,0,0)) -> void:
	var mat =  $ColorRect.material as ShaderMaterial
	mat.set_shader_parameter("rect1_pos", r.position / get_viewport_rect().size)
	mat.set_shader_parameter("rect1_size", r.size / get_viewport_rect().size)
	
	mat.set_shader_parameter("rect2_pos", r2.position / get_viewport_rect().size)
	mat.set_shader_parameter("rect2_size", r2.size / get_viewport_rect().size)

func UpdateSize(NewSize : Vector2) -> void:
	Pan.size = NewSize
	Pan.position = size/2 - Pan.size/2

func UpdateDarkness(Darkness : float) -> void:
	var mat =  $ColorRect.material as ShaderMaterial
	mat.set_shader_parameter("darkness", Darkness)
	#size = lerp(Vector2.ZERO, OriginalSize, NewSize.x / OriginalSize.x)
	#position = get_viewport_rect().size / 2 - size / 2
	
	#if (Target != null):
		#Line1Target = lerp(Line.global_position, Target.global_position + Vector2( Target.size.x / 2, 0), NewSize.x / OriginalSize.x)
		#Line.set_point_position(1, Line.to_local(Line1Target))
	#if (Target2 != null):
		#Line2Target = lerp(Line2.global_position, Target2.global_position + Vector2( Target2.size.x / 2, 0), NewSize.x / OriginalSize.x)
		#Line2.set_point_position(1, Line2.to_local(Line2Target))

func _physics_process(delta: float) -> void:
	
	
	#if (Target != null):
		#Line.set_point_position(1, Line.to_local(Line1Target))
	#if (Target2 != null):
		#Line2.set_point_position(1, Line2.to_local(Line2Target))
	
	if (TextLabel.is_visible_in_tree()):
		TextLabel.visible_ratio += delta

func _on_button_pressed() -> void:
	set_physics_process(false)
	InScreenCursor.Instance.ToggleMouse(true)
	
	var Tw = create_tween()
	Tw.set_ease(Tween.EASE_IN)
	Tw.set_trans(Tween.TRANS_QUAD)
	Tw.tween_method(UpdateSize, OriginalSize, Vector2.ZERO, 1)
	Tw.set_parallel(true)
	Tw.tween_method(UpdateDarkness, 0.8, 0.0, 1)
	$VBoxContainer/PanelContainer/VBoxContainer2.visible = false
	$VBoxContainer/Button.visible = false
	
	var S = DeletableSoundGlobal.new()
	S.stream = OutSound
	S.autoplay = true
	add_child(S)

	await Tw.finished
	Completed.emit()
	
	queue_free()
