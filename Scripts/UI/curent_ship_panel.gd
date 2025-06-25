extends PanelContainer

class_name CurrentShipPanel

@export var Sep : Control

signal Selected(Cpt : PlayerDrivenShip)
signal button_down

var ConnectedShip : PlayerDrivenShip

var IsSelected : bool
var Hovered : bool

func _ready() -> void:
	UiSoundManager.GetInstance().AddSelf(self)

func _exit_tree() -> void:
	UiSoundManager.GetInstance().RemoveSelf(self)

func SetText(Text : String, Capital : bool) -> void:
	$HBoxContainer/Label.text = Text
	$HBoxContainer/Label.uppercase = Capital
	$HBoxContainer/Label.visible = Text != ""
	#if ($VBoxContainer.get_child_count() != Text.size()):
		#for g in $VBoxContainer.get_children():
			#g.free()
			#
		#for g in Text.size():
			#var Hb = HBoxContainer.new()
			#var Sep = Control.new()
			##Hb.alignment = BoxContainer.ALIGNMENT_END
			#var L = Label.new()
			#
			#L.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			#L.text = Text[g]
			#
			#$VBoxContainer.add_child(Hb)
			#Hb.add_child(L)
			#Hb.add_child(Sep)
			#
			#Sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
			#Hb.alignment = BoxContainer.ALIGNMENT_END
			#Hb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			#L.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			#L.add_theme_font_size_override("", 14)
	#else:
		#for g in Text.size():
			#$VBoxContainer.get_child(g).get_child(0).text = Text[g]

func SetSelected(t : bool) -> void:
	IsSelected = t
	#var c = $HBoxContainer/Control
	#for g in $VBoxContainer.get_child_count():
		#var c = $VBoxContainer.get_child(g).get_child(1) as Control
	if (t):
		if (Sep.custom_minimum_size.x != 50):
			var tw = create_tween()
			tw.set_ease(Tween.EASE_OUT)
			tw.set_trans(Tween.TRANS_QUAD)
			tw.tween_property(Sep, "custom_minimum_size", Vector2(50, 0), 0.3)
	else:
		if (Sep.custom_minimum_size.x != 0 and !Hovered):
			var tw = create_tween()
			tw.set_ease(Tween.EASE_OUT)
			tw.set_trans(Tween.TRANS_QUAD)
			tw.tween_property(Sep, "custom_minimum_size", Vector2(0, 0), 0.3)



func _on_gui_input(event: InputEvent) -> void:
	if (event.is_action_pressed("Click") and ConnectedShip != null):
		Selected.emit(ConnectedShip)
		button_down.emit()
		Hovered = false


func _on_mouse_entered() -> void:
	if (IsSelected or ConnectedShip == null):
		return
	
	Hovered = true
	
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(Sep, "custom_minimum_size", Vector2(30, 0), 0.3)


func _on_mouse_exited() -> void:
	if (IsSelected or ConnectedShip == null):
		return
	
	Hovered = false
	
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(Sep, "custom_minimum_size", Vector2(0, 0), 0.3)
