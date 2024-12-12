extends PanelContainer
class_name FadeNotif

var alph = 4

func SetText(t : String):
	$VBoxContainer/Label.text = t

func _physics_process(_delta: float) -> void:
	if (alph <= 0):
		queue_free()
	alph -= 0.05
	modulate.a = min(1, alph)
	pass

func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER, true)
