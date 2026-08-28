extends Control
class_name CageFightWorld

@export_group("Scenes")
@export var CardFightScene : PackedScene
@export var ScrUI : ScreenUI
@export var TeamComp : PackedScene

signal FightEnded
signal FightTransitionFinished

static var Instance : CageFightWorld

var TCompUI

static func GetInstance() -> CageFightWorld:
	return Instance

func _ready() -> void:
	Rand.NewStaticRand()
	
	ScrUI.StateSwitched.connect(ToggleFullScreen)
	Instance = self
	ScrUI.DoIntroFullScreen(ScreenUI.ScreenState.FULL_SCREEN)
	await ScrUI.FullScreenToggleStarted
	FightTransitionFinished.emit()
	ToggleFullScreen(ScreenUI.ScreenState.FULL_SCREEN)
	TCompUI = TeamComp.instantiate() as CageFight_TeamComp
	Ingame_UIManager.GetInstance().AddUI(TCompUI, true, false)
	TCompUI.TeamReady.connect(TeamsPicked)
	
	World.WORLDST = World.WORLDSTATE.FIGHT

func _exit_tree() -> void:
	World.WORLDST = World.WORLDSTATE.INITIAL

func TeamsPicked(PlTeam : Array[Captain], EnTeam : Array[Captain]) -> void:
	await ScrUI.CloseScreen()

	TCompUI.queue_free()
	
	#ScrUI.ToggleScreenUI(false)
	await ScrUI.ToggleCardFightUI(true)
	ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
	await ScrUI.OpenScreen(ScreenUI.ScreenState.HALF_SCREEN)
	StartDogFight(PlTeam, EnTeam)
	
	AchievementManager.GetInstance().IncrementStatInt("CF", 1)
	#$Inventory.Player = GetMap().GetPlayerShip()

func EndGame() -> void:
	
	#get_tree().get_nodes_in_group("CardFight")[0].queue_free()
	FightEnded.emit()
	#queue_free()

#Dogfight-----------------------------------------------

func StartDogFight(PlTeam : Array[Captain], EnTeam : Array[Captain]):

	var CardF = CardFightScene.instantiate() as Card_Fight
	CardF.CardFightEnded.connect(CardFightEnded)
	CardF.CardFightDestroyed.connect(CardFightDestroyed)
	
	for g in PlTeam:
		var bt : BattleShipStats = g.GetBattleStats()
		bt.Friendly = true
		CardF.PlayerReserves.append(bt)
	for g in EnTeam:
		var bt : BattleShipStats = g.GetBattleStats()
		bt.Friendly = false
		CardF.EnemyReserves.append(bt)
	
	if (PlTeam.size() == 0 and EnTeam.size() == 0):
		CardF.InitRandomFight(3)
	
	#SimulationManager.GetInstance().TogglePause(true)
	#CardF.SetBattleData(FBattleStats, EBattleStats)
	#ScrUI.ToggleFullScreen(ScreenUI.ScreenState.FULL_SCREEN)
	#await ScrUI.FullScreenToggleStarted
	
	Ingame_UIManager.GetInstance().AddUI(CardF, true, false)
	#GetMap().GetScreenUi().ToggleControllCover(true)
	UISoundMan.GetInstance().Refresh()
	
func CardFightEnded(_Survivors : Array[BattleShipStats], won : bool, WonFUnds : float) -> void:
	
	if (won):
		AchievementManager.GetInstance().IncrementStatInt("CFW", 1)
	else:
		AchievementManager.GetInstance().IncrementStatInt("CFL", 1)
	#GetMap().GetScreenUi().ToggleControllCover(false)
	#ScrUI.ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
	

func CardFightDestroyed() -> void:
	get_tree().get_nodes_in_group("CardFight")[0].queue_free()
	FightEnded.emit()
#/////////////////////////////////////////////////////////////
#SCREEN RESIZING
const ScreenPos = Vector2(40.0,40.0)
const OriginalSize = Vector2(926.0, 643.0)
const FullSize = Vector2(1200.0, 640.0)

func ToggleFullScreen(NewState : ScreenUI.ScreenState) -> void:
	
	#$SubViewportContainer.visible = false
	
	#var toggle = await _ScreenUI.FullScreenToggleStarted
	
	if (NewState == ScreenUI.ScreenState.FULL_SCREEN):
		$SubViewportContainer.size = FullSize
		$SubViewportContainer.position = ScreenPos
		
		#$SubViewportContainer._queue_recalc_force_viewport_sizes()
		$SubViewportContainer/ViewPort/InScreenUI.ToggleCrtEffect(true)
		$SubViewportContainer/ViewPort/InScreenUI.SetScreenRes(FullSize)
		
	else: if (NewState == ScreenUI.ScreenState.HALF_SCREEN):
		$SubViewportContainer.size = OriginalSize
		$SubViewportContainer.position = ScreenPos
		
		#$SubViewportContainer._queue_recalc_force_viewport_sizes()
		$SubViewportContainer/ViewPort/InScreenUI.ToggleCrtEffect(true)
		$SubViewportContainer/ViewPort/InScreenUI.SetScreenRes(OriginalSize)
	else:
		$SubViewportContainer.size = get_viewport().get_visible_rect().size
		$SubViewportContainer.position = Vector2.ZERO
		
		#$SubViewportContainer._queue_recalc_force_viewport_sizes()
		$SubViewportContainer/ViewPort/InScreenUI.ToggleCrtEffect(false)
	$SubViewportContainer.visible = true
