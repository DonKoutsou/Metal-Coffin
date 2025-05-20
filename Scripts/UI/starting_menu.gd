extends CanvasLayer

class_name StartingMenu

@export var Black : ColorRect
@export var CreditsScene : PackedScene
@export var LoadPrologueLight : Light
@export var LoadLight : Light
@export var HintDialogue : Control
@export var Credits : Control
@export var NormalUI : Control

var SpawnedCredits : Control

var Selecting : bool


signal GameStart(Load : bool)
signal PrologueStart(Load : bool)
signal FightStart()
signal DelSave

signal ShowTutorial(T : bool)

func _ready() -> void:
	HintDialogue.visible = false
	Credits.visible = false
	
	Black.color = Color(0,0,0,1)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property(Black, "color", Color(0,0,0,0), 2)
	
	LoadPrologueLight.ToggleNoAnim(true, FileAccess.file_exists("user://PrologueSavedGame.tres"))
	LoadLight.ToggleNoAnim(true, FileAccess.file_exists("user://SavedGame.tres"))
	
	
	#LoopAmp()

func _on_play_pressed() -> void:
	if (Selecting):
		return
		
	await ChooseTutorial()
	GameStart.emit(false)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_load_pressed() -> void:
	if (Selecting):
		return
		
	await ChooseTutorial()
	GameStart.emit(true)


func On_Credits_Pressed() -> void:
	if (Selecting):
		return
	
	var t = !Credits.visible
	Credits.visible = t
	NormalUI.visible = !t

func _on_credits_on_button_pressed() -> void:
	Credits.visible = false
	NormalUI.visible = true

#func LoopAmp() -> void:
	#var Tw = create_tween()
	#Tw.set_trans(Tween.TRANS_BOUNCE)
	#Tw.tween_property($w/LineDrawer, "amplitude", randf_range(-80, 80), 0.2)
	#await Tw.finished
	#call_deferred("LoopAmp")


func _on_prologue_pressed() -> void:
	if (Selecting):
		return
		
	await ChooseTutorial()
	PrologueStart.emit(false)
	

func _on_button_pressed() -> void:
	if (Selecting):
		return
		
	DelSave.emit()
	LoadPrologueLight.ToggleNoAnim(true, false)
	LoadLight.ToggleNoAnim(true, false)


func _on_load_prologue_pressed() -> void:
	if (Selecting):
		return
		
	await ChooseTutorial()
	ActionTracker.GetInstance().Load()
	PrologueStart.emit(true)

func ChooseTutorial() -> void:
	var c = get_tree().get_nodes_in_group("Credits")
	if (c.size() > 0):
		c[0].queue_free()
		
	HintDialogue.visible = true
	var t = await ShowTutorial
	
	ActionTracker.ShowTutorials = t
	ActionTracker.GetInstance().CompletedActions.clear()
	#if (t):
		#ActionTracker.GetInstance().DeleteSave()
	
	HintDialogue.visible = false

func GetVp() -> Control:
	return $SubViewportContainer/SubViewport

func _on_dont_show_tutorial_pressed() -> void:
	ShowTutorial.emit(false)


func _on_show_tutorial_pressed() -> void:
	ShowTutorial.emit(true)


func _on_fight_pressed() -> void:
	if (Selecting):
		return
	await ChooseTutorial()
	FightStart.emit()
	
