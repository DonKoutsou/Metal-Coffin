extends PanelContainer
class_name FadeNotif

@export var T : Label

var alph = 4

var txt : String

signal Finished

func SetText(t : String):
	txt = t
	T.text = t
	T.visible_characters = 0

func _physics_process(_delta: float) -> void:
	if (txt.length() > T.visible_characters):
		T.visible_characters += 2
		return
	if (alph <= 0):
		queue_free()
	alph -= 0.1
	modulate.a = min(1, alph)

func _exit_tree() -> void:
	Finished.emit()
#func _ready() -> void:
	#set_anchors_preset(Control.PRESET_CENTER_LEFT, true)
	
