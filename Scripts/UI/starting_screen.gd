extends Node

class_name StartingScreen

@export var StartingMenuScene : String = "res://Scenes/starting_menu.tscn"
@export var DitherShader : ShaderMaterial
@export_file("*.tscn") var StudioAnim : String
@export var GameScene : String = "res://Scenes/World.tscn"
@export var IntroGameScene : String = "res://Scenes/IntroWorld.tscn"
@export var CageFightGameScene : String = "res://Scenes/CageFightWorld.tscn"

var StMenu : StartingMenu
var Wor : World

const APPID = "3679120"
 #Called when the node enters the scene tree for the first time.

#func _init() -> void:
	#if (OS.get_name() == "Windows"):
		#OS.set_environment("SteamAppID", APPID)
		#OS.set_environment("SteamGameID", APPID)


func _ready() -> void:
	var siz =  DisplayServer.screen_get_size()
	siz.x = min(siz.x, 1920)
	siz.y = min(siz.y, 1080)
	DitherShader.set_shader_parameter("ScreenSize",siz)
	print("Screen Size = {0}".format([siz]))
	#if (OS.get_name() == "Windows"):
		#Steam.steamInit()
		#var IsRunning = Steam.isSteamRunning()
		#
		#if (!IsRunning):
			#printerr("Steam Is Not Running")
		#else:
			#print("Steam Is Running")
			#var ID = Steam.getSteamID()
			#var name = Steam.getFriendPersonaName(ID)
			#print("Username : ", str(name))
			#AchievementManager.GetInstance().SteamRunning = true
			#print("Achievement Tracking Enabled")
	call_deferred("Start")

func Start() -> void:
	var StudioAnimScene = ResourceLoader.load(StudioAnim)
	var vidpl = StudioAnimScene.instantiate() as StudioAnimation
	$SubViewportContainer/SubViewport.add_child(vidpl)
	
	await vidpl.Finished
	
	vidpl.queue_free()
	SpawnMenu()

func SpawnMenu() -> void:
	var Menu = await Helper.GetInstance().LoadThreaded(StartingMenuScene).Sign
	StMenu = Menu.instantiate() as StartingMenu
	$SubViewportContainer/SubViewport.add_child(StMenu)
	StMenu.connect("GameStart", StartGame)
	StMenu.connect("PrologueStart", StartPrologue)
	StMenu.connect("DelSave", DelSave)
	StMenu.FightStart.connect(StartCageFight)
	UISoundMan.GetInstance().Refresh()

func StartPrologue(Load : bool, SkipStory : bool = false) -> void:
	var IntroScene = await Helper.GetInstance().LoadThreaded(IntroGameScene).Sign
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

func StartCageFight() -> void:
	var FightScene = await Helper.GetInstance().LoadThreaded(CageFightGameScene).Sign
	var fight = FightScene.instantiate() as CageFightWorld

	$SubViewportContainer/SubViewport.add_child(fight)
	await fight.FightTransitionFinished
	StMenu.queue_free()
	#$ColorRect.visible = false
	#$PanelContainer.visible = false
	fight.FightEnded.connect(FightEnded.bind(fight))

func StartGame(Load : bool, _SkipStory : bool = false) -> void:
	#TODO enable on full release
	if (!ActionTracker.GetInstance().DidPrologue()):
		PopupManager.DoFadeNotif("Prologue needs to be completed before moving to the campaign", StMenu.GetVp())
		return
		
	if (!OS.is_debug_build()):
		PopupManager.DoFadeNotif("Not available on Demo", StMenu.GetVp())
		return
	
	var WorldScene = await Helper.GetInstance().LoadThreaded(GameScene).Sign
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
	Wor.connect("WRLD_OnGameEnded", OnGameEnded)

func DelSave() -> void:
	
	PopUpManager.GetInstance().DoFadeNotif("Saves have been nuked", StMenu.GetVp())
	
	SaveLoadManager.GetInstance().DeleteSave()
	#ActionTracker.GetInstance().DeleteSave()
	
func FightEnded(Fight : CageFightWorld) -> void:
	get_tree().paused = false
	Fight.queue_free()
	SpawnMenu()

func OnGameEnded() -> void:
	get_tree().paused = false
	Wor.TerminateWorld()
	Wor.queue_free()
	SpawnMenu()
