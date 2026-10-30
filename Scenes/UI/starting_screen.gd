extends Node

class_name StartingScreen

@export var StartingMenuScene : String = "res://Scenes/starting_menu.tscn"
@export var DitherShader : ShaderMaterial
@export_file("*.tscn") var scenesToShow : Array[String]
@export_file("*.tscn") var StudioAnim : String
@export_file("*.tscn") var GameScene : String = "res://Scenes/World.tscn"
@export_file("*.tscn") var IntroGameScene : String = "res://Scenes/IntroWorld.tscn"
@export_file("*.tscn") var CageFightGameScene : String = "res://Scenes/CageFightWorld.tscn"

var StMenu : StartingMenu
var Wor : World

const MAIN_APP_ID = "3551150"
const PLAYTEST_APP_ID = "3679430"
const DEMO_APP_ID = "3679120"

const APPID = DEMO_APP_ID

static var mainSubviewPort : SubViewport

 #Called when the node enters the scene tree for the first time.
#-----------------------------------------------------------------------------------

static func GetModLoc() -> String:
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/My Games/MetalCoffin/Mods"

func _init() -> void:
	if (OS.get_name() == "Windows"):
		OS.set_environment("SteamAppID", APPID)
		OS.set_environment("SteamGameID", APPID)

const DIR_ERROR = 'ERROR: Failed to create directory "%s". Error code %s.'

# This is only needed for potential solution 1.
func try_to_create_dir(path):
	if not DirAccess.dir_exists_absolute(path):
		var error_code = DirAccess.make_dir_absolute(path)
		if error_code != OK:
			printerr(DIR_ERROR % [path, error_code])
		else:
			"Mods Directory Created"
	else:
		print("Mods Directory Found")

#-----------------------------------------------------------------------------------
func _ready() -> void:
	mainSubviewPort = $SubViewportContainer/SubViewport
	var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	
	var dir : DirAccess = DirAccess.open(documents_path)
	if dir:
		#print("Successfully accessed Documents folder!")
		if (dir.dir_exists("My Games")):
			dir = DirAccess.open(documents_path + "/My Games")
		else:
			dir.make_dir("My Games")
			dir = DirAccess.open(documents_path + "/My Games")
		
		if (dir.dir_exists("MetalCoffin")):
			dir = DirAccess.open(documents_path +"/My Games" + "/MetalCoffin")
		else:
			dir.make_dir("MetalCoffin")
			dir = DirAccess.open(documents_path + "/My Games" + "/MetalCoffin")
		
		#Create Save directory
		if (!dir.dir_exists("Save")):
			dir.make_dir("Save")
		
		#Create Mod Directory
		if (!dir.dir_exists("Mods")):
			dir.make_dir("Mods")
			
	else:
		print("Failed to access path. Check permissions.")
	
	var modDir : DirAccess = DirAccess.open(GetModLoc())
	modDir.list_dir_begin()
	var file_name = modDir.get_next()
	while file_name != "":
		var l = ProjectSettings.load_resource_pack(GetModLoc() + "/" + file_name)
		if (l):
			CommandLine.AddText("Loaded mod: {0}".format([file_name.get_file()]))
		else:
			CommandLine.AddErr("Failed to load mod: {0}".format([file_name.get_file()]))
		
		file_name = modDir.get_next()
		
	if (OS.get_name() == "Windows"):
		Steam.steamInit()
		var IsRunning = Steam.isSteamRunning()
		
		if (!IsRunning):
			CommandLine.AddErr("Steam Is Not Running")
		else:
			CommandLine.AddText("Steam Is Running")
			var ID = Steam.getSteamID()
			var n = Steam.getFriendPersonaName(ID)
			CommandLine.AddText("Username : " + str(n))
			AchievementManager.GetInstance().SteamRunning = true
			CommandLine.AddText("Achievement Tracking Enabled")
			
			load_all_workshop_mods()
			CommandLine.AddText("Loaded Workshop Mods")

	Saved_Settings.LoadSavedSettings()
	get_viewport().disable_3d = true
	TranslationServer.set_locale("english")
	
	await Start()

func load_all_workshop_mods() -> void:
	var subscribed_ids = Steam.getSubscribedItems()

	for mod_id in subscribed_ids:
		var info: Dictionary = Steam.getItemInstallInfo(mod_id)

		# Skip mods that aren't installed yet.
		if not info.get("ret", false):
			continue

		var mod_dir: String = info.get("folder", "")
		if mod_dir.is_empty():
			continue

		# Find PCK files in this mod's folder.
		var dir := DirAccess.open(mod_dir)
		if dir == null:
			continue

		dir.list_dir_begin()
		var file_name := dir.get_next()

		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".pck"):
				var pck_path := mod_dir.path_join(file_name)

				if ProjectSettings.load_resource_pack(pck_path):
					CommandLine.AddText("Loaded mod: {0}".format([file_name]))
				else:
					CommandLine.AddErr("Failed to load mod: {0}".format([pck_path]))

			file_name = dir.get_next()

		dir.list_dir_end()

#-----------------------------------------------------------------------------------
func Start() -> void:

	for g in scenesToShow:
		var sc : PackedScene = load(g)
		var introScene : IntroScene = sc.instantiate()
		$SubViewportContainer/SubViewport.add_child(introScene)
		await introScene.Finished

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
	
	var wScene = await Helper.LoadThreaded(IntroGameScene).Sign
	Wor = wScene.instantiate() as World
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
	Saved_Settings.UpdateSavedSettings()
