extends PanelContainer

class_name PrologueEnd

signal Finished

func _ready() -> void:
	modulate = Color(1,1,1,0)
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1,1,1,1), 1)


func _on_button_2_pressed() -> void:
	Finished.emit()
