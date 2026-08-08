extends Node

class_name MissileCommandMain

@export var MainMenuScene : PackedScene
@export var LevelScene : PackedScene
@export var EndlessLevelScene : PackedScene
@export var PauseScene : PackedScene

var Menu : MainMenu
var PMenu : PauseMenu
var CurrentLevel : Level
var CurrentEndlessLevel : EndlessLevel

signal Finished

func _ready() -> void:
	SpawnMenu()

func SpawnMenu() -> void:
	Menu = MainMenuScene.instantiate()
	$PanelContainer/SubViewportContainer/SubViewport.add_child(Menu)
	Menu.ExitPressed.connect(ExitPressed)
	Menu.LevelStarted.connect(LevelSelected)
	
func LevelSelected(LevelNumber : int) -> void:
	Menu.queue_free()
	if (LevelNumber == -1):
		CurrentEndlessLevel = EndlessLevelScene.instantiate()
		CurrentEndlessLevel.LevelFinished.connect(EndlessLevelFinished)
		$PanelContainer/SubViewportContainer/SubViewport.add_child(CurrentEndlessLevel)
	else:
		CurrentLevel = LevelScene.instantiate()
		CurrentLevel.LevelFinished.connect(LevelFinished)
		CurrentLevel.SetDificulty(LevelNumber)
		$PanelContainer/SubViewportContainer/SubViewport.add_child(CurrentLevel)

func LevelFinished() -> void:
	CurrentLevel.queue_free()
	SpawnMenu()

func EndlessLevelFinished() -> void:
	CurrentEndlessLevel.queue_free()
	SpawnMenu()

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Pause")):
		#if menu exists we dont need to pause
		if (is_instance_valid(Menu)):
			return
		
		if (is_instance_valid(PMenu)):
			UnpausePressed()
			return
		
		PMenu = PauseScene.instantiate()
		$PanelContainer/SubViewportContainer/SubViewport.add_child(PMenu)
		PMenu.ContinuePressed.connect(UnpausePressed)
		PMenu.ExitPressed.connect(ExitPressed)
		PMenu.ExitToMenuPressed.connect(ExitToMenuPressed)
		get_tree().paused = true

func UnpausePressed() -> void:
	get_tree().paused = false
	PMenu.queue_free()

func ExitPressed() -> void:
	get_tree().paused = false
	Finished.emit()
	queue_free()

func ExitToMenuPressed() -> void:
	get_tree().paused = false
	PMenu.queue_free()
	if (is_instance_valid(CurrentLevel)):
		LevelFinished()
	
	if (is_instance_valid(CurrentEndlessLevel)):
		EndlessLevelFinished()
