extends CanvasLayer

class_name ScreenUI
@export var Cam : ScreenCamera

@export_group("Screen")
@export var Cables : Control
@export_file("*.tscn") var TransitionScreenScene : String
@export_file("*.tscn") var CardFightUIScene : String
@export_file("*.tscn") var TownUIScene : String
@export_file("*.tscn") var PilotScreenScene : String
@export_file("*.tscn") var FullScreenScene : String

var Transition : TransitionPanel
var CardFightUI : ExternalCardFightUI
var TownUi : TownExternalUI
var PilotScreen : PilotScreenUI
var FullScreen : Control
static var Instance : ScreenUI
var CurrentScreenState : ScreenState

signal FullScreenToggleStarted(NewState : ScreenState)
signal FullScreenToggleFinished()

func _ready() -> void:
	Instance = self

func Update(delta : float) -> void:
	if (PilotScreen != null):
		PilotScreen.Update(delta)

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
			SimulationMan.SpeedChanged.connect(PilotScreen.speedUpdated)
			SimulationMan.SimulationToggled.connect(PilotScreen.simulationToggled)
	else:
		PilotScreen.queue_free()


################## SCREEN TRANSITION ########################

enum ScreenState{
	FULL_SCREEN,
	HALF_SCREEN,
	NORMAL_SCREEN,
	NO_SCREEN,
	PILOT_SCREEN,
}

func CloseScreen() -> void:
	var TransitionSc : PackedScene = ResourceLoader.load(TransitionScreenScene)
	Transition = TransitionSc.instantiate()
	
	add_child(Transition)
	Transition.Close()
	Cam.EnableFullScreenShake()

	await Transition.PanelClosed
	FullScreenToggleStarted.emit(ScreenState.HALF_SCREEN)

func OpenScreen(NewStat : ScreenState) -> void:
	match(CurrentScreenState):
		ScreenState.NORMAL_SCREEN:
			ToggleForegroundUI(false)
		ScreenState.FULL_SCREEN:
			ToggleFullScreenUI(false)
		ScreenState.PILOT_SCREEN:
			ToggleForegroundUI(false)
			
	CurrentScreenState = NewStat
	
	match (NewStat):
		ScreenState.FULL_SCREEN:
			ToggleFullScreenUI(true)
		ScreenState.NORMAL_SCREEN:
			ToggleForegroundUI(true)
		ScreenState.PILOT_SCREEN:
			ToggleForegroundUI(true)
	
	Transition.Open()
	await Transition.PanelOpened
	Transition.queue_free()
	
	FullScreenToggleFinished.emit()
	Cam.EnableFullScreenShake()

func DoIntroFullScreen(NewStat : ScreenState) -> void:
	var TransitionSc : PackedScene = ResourceLoader.load(TransitionScreenScene)
	Transition = TransitionSc.instantiate()
	
	add_child(Transition)
	Transition.Close()

	Cables.visible = false
	Cam.EnableFullScreenShake()
	
	await Transition.PanelClosed
	FullScreenToggleStarted.emit(NewStat)
	
	#await Helper.GetInstance().wait(0.2)
	Cables.visible = true
	match (NewStat):
		ScreenState.FULL_SCREEN:
			ToggleFullScreenUI(true)
		ScreenState.NORMAL_SCREEN:
			ToggleForegroundUI(true)
	
	Transition.Open()
	await Transition.PanelOpened
	Transition.queue_free()
	
	FullScreenToggleFinished.emit()
	Cam.EnableFullScreenShake()

func ToggleFullScreen(NewStat : ScreenState) -> void:
	var TransitionSc : PackedScene = ResourceLoader.load(TransitionScreenScene)
	Transition = TransitionSc.instantiate()
	
	add_child(Transition)
	Transition.Close()

	Cam.EnableFullScreenShake()

	await Transition.PanelClosed
	
	FullScreenToggleStarted.emit(NewStat)
	
	match(CurrentScreenState):
		ScreenState.NORMAL_SCREEN:
			ToggleForegroundUI(false)
		ScreenState.PILOT_SCREEN:
			ToggleForegroundUI(false)
		ScreenState.FULL_SCREEN:
			ToggleFullScreenUI(false)
		
	CurrentScreenState = NewStat
	
	match (NewStat):
		ScreenState.FULL_SCREEN:
			ToggleFullScreenUI(true)
		ScreenState.NORMAL_SCREEN:
			ToggleForegroundUI(true)
		ScreenState.PILOT_SCREEN:
			ToggleForegroundUI(true)

	Transition.Open()
	await Transition.PanelOpened
	Transition.queue_free()
	
	FullScreenToggleFinished.emit()
	Cam.EnableFullScreenShake()


