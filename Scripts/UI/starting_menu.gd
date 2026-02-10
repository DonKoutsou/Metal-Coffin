extends CanvasLayer

class_name StartingMenu

@export var Black : ColorRect
@export var CreditsScene : PackedScene
@export var LoadPrologueLight : Light
@export var LoadLight : Light
@export var HintDialogue : Control
@export var Credits : Control
@export var NormalUI : Control
@export var VersionLabel : Label

var SpawnedCredits : Control

var Selecting : bool


signal GameStart(Load : bool, SkipStory : bool)
signal PrologueStart(Load : bool, SkipStory : bool)
signal FightStart()
signal DelSave

signal ShowTutorial(i : int)

func _ready() -> void:
	HintDialogue.visible = false
	Credits.visible = false
	
	#Black.color = Color(0,0,0,1)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property(Black, "color", Color(0,0,0,0), 2)
	
	call_deferred("DoLights")
	
	VersionLabel.text = "Demo Version v{0}".format([ProjectSettings.get_setting("application/config/version")])
	#LoopAmp()

var CloudOffset = Vector2.ZERO
func _physics_process(_delta: float) -> void:
	var cloudmat = $SubViewportContainer/SubViewport/Clouds.material as ShaderMaterial
	CloudOffset += Vector2(-0.0001, 0.0001)
	cloudmat.set_shader_parameter("Offset", CloudOffset)

func DoLights() -> void:
	LoadPrologueLight.ToggleNoAnim(true, SaveLoadManager.SaveExists("user://PrologueSavedGame.tres"))
	
	LoadLight.ToggleNoAnim(true, SaveLoadManager.SaveExists("user://SavedGame.tres"))

func _on_play_pressed() -> void:
	if (Selecting):
		return
		
	var Run = await ChooseTutorial()
	if (!Run):
		return
	GameStart.emit(false)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_load_pressed() -> void:
	if (Selecting):
		return
		
	var Run = await ChooseTutorial()
	if (!Run):
		return
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
		
	var Run = await ChooseTutorial()
	if (!Run):
		return
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
		
	var Run = await ChooseTutorial()
	if (!Run):
		return
	ActionTracker.GetInstance().Load()
	PrologueStart.emit(true)

func ChooseTutorial() -> bool:
	var c = get_tree().get_nodes_in_group("Credits")
	if (c.size() > 0):
		c[0].queue_free()
	
	Selecting = true
	HintDialogue.visible = true
	var t = await ShowTutorial
	
	Selecting = false
	HintDialogue.visible = false
	if (t == 2):
		return false
	ActionTracker.ShowTutorials = t == 1
	ActionTracker.GetInstance().CompletedActions.clear()
	
	
	
	
	return true

func GetVp() -> Control:
	return $SubViewportContainer/SubViewport

func _on_dont_show_tutorial_pressed() -> void:
	ShowTutorial.emit(0)


func _on_show_tutorial_pressed() -> void:
	ShowTutorial.emit(1)


func _on_fight_pressed() -> void:
	if (Selecting):
		return
	var Run = await ChooseTutorial()
	if (!Run):
		return
	FightStart.emit()
	


func _on_cancel_pressed() -> void:
	ShowTutorial.emit(2)
	


func _on_command_line_start_campaign(SkipStory: bool) -> void:
	if (Selecting):
		return
		
	var Run = await ChooseTutorial()
	if (!Run):
		return
	GameStart.emit(false, SkipStory)


func _on_command_line_start_prologue(SkipStory: bool) -> void:
	if (Selecting):
		return
		
	var Run = await ChooseTutorial()
	if (!Run):
		return
	PrologueStart.emit(false, SkipStory)


#func MouseIn() -> void:
	#$SubViewportContainer/SubViewport/InScreenMouse.MouseIn()
#
#func MouseOut() -> void:
	#$SubViewportContainer/SubViewport/InScreenMouse.MouseOut().
