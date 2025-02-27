extends PanelContainer
class_name FadeNotif

var alph = 4

var txt : String

func SetText(t : String):
	txt = t
	$HBoxContainer/Label.text = t

func _physics_process(_delta: float) -> void:
	if (txt.length() > $HBoxContainer/Label.visible_characters):
		$HBoxContainer/Label.visible_characters += 1
		return
	if (alph <= 0):
		queue_free()
	alph -= 0.05
	modulate.a = min(1, alph)
	pass

#func _ready() -> void:
	#set_anchors_preset(Control.PRESET_CENTER_LEFT, true)
	
