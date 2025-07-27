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
	Instance = self
	ScrUI.DoIntroFullScreen(ScreenUI.ScreenState.FULL_SCREEN)
	await ScrUI.FullScreenToggleStarted
	FightTransitionFinished.emit()
	ToggleFullScreen(ScreenUI.ScreenState.FULL_SCREEN)
	TCompUI = TeamComp.instantiate() as CageFight_TeamComp
	Ingame_UIManager.GetInstance().AddUI(TCompUI, true, false)
	TCompUI.TeamReady.connect(TeamsPicked)
	

func TeamsPicked(PlTeam : Array[Captain], EnTeam : Array[Captain]) -> void:
	ScrUI.ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
	await ScrUI.FullScreenToggleStarted
	ToggleFullScreen(ScreenUI.ScreenState.HALF_SCREEN)
	TCompUI.queue_free()
	
	ScrUI.ToggleScreenUI(false)
	ScrUI.ToggleCardFightUI(true)
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
		CardF.PlayerReserves.append(g.GetBattleStats())
	for g in EnTeam:
		CardF.EnemyReserves.append(g.GetBattleStats())

	CardF.InitRandomFight(5)
	
	#SimulationManager.GetInstance().TogglePause(true)
	#CardF.SetBattleData(FBattleStats, EBattleStats)
	#ScrUI.ToggleFullScreen(ScreenUI.ScreenState.FULL_SCREEN)
	#await ScrUI.FullScreenToggleStarted
	
	Ingame_UIManager.GetInstance().AddUI(CardF, true, false)
	#GetMap().GetScreenUi().ToggleControllCover(true)
	UISoundMan.GetInstance().Refresh()
	
func CardFightEnded(_Survivors : Array[BattleShipStats], won : bool) -> void:
	
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
const ScreenPos = Vector2(67.0,62.0)
const OriginalSize = Vector2(869, 595.0)
const FullSize = Vector2(1148.0, 595.0)

func ToggleFullScreen(NewState : ScreenUI.ScreenState) -> void:
	
	#$SubViewportContainer.visible = false
	
	#var toggle = await _ScreenUI.FullScreenToggleStarted
	
	if (NewState == ScreenUI.ScreenState.FULL_SCREEN):
		$SubViewportContainer.position = ScreenPos
		$SubViewportContainer.size = FullSize
		$SubViewportContainer/ViewPort/InScreenUI.ToggleCrtEffect(true)
		$SubViewportContainer/ViewPort/InScreenUI.SetScreenRes(FullSize)
		
	else: if (NewState == ScreenUI.ScreenState.HALF_SCREEN):
		$SubViewportContainer.position = ScreenPos
		$SubViewportContainer.size = OriginalSize
		$SubViewportContainer/ViewPort/InScreenUI.ToggleCrtEffect(true)
		$SubViewportContainer/ViewPort/InScreenUI.SetScreenRes(OriginalSize)
	else:
		$SubViewportContainer.position = Vector2.ZERO
		$SubViewportContainer.size = get_viewport().get_visible_rect().size
		$SubViewportContainer/ViewPort/InScreenUI.ToggleCrtEffect(false)
	$SubViewportContainer.visible = true
