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
@export var colorsSlider : HSlider
@export var resolutionOptions : Text_Spin_Box

static var HasRain = true
static var HasGlitch = true

var resolutions: Array[Vector2i] = [
	# 16:9
	Vector2i(854, 480),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

var availableResolutions: Array[Vector2i] = []


func _ready() -> void:
	GlitchButton.set_pressed_no_signal(HasGlitch)
	RainButton.set_pressed_no_signal(HasRain)
	FullScreenButton.set_pressed_no_signal(DisplayServer.window_get_mode(0) == DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	var master_vca = FmodServer.get_bus_from_guid("{73e88512-3bf1-41c9-b3bf-f65df22cb358}")
	SoundSlider.set_value_no_signal(master_vca.get_volume())
	
	MusicSlider.set_value_no_signal(MusicManager.Instance.GetMusicVolume())
	ShakeEffectButton.set_pressed_no_signal(ScreenCamera.ShakeEffects)
	FPSSlider.value = roundi(Engine.max_fps)
	FPSLabel.text = var_to_str(roundi(Engine.max_fps))
	
	colorsSlider.max_value = ColorManager.COLORS.size() - 1
	colorsSlider.set_value_no_signal(ColorManager.CurrentColor)
	
	var max_resolution: Vector2i = DisplayServer.screen_get_size()
	var current_size: Vector2i = DisplayServer.window_get_size()
	for res in resolutions:
		if (res.x <= max_resolution.x and res.y <= max_resolution.y):
			availableResolutions.append(res)
			resolutionOptions.AddOption("{0} x {1}".format([res.x, res.y]))
			if (res == current_size):
				resolutionOptions.SetSelected(availableResolutions.size() - 1)

func _on_resolution_option_picked(index: int) -> void:
	DisplayServer.window_set_size(availableResolutions[index])
	get_tree().root.size = availableResolutions[index]
	#StartingScreen.mainSubviewPort.size = availableResolutions[index]
	
#-------------------------------------------------------------------
##FULLSCREEN
func _on_full_screen_check_box_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
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
	var master_vca = FmodServer.get_bus_from_guid("{73e88512-3bf1-41c9-b3bf-f65df22cb358}")
	master_vca.set_volume(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), linear_to_db(value))
	
#-------------------------------------------------------------------
##MUSIC
func _on_music_value_changed(value: float) -> void:
	MusicManager.Instance.UpdateMusicVolume(value)
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))


func _on_fps_value_changed(value: float) -> void:
	Engine.max_fps = value
	$VBoxContainer/GridContainer/HBoxContainer/Label.text = var_to_str(roundi(value))


func _on_h_slider_value_changed(value: float) -> void:
	ColorManager.CurrentColor = roundi(value)
