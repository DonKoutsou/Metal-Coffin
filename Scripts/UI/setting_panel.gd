extends PanelContainer

class_name SettingsPanel

@export var mat : ShaderMaterial

static var HasGlitch = true

func _ready() -> void:
	$VBoxContainer/HBoxContainer3/GlitchesCheckBox.set_pressed_no_signal(HasGlitch)
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

static func GetGlitch() -> bool:
	return HasGlitch

func _on_glitches_check_box_toggled(toggled_on: bool) -> void:
	HasGlitch = toggled_on
	ToggleScreenGlitches(toggled_on)

func ToggleScreenGlitches(t : bool) -> void:

	var ImageFlicker = 0
	var Skip = 0
	if (t):
		ImageFlicker = 0.25
		Skip = 0.01
		
	mat.set_shader_parameter("image_flicker", ImageFlicker)
	mat.set_shader_parameter("skip", Skip)
