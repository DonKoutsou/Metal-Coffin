extends Node

class_name StartingScreen

@export var StartingMenuScene : PackedScene
@export var StudioAnim : PackedScene
@export var GameScene : PackedScene
@export var IntroGameScene : PackedScene
@export var CageFightGameScene : PackedScene

var StMenu : StartingMenu
var Wor : World


const APPID = "3679120"
 #Called when the node enters the scene tree for the first time.

#func _init() -> void:
	#if (OS.get_name() == "Windows"):
		#OS.set_environment("SteamAppID", APPID)
		#OS.set_environment("SteamGameID", APPID)
	
func _ready() -> void:
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
	
	var vidpl = StudioAnim.instantiate() as StudioAnimation
	add_child(vidpl)
	await vidpl.Finished
	vidpl.queue_free()

	SpawnMenu()

func SpawnMenu() -> void:
	StMenu = StartingMenuScene.instantiate() as StartingMenu
	add_child(StMenu)
	StMenu.connect("GameStart", StartGame)
	StMenu.connect("PrologueStart", StartPrologue)
	StMenu.connect("DelSave", DelSave)
	StMenu.FightStart.connect(StartCageFight)
	UISoundMan.GetInstance().Refresh()

func StartPrologue(Load : bool, SkipStory : bool = false) -> void:
	
	Wor = IntroGameScene.instantiate() as World
	if (Load):
		var LoadResault = SaveLoadManager.GetInstance().Load(Wor)
		if (!LoadResault["Succsess"]):
			PopupManager.DoFadeNotif(LoadResault["Reason"], StMenu.GetVp())
			return
	
	add_child(Wor)
	Wor.SkipStory = SkipStory
	await Wor.WorldSpawnTransitionFinished
	StMenu.queue_free()
	#$ColorRect.visible = false
	#$PanelContainer.visible = false
	Wor.connect("WRLD_OnGameEnded", OnGameEnded)

func StartCageFight() -> void:
	
	var fight = CageFightGameScene.instantiate() as CageFightWorld

	add_child(fight)
	await fight.FightTransitionFinished
	StMenu.queue_free()
	#$ColorRect.visible = false
	#$PanelContainer.visible = false
	fight.FightEnded.connect(FightEnded.bind(fight))

func StartGame(Load : bool, SkipStory : bool = false) -> void:
	#TODO enable on full release
	if (!ActionTracker.GetInstance().DidPrologue()):
		PopupManager.DoFadeNotif("Prologue needs to be completed before moving to the campaign", StMenu.GetVp())
		return
		
	if (!OS.is_debug_build()):
		PopupManager.DoFadeNotif("Not available on Demo", StMenu.GetVp())
		return

	Wor = GameScene.instantiate() as World

	if (Load):
		var LoadResault = SaveLoadManager.GetInstance().Load(Wor)
		if (!LoadResault["Succsess"]):
			PopupManager.DoFadeNotif(LoadResault["Reason"], StMenu.GetVp())
			return
	
	add_child(Wor)
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
