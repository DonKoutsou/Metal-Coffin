extends PanelContainer

class_name SettingsPanel

@export var mat : ShaderMaterial

@export var GlitchButton : Control
@export var FullScreenButton : Control
@export var SoundSlider : HSlider
@export var MusicSlider : HSlider
@export var ShakeEffectButton : Control
@export var RainButton : BaseButton
@export var FPSSlider : HSlider
@export var FPSLabel : Label

static var HasRain = true
static var HasGlitch = true

func _ready() -> void:
	GlitchButton.set_pressed_no_signal(HasGlitch)
	RainButton.set_pressed_no_signal(HasRain)
	FullScreenButton.set_pressed_no_signal(DisplayServer.window_get_mode(0) == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	SoundSlider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sounds"))))
	MusicSlider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))))
	ShakeEffectButton.set_pressed_no_signal(ScreenCamera.ShakeEffects)
	FPSSlider.value = roundi(Engine.max_fps)
	FPSLabel.text = var_to_str(roundi(Engine.max_fps))
	
	
#-------------------------------------------------------------------
##FULLSCREEN
func _on_full_screen_check_box_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)

#-------------------------------------------------------------------
##GLITCH
static func GetGlitch() -> bool:
	return HasGlitch

func _on_glitches_check_box_toggled(toggled_on: bool) -> void:
	HasGlitch = toggled_on
	ToggleScreenGlitches(toggled_on)

func ToggleScreenGlitches(t : bool) -> void:
	var ImageFlicker = 0
	var Skip = 0
	if (t):
		ImageFlicker = 0.05
		Skip = 0.01
		
	mat.set_shader_parameter("image_flicker", ImageFlicker)
	mat.set_shader_parameter("skip", Skip)

#-------------------------------------------------------------------
##Shake
func _on_shake_check_box_toggled(toggled_on: bool) -> void:
	ScreenCamera.ShakeEffects = toggled_on

#-------------------------------------------------------------------
##Rain
static func GetRain() -> bool:
	return HasRain

func _on_rain_check_box_toggled(toggled_on: bool) -> void:
	HasRain = toggled_on
	if (RainEffect.Instance != null):
		RainEffect.Instance.ToggleEffects(toggled_on)

#-------------------------------------------------------------------
##SOUND
func _on_sound_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), linear_to_db(value))
	
#-------------------------------------------------------------------
##MUSIC
func _on_music_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))


func _on_fps_value_changed(value: float) -> void:
	Engine.max_fps = value
	$VBoxContainer/GridContainer/HBoxContainer/Label.text = var_to_str(roundi(value))
