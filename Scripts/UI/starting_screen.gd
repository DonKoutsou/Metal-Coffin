extends Node

class_name StartingScreen

@export var StartingMenuScene : String = "res://Scenes/starting_menu.tscn"
@export var DitherShader : ShaderMaterial
@export_file("*.tscn") var StudioAnim : String
@export_file("*.tscn") var WarningScene : String
@export_file("*.tscn") var GameScene : String = "res://Scenes/World.tscn"
@export_file("*.tscn") var IntroGameScene : String = "res://Scenes/IntroWorld.tscn"
@export_file("*.tscn") var CageFightGameScene : String = "res://Scenes/CageFightWorld.tscn"

var StMenu : StartingMenu
var Wor : World

const APPID = "3679120"

 #Called when the node enters the scene tree for the first time.
#-----------------------------------------------------------------------------------
func _init() -> void:
	if (OS.get_name() == "Windows"):
		OS.set_environment("SteamAppID", APPID)
		OS.set_environment("SteamGameID", APPID)

#-----------------------------------------------------------------------------------
func _ready() -> void:
	LoadSavedSettings()
	#get_viewport().disable_3d = true
	TranslationServer.set_locale("english")
	#var siz =  DisplayServer.screen_get_size()
	#siz.x = min(siz.x, 1920)
	#siz.y = min(siz.y, 1080)
	#DitherShader.set_shader_parameter("ScreenSize",siz)
	#print("Screen Size = {0}".format([siz]))
	if (OS.get_name() == "Windows"):
		Steam.steamInit()
		var IsRunning = Steam.isSteamRunning()
		
		if (!IsRunning):
			printerr("Steam Is Not Running")
		else:
			print("Steam Is Running")
			var ID = Steam.getSteamID()
			var n = Steam.getFriendPersonaName(ID)
			print("Username : ", str(n))
			AchievementManager.GetInstance().SteamRunning = true
			print("Achievement Tracking Enabled")
			
	await Start()

#-----------------------------------------------------------------------------------
func Start() -> void:
	var warning : PackedScene = ResourceLoader.load(WarningScene)
	var warningsc : Control = warning.instantiate()
	warningsc.modulate.a = 0
	$SubViewportContainer/SubViewport.add_child(warningsc)
	
	var tw = create_tween()
	tw.tween_property(warningsc, "modulate", Color(1,1,1,1), 1)
	
	await get_tree().create_timer(3).timeout
	warningsc.queue_free()
	
	var StudioAnimScene = ResourceLoader.load(StudioAnim)
	var vidpl = StudioAnimScene.instantiate() as StudioAnimation
	$SubViewportContainer/SubViewport.add_child(vidpl)
	
	await vidpl.Finished
	
	vidpl.queue_free()
	await SpawnMenu()

#-----------------------------------------------------------------------------------
func SpawnMenu() -> void:
	var Menu = await Helper.LoadThreaded(StartingMenuScene).Sign
	StMenu = Menu.instantiate() as StartingMenu
	$SubViewportContainer/SubViewport.add_child(StMenu)
	StMenu.connect("GameStart", StartGame)
	StMenu.connect("PrologueStart", StartPrologue)
	StMenu.connect("DelSave", DelSave)
	StMenu.FightStart.connect(StartCageFight)
	UISoundMan.GetInstance().Refresh()

#-----------------------------------------------------------------------------------
func StartPrologue(Load : bool, SkipStory : bool = false, customSeed : int = -1) -> void:
	if (customSeed == -1):
		Rand.customSeed = randi()
	else:
		Rand.customSeed = customSeed
	
	var IntroScene = await Helper.LoadThreaded(IntroGameScene).Sign
	Wor = IntroScene.instantiate() as World
	if (Load):
		var LoadResault = SaveLoadManager.GetInstance().Load(Wor)
		if (!LoadResault["Succsess"]):
			PopupManager.DoFadeNotif(LoadResault["Reason"], StMenu.GetVp())
			return
	
	$SubViewportContainer/SubViewport.add_child(Wor)
	Wor.SkipStory = SkipStory
	
	await Wor.WorldSpawnTransitionFinished
	StMenu.queue_free()
	#$ColorRect.visible = false
	#$PanelContainer.visible = false
	Wor.connect("WRLD_OnGameEnded", OnGameEnded)

