extends CanvasLayer

class_name ScreenUI
@export var Cam : ScreenCamera

@export_group("Screen")
@export var Cables : Control
@export var DoorSound : AudioStreamPlayer
@export var ScreenPanel : TextureRect
@export_file("*.tscn") var CardFightUIScene : String
@export_file("*.tscn") var TownUIScene : String
@export_file("*.tscn") var PilotScreenScene : String
@export_file("*.tscn") var FullScreenScene : String

var CardFightUI : ExternalCardFightUI
var TownUi : TownExternalUI
var PilotScreen : PilotScreenUI
var FullScreen : Control

var CurrentScreenState : ScreenState

signal FullScreenToggleStarted(NewState : ScreenState)
signal FullScreenToggleFinished()


func _ready() -> void:
	ScreenPanel.visible = false
	
func ToggleCardFightUI(t : bool) -> void:
	if (t):
		var Sc : PackedScene = await Helper.GetInstance().LoadThreaded(CardFightUIScene).Sign
		CardFightUI = Sc.instantiate()
		add_child(CardFightUI)
		move_child(CardFightUI,0)
	else:
		CardFightUI.queue_free()

func ToggleTownUI(t : bool) -> void:
	if (t):
		var Sc : PackedScene = await Helper.GetInstance().LoadThreaded(TownUIScene).Sign
		TownUi = Sc.instantiate()
		add_child(TownUi)
		move_child(TownUi,0)
	else:
		TownUi.queue_free()

func ToggleFullScreenUI(t : bool) -> void:
	if (t):
		var SC : PackedScene = await Helper.GetInstance().LoadThreaded(FullScreenScene).Sign
		FullScreen = SC.instantiate()
		add_child(FullScreen)
		move_child(FullScreen, 0)
	else:
		FullScreen.queue_free()

func ToggleForegroundUI(t : bool) -> void:
	if (t):
		var Sc : PackedScene = await Helper.GetInstance().LoadThreaded(PilotScreenScene).Sign
		PilotScreen = Sc.instantiate()
		add_child(PilotScreen)
		move_child(PilotScreen,0)

		var SimulationMan = SimulationManager.GetInstance()
		if (SimulationMan != null):
			SimulationMan.SpeedChanged.connect(PilotScreen.SpeedUpdated)
	else:
		PilotScreen.queue_free()


################## SCREEN TRANSITION ########################

enum ScreenState{
	FULL_SCREEN,
	HALF_SCREEN,
	NORMAL_SCREEN,
	NO_SCREEN
}

func CloseScreen() -> void:
	ScreenPanel.visible = true
	DoorSound.play()
	Cam.EnableFullScreenShake()
	await Helper.GetInstance().wait(0.5)
	var CloseTw = create_tween()
	CloseTw.set_ease(Tween.EASE_OUT)
	CloseTw.set_trans(Tween.TRANS_BOUNCE)
	CloseTw.tween_property(ScreenPanel, "position", Vector2.ZERO, 2)
	await CloseTw.finished
	FullScreenToggleStarted.emit(ScreenState.HALF_SCREEN)

func OpenScreen(NewStat : ScreenState) -> void:
	match (NewStat):
		ScreenState.FULL_SCREEN:
			ToggleFullScreenUI(true)
		ScreenState.NORMAL_SCREEN:
			ToggleForegroundUI(true)

	var OpenTw = create_tween()
	OpenTw.set_ease(Tween.EASE_IN)
	OpenTw.set_trans(Tween.TRANS_QUART)
	OpenTw.tween_property(ScreenPanel, "position", Vector2(0, -ScreenPanel.size.y - 40), 1.6)
	await OpenTw.finished
	ScreenPanel.visible = false
	FullScreenToggleFinished.emit()
	Cam.EnableFullScreenShake()

func DoIntroFullScreen(NewStat : ScreenState) -> void:
	ScreenPanel.visible = true
	Cables.visible = false
	DoorSound.play()
	Cam.EnableFullScreenShake()
	await Helper.GetInstance().wait(0.5)
	var CloseTw = create_tween()
	CloseTw.set_ease(Tween.EASE_OUT)
	CloseTw.set_trans(Tween.TRANS_BOUNCE)
	CloseTw.tween_property(ScreenPanel, "position", Vector2(0,0), 2)
	CloseTw.finished.connect(IntroCloseFinisehd.bind(NewStat))

func IntroCloseFinisehd(NewStat : ScreenState) -> void:
	FullScreenToggleStarted.emit(NewStat)
	
	#await Helper.GetInstance().wait(0.2)
	Cables.visible = true
	match (NewStat):
		ScreenState.FULL_SCREEN:
			ToggleFullScreenUI(true)
		ScreenState.NORMAL_SCREEN:
			ToggleForegroundUI(true)
	
	var OpenTw = create_tween()
	OpenTw.set_ease(Tween.EASE_IN)
	OpenTw.set_trans(Tween.TRANS_QUART)
	OpenTw.tween_property(ScreenPanel, "position", Vector2(0, -ScreenPanel.size.y - 40), 1.6)
	await OpenTw.finished
	ScreenPanel.visible = false
	FullScreenToggleFinished.emit()
	Cam.EnableFullScreenShake()

func ToggleFullScreen(NewStat : ScreenState) -> void:
	ScreenPanel.visible = true
	DoorSound.play()
	Cam.EnableFullScreenShake()
	await Helper.GetInstance().wait(0.5)
	var CloseTw = create_tween()
	CloseTw.set_ease(Tween.EASE_OUT)
	CloseTw.set_trans(Tween.TRANS_BOUNCE)
	CloseTw.tween_property(ScreenPanel, "position", Vector2.ZERO, 2)
	await CloseTw.finished
	
	FullScreenToggleStarted.emit(NewStat)
	
	match(CurrentScreenState):
		ScreenState.NORMAL_SCREEN:
			ToggleForegroundUI(false)
		ScreenState.FULL_SCREEN:
			ToggleFullScreenUI(false)
		
	CurrentScreenState = NewStat
	
	match (NewStat):
		ScreenState.FULL_SCREEN:
			ToggleFullScreenUI(true)
		ScreenState.NORMAL_SCREEN:
			ToggleForegroundUI(true)

	var OpenTw = create_tween()
	OpenTw.set_ease(Tween.EASE_IN)
	OpenTw.set_trans(Tween.TRANS_QUART)
	OpenTw.tween_property(ScreenPanel, "position", Vector2(0, -ScreenPanel.size.y - 40), 1.6)
	await OpenTw.finished
	ScreenPanel.visible = false
	FullScreenToggleFinished.emit()
	Cam.EnableFullScreenShake()
