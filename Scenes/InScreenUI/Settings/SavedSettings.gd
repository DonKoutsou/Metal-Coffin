extends Resource

class_name Saved_Settings

@export var FullScreen : bool
@export var Sound : float
@export var Music : float
@export var ShakeEffect : bool
@export var Rain : bool
@export var Glitch : bool
@export var GameVersion : float
@export var FPS : int
@export var UI_Color : int

#-----------------------------------------------------------------------------------
static func LoadSavedSettings() -> void:
	if (!FileAccess.file_exists("user://Settings.tres")):
		return
		
	var CurrentVersion = ProjectSettings.get_setting("application/config/version")
	var sav = load("user://Settings.tres") as Saved_Settings
	
	if (sav == null):
		return
	if (sav.GameVersion != str_to_var(CurrentVersion)):
		return
	
	if (sav.FullScreen):
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)

	var master_vca = FmodServer.get_bus_from_guid("{73e88512-3bf1-41c9-b3bf-f65df22cb358}")
	master_vca.set_volume(sav.Sound)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), linear_to_db(sav.Sound))
	MusicManager.Instance.UpdateMusicVolume(sav.Music)

	Engine.max_fps = sav.FPS
	ScreenCamera.ShakeEffects = sav.ShakeEffect
	SettingsPanel.HasRain = sav.Rain

	ColorManager.CurrentColor = sav.UI_Color

#-----------------------------------------------------------------------------------
static func UpdateSavedSettings() -> void:
	var save = Saved_Settings.new()
	save.FullScreen = DisplayServer.window_get_mode(0) == DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	save.Glitch = SettingsPanel.HasGlitch
	save.Rain = SettingsPanel.HasRain
	#save.Sound = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sounds"))
	var master_vca = FmodServer.get_bus_from_guid("{73e88512-3bf1-41c9-b3bf-f65df22cb358}")
	save.Sound =  master_vca.get_volume()
	
	save.Music = MusicManager.Instance.GetMusicVolume()
	save.ShakeEffect = ScreenCamera.ShakeEffects
	save.GameVersion = ProjectSettings.get_setting("application/config/version")
	save.FPS = Engine.max_fps
	save.UI_Color = ColorManager.CurrentColor

	ResourceSaver.save(save, "user://Settings.tres")