enum UI_ELEMENT{
	PILOT_SIMULATION_BUTTON,
	PILOT_SIMULATION_SPEED_BUTTON,
	PILOT_MAP_MARKER_TOGGLE,
	CARD_FIGHT_ENERGY_BAR,
	CARD_FIGHT_RESERVE_BAR,
	STEER,
	THRUST,
	MISSILE_TOGGLE,
	MISSILE_ARM,
	MISSILE_DISSARM,
	MISSILE_LAUNCH,
	MISSILE_DIAL,
	ELEVATION,
	LAND_BUTTON,
	HATCH_BUTTON,
	TOPOLOGY_TOGGLE,
	AEROSONAR,
	REGROUP_BUTTON,
	SHIP_DOCK_BUTTON,
	CARD_FIGHT_DISCARD,
}

func GetUIElement(Element : UI_ELEMENT) -> Node:
	match(Element):
		UI_ELEMENT.PILOT_SIMULATION_BUTTON:
			return PilotScreen.pauseSimulationButton
		UI_ELEMENT.PILOT_SIMULATION_SPEED_BUTTON:
			return PilotScreen.speedSimulationButton
		UI_ELEMENT.PILOT_MAP_MARKER_TOGGLE:
			return PilotScreen.mapMarkerControls.ToggleButton
		UI_ELEMENT.CARD_FIGHT_ENERGY_BAR:
			return CardFightUI.GetEnergyBar()
		UI_ELEMENT.CARD_FIGHT_DISCARD:
			return CardFightUI.DiscardInsertInput
		UI_ELEMENT.CARD_FIGHT_RESERVE_BAR:
			return CardFightUI.GetReserveBar()
		UI_ELEMENT.STEER:
			return PilotScreen.steer
		UI_ELEMENT.THRUST:
			return PilotScreen.thrust
		UI_ELEMENT.MISSILE_TOGGLE:
			return PilotScreen.missileUI.turnOffButton
		UI_ELEMENT.MISSILE_ARM:
			return PilotScreen.missileUI.armButton
		UI_ELEMENT.MISSILE_DISSARM:
			return PilotScreen.missileUI.dissarmButton
		UI_ELEMENT.MISSILE_LAUNCH:
			return PilotScreen.missileUI.launchButton
		UI_ELEMENT.MISSILE_DIAL:
			return PilotScreen.missileUI.missileDial
		UI_ELEMENT.ELEVATION:
			return PilotScreen.elevationThrust
		UI_ELEMENT.LAND_BUTTON:
			return PilotScreen.landButton
		UI_ELEMENT.HATCH_BUTTON:
			return PilotScreen.hatchButton
		UI_ELEMENT.TOPOLOGY_TOGGLE:
			return PilotScreen.pilotScreenSet.TopoButton
		UI_ELEMENT.AEROSONAR:
			return PilotScreen.SonarUI
		UI_ELEMENT.REGROUP_BUTTON:
			return PilotScreen.regroupButton
		UI_ELEMENT.SHIP_DOCK_BUTTON:
			return PilotScreen.shipDockButton
	return null

func UIElementExists(Element : UI_ELEMENT) -> bool:
	match(Element):
		UI_ELEMENT.PILOT_SIMULATION_BUTTON:
			return PilotScreen != null
		UI_ELEMENT.PILOT_SIMULATION_SPEED_BUTTON:
			return PilotScreen != null
		UI_ELEMENT.PILOT_MAP_MARKER_TOGGLE:
			return PilotScreen != null
		UI_ELEMENT.CARD_FIGHT_ENERGY_BAR:
			return CardFightUI != null
		UI_ELEMENT.CARD_FIGHT_RESERVE_BAR:
			return CardFightUI != null
		UI_ELEMENT.CARD_FIGHT_DISCARD:
			return CardFightUI != null
		UI_ELEMENT.STEER:
			return PilotScreen != null
		UI_ELEMENT.THRUST:
			return PilotScreen != null
		UI_ELEMENT.MISSILE_TOGGLE:
			return PilotScreen != null
		UI_ELEMENT.MISSILE_ARM:
			return PilotScreen != null
		UI_ELEMENT.MISSILE_DISSARM:
			return PilotScreen != null
		UI_ELEMENT.MISSILE_LAUNCH:
			return PilotScreen != null
		UI_ELEMENT.MISSILE_DIAL:
			return PilotScreen != null
		UI_ELEMENT.ELEVATION:
			return PilotScreen != null
		UI_ELEMENT.LAND_BUTTON:
			return PilotScreen != null
		UI_ELEMENT.HATCH_BUTTON:
			return PilotScreen != null
		UI_ELEMENT.TOPOLOGY_TOGGLE:
			return PilotScreen != null
		UI_ELEMENT.AEROSONAR:
			return PilotScreen != null
		UI_ELEMENT.REGROUP_BUTTON:
			return PilotScreen != null
		UI_ELEMENT.SHIP_DOCK_BUTTON:
			return PilotScreen != null
	return false
