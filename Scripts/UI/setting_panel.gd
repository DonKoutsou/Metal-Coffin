extends PanelContainer


func _ready() -> void:
	$VBoxContainer/HBoxContainer/FullScreenCheckBox.button_pressed = DisplayServer.window_get_mode(0) == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN
	$VBoxContainer/HBoxContainer2/SoundCheckBox.button_pressed = AudioServer.get_bus_volume_db(0) == 0
	
func _on_full_screen_check_box_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)


func _on_sound_check_box_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		AudioServer.set_bus_volume_db(0, 0)
	else:
		AudioServer.set_bus_volume_db(0, -64)
