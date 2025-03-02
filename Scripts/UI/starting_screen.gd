extends Node

class_name StartingScreen
@onready var save_load_manager: SaveLoadManager = $SaveLoadManager

@export var StartingMenuScene : PackedScene
@export var StudioAnim : PackedScene
@export var GameScene : PackedScene

const APPID = "3551150"
# Called when the node enters the scene tree for the first time.

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
			#$AchievementManager.SteamRunning = true
			#print("Achievement Tracking Enabled")
	
	var vidpl = StudioAnim.instantiate() as StudioAnim
	add_child(vidpl)
	await vidpl.Finished
	vidpl.queue_free()

	SpawnMenu()

func SpawnMenu() -> void:
	var startmen = StartingMenuScene.instantiate() as StartingMenu
	add_child(startmen)
	startmen.connect("GameStart", StartGame)
	UISoundMan.GetInstance().Refresh()
	
func StartGame(Load : bool) -> void:
	var wor = GameScene.instantiate() as World
	#wor.Load
	if (Load):
		if (!save_load_manager.Load(wor)):
			var window = AcceptDialog.new()
			add_child(window)
			window.dialog_text = "No Save File Found"
			window.popup_centered()
			return
	
	get_child(5).queue_free()
	add_child(wor)
	#$ColorRect.visible = false
	#$PanelContainer.visible = false
	wor.connect("WRLD_OnGameEnded", OnGameEnded)

	

func OnGameEnded() -> void:
	get_tree().paused = false
	get_child(5).TerminateWorld()
	get_child(5).queue_free()
	SpawnMenu()
