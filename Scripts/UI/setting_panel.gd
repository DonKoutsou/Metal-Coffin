extends PanelContainer

class_name SettingsPanel

@export var mat : ShaderMaterial

@export var GlitchButton : Control
@export var FullScreenButton : Control
@export var SoundButton : Control
@export var MusicButton : Control
@export var ShakeEffectButton : Control

static var HasGlitch = true

func _ready() -> void:
	GlitchButton.set_pressed_no_signal(HasGlitch)
	FullScreenButton.set_pressed_no_signal(DisplayServer.window_get_mode(0) == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	SoundButton.set_pressed_no_signal(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sounds")) == 0)
	MusicButton.set_pressed_no_signal(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) == 0)
	ShakeEffectButton.set_pressed_no_signal(ScreenCamera.ShakeEffects)
	
func _on_full_screen_check_box_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)


func _on_sound_check_box_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), 0)
	else:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), -64)

func _on_music_check_box_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), 0)
	else:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), -64)

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


func _on_shake_check_box_toggled(toggled_on: bool) -> void:
	ScreenCamera.ShakeEffects = toggled_on
