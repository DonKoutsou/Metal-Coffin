extends Node

class_name StartingScreen
@onready var save_load_manager: SaveLoadManager = $SaveLoadManager

@export var StartingMenuScene : PackedScene
@export var GameScene : PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	get_child(3).queue_free()
	add_child(wor)
	#$ColorRect.visible = false
	#$PanelContainer.visible = false
	wor.connect("OnGameEnded", OnGameEnded)

func OnGameEnded() -> void:
	get_tree().paused = false
	get_child(3).queue_free()
	SpawnMenu()
