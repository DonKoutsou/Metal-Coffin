extends CanvasLayer

class_name StartingMenu

@export var CreditsScene : PackedScene

var SpawnedCredits : Control

signal GameStart(Load : bool)
signal PrologueStart(Load : bool)
signal DelSave

signal ShowTutorial(T : bool)

func _ready() -> void:
	$Control.visible = false
	
	$ColorRect.color = Color(0,0,0,1)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property($ColorRect, "color", Color(0,0,0,0), 2)
	
	$PanelContainer/VBoxContainer/HBoxContainer3/LoadPrologue.visible = FileAccess.file_exists("user://PrologueSavedGame.tres")
	$PanelContainer/VBoxContainer/HBoxContainer/Load.visible = FileAccess.file_exists("user://SavedGame.tres")
		
	
	#LoopAmp()

func _on_play_pressed() -> void:
	await ChooseTutorial()
	GameStart.emit(false)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_load_pressed() -> void:
	await ChooseTutorial()
	GameStart.emit(true)


func On_Credits_Pressed() -> void:
	SpawnedCredits = CreditsScene.instantiate()
	$CanvasLayer.add_child(SpawnedCredits)


#func LoopAmp() -> void:
	#var Tw = create_tween()
	#Tw.set_trans(Tween.TRANS_BOUNCE)
	#Tw.tween_property($w/LineDrawer, "amplitude", randf_range(-80, 80), 0.2)
	#await Tw.finished
	#call_deferred("LoopAmp")


func _on_prologue_pressed() -> void:
	await ChooseTutorial()
	PrologueStart.emit(false)
	

func _on_button_pressed() -> void:
	DelSave.emit()
	$PanelContainer/VBoxContainer/HBoxContainer3/LoadPrologue.visible = false
	$PanelContainer/VBoxContainer/HBoxContainer/Load.visible = false


func _on_load_prologue_pressed() -> void:
	await ChooseTutorial()
	PrologueStart.emit(true)

func ChooseTutorial() -> bool:
	$Control.visible = true
	var t = await ShowTutorial
	
	ActionTracker.ShowTutorials = t
	if (t):
		ActionTracker.GetInstance().DeleteSave()
	
	$Control.visible = false
	return t

func _on_dont_show_tutorial_pressed() -> void:
	ShowTutorial.emit(false)


func _on_show_tutorial_pressed() -> void:
	ShowTutorial.emit(true)