#-----------------------------------------------------------------------------------
func StartCageFight() -> void:
	var FightScene = await Helper.LoadThreaded(CageFightGameScene).Sign
	var fight = FightScene.instantiate() as CageFightWorld

	$SubViewportContainer/SubViewport.add_child(fight)
	await fight.FightTransitionFinished
	StMenu.queue_free()
	#$ColorRect.visible = false
	#$PanelContainer.visible = false
	fight.FightEnded.connect(FightEnded.bind(fight))

#-----------------------------------------------------------------------------------
func StartGame(Load : bool, _SkipStory : bool = false) -> void:
	#TODO enable on full release
	if (!ActionTracker.GetInstance().DidPrologue()):
		PopupManager.DoFadeNotif("Prologue needs to be completed before moving to the campaign", StMenu.GetVp())
		return
		
	if (!OS.is_debug_build()):
		PopupManager.DoFadeNotif("Not available on Demo", StMenu.GetVp())
		return
	
	var WorldScene = await Helper.LoadThreaded(GameScene).Sign
	Wor = WorldScene.instantiate() as World

	if (Load):
		var LoadResault = SaveLoadManager.GetInstance().Load(Wor)
		if (!LoadResault["Succsess"]):
			PopupManager.DoFadeNotif(LoadResault["Reason"], StMenu.GetVp())
			return
	
	$SubViewportContainer/SubViewport.add_child(Wor)
	await Wor.WorldSpawnTransitionFinished
	StMenu.queue_free()
	#$ColorRect.visible = false
	#$PanelContainer.visible = false
	Wor.WRLD_OnGameEnded.connect(OnGameEnded)

#-----------------------------------------------------------------------------------
func DelSave() -> void:
	PopUpManager.GetInstance().DoFadeNotif("Saves have been nuked", StMenu.GetVp())
	SaveLoadManager.GetInstance().DeleteSave()
	#ActionTracker.GetInstance().DeleteSave()

#-----------------------------------------------------------------------------------
func FightEnded(Fight : CageFightWorld) -> void:
	get_tree().paused = false
	Fight.queue_free()
	await SpawnMenu()

#-----------------------------------------------------------------------------------
func OnGameEnded() -> void:
	get_tree().paused = false
	Wor.TerminateWorld()
	Wor.queue_free()
	await SpawnMenu()

#-----------------------------------------------------------------------------------
func _exit_tree() -> void:
	UpdateSavedSettings()

#-----------------------------------------------------------------------------------
func LoadSavedSettings() -> void:
	if (!FileAccess.file_exists("user://Settings.tres")):
		return
		
	var CurrentVersion = ProjectSettings.get_setting("application/config/version")
	var sav = load("user://Settings.tres") as Saved_Settings
	
	if (sav == null):
		return
	if (sav.GameVersion != str_to_var(CurrentVersion)):
		return
	
	if (sav.FullScreen):
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sounds"), sav.Sound)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), sav.Music)
	Engine.max_fps = sav.FPS
	ScreenCamera.ShakeEffects = sav.ShakeEffect
	SettingsPanel.HasRain = sav.Rain

#-----------------------------------------------------------------------------------
func UpdateSavedSettings() -> void:
	var save = Saved_Settings.new()
	save.FullScreen = DisplayServer.window_get_mode(0) == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN
	save.Glitch = SettingsPanel.HasGlitch
	save.Rain = SettingsPanel.HasRain
	save.Sound = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sounds"))
	save.Music = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	save.ShakeEffect = ScreenCamera.ShakeEffects
	save.GameVersion = ProjectSettings.get_setting("application/config/version")
	save.FPS = Engine.max_fps
	ResourceSaver.save(save, "user://Settings.tres")
