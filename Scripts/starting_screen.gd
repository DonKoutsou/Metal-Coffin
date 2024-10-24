extends Node

class_name StartingScreen

@export var StartingMenuScene : PackedScene
@export var GameScene : PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SpawnMenu()

func SpawnMenu() -> void:
	var startmen = StartingMenuScene.instantiate() as StartingMenu
	add_child(startmen)
	startmen.connect("GameStart", StartGame)
	
func StartGame() -> void:
	get_child(1).queue_free()
	var wor = GameScene.instantiate() as World
	add_child(wor)
	#$ColorRect.visible = false
	#$PanelContainer.visible = false
	wor.connect("OnGameEnded", OnGameEnded)

func OnGameEnded() -> void:
	get_tree().paused = false
	get_child(1).queue_free()
	SpawnMenu()
