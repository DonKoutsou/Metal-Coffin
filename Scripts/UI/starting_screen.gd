extends Node

class_name StartingScreen

@export var StartingMenuScene : PackedScene
@export var StudioAnim : PackedScene
@export var GameScene : PackedScene
@export var IntroGameScene : PackedScene


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
	UISoundMan.GetInstance().Refresh()

func StartPrologue() -> void:
	Wor = IntroGameScene.instantiate() as World
	add_child(Wor)
	await Wor.WorldSpawnTransitionFinished
	StMenu.queue_free()
	#$ColorRect.visible = false
	#$PanelContainer.visible = false
	Wor.connect("WRLD_OnGameEnded", OnGameEnded)

func StartGame(Load : bool) -> void:
	#TODO enable on full release
	if (!ActionTracker.GetInstance().DidPrologue()):
		var window = AcceptDialog.new()
		add_child(window)
		window.dialog_text = "Prologue needs to be completed before moving to the campaign"
		window.popup_centered()
		return
		
	if (!OS.is_debug_build()):
		var window = AcceptDialog.new()
		add_child(window)
		window.dialog_text = "Not available on Demo"
		window.popup_centered()
		return
		
	
		
	Wor = GameScene.instantiate() as World
	#wor.Load
	if (Load):
		if (!SaveLoadManager.GetInstance().Load(Wor)):
			var window = AcceptDialog.new()
			add_child(window)
			window.dialog_text = "No Save File Found"
			window.popup_centered()
			return
	
	add_child(Wor)
	await Wor.WorldSpawnTransitionFinished
	StMenu.queue_free()
	#$ColorRect.visible = false
	#$PanelContainer.visible = false
	Wor.connect("WRLD_OnGameEnded", OnGameEnded)

func DelSave() -> void:
	var pop = ConfirmationDialog.new()
	pop.dialog_text = "Saves have been nuked"
	get_viewport().add_child(pop)
	pop.popup_centered()
	SaveLoadManager.GetInstance().DeleteSave()
	ActionTracker.GetInstance().DeleteSave()
	

func OnGameEnded() -> void:
	get_tree().paused = false
	Wor.TerminateWorld()
	Wor.queue_free()
	SpawnMenu()
