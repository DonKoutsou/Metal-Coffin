extends Control
class_name World

@export_group("Nodes")
@export var _Map : Map
@export var _Command : Commander
@export_group("Scenes")
@export var CardFightScene : PackedScene
@export_group("Wallet")
@export var StartingFunds : int = 500000
@export var PlayerWallet : Wallet

# array holding the strings of the stats that we have already notified the player that are getting low
var StatsNotifiedLow : Array[String] = []

signal WRLD_OnGameEnded
#signal WRLD_StatsUpdated(StatN : String)
signal WRLD_StatGotLow(StatN : String)

var Loading = false

static var Instance : World

static func GetInstance() -> World:
	return Instance

func _ready() -> void:
	#$Inventory.Player = GetMap().GetPlayerShip()
	PlayerWallet.Funds = StartingFunds
	UISoundMan.GetInstance().Refresh()
	Instance = self
	if (!Loading):
		PlayIntro()

func GetSaveData() -> SaveData:
	var Data = SaveData.new()
	Data.DataName = "Wallet"
	Data.Datas.append(PlayerWallet)
	return Data

func LoadSaveData(PlWallet : Wallet) -> void:
	PlayerWallet.Funds = PlWallet.Funds

func PlayIntro():
	#GetMap().PlayIntroFadeInt()
	var DiagText : Array[String] = ["Operator.....", "Are you awake ?...", "We've almost arrived ar Cardi. We are slowly entering enemy territory, i advise caution.", "Our journey is comming to an end slowly...", "I recomend staying out of the cities, there are heave patrols checking the roads to and from each city."]
	Ingame_UIManager.GetInstance().CallbackDiag(DiagText, ShowStation, true)
	#$Ingame_UIManager/VBoxContainer/HBoxContainer/Panel.visible = false
	#$Ingame_UIManager/VBoxContainer/HBoxContainer/Stat_Panel.visible = false
	GetMap().ToggleUIForIntro(false)

func ShowStation():
	var DiagText : Array[String]  = ["Dormak is a few killometers away.", "Lets be cautious and slowly make our way there.", "Multiple cities exist on the way there but i'd advise against visiting unless on great need.", "Most of the cities in this are are inhabited by enemy troops, even if we dont stumble on a patrol, occupants of the cities might report our location to the enemy."]
	Ingame_UIManager.GetInstance().CallbackDiag(DiagText, ReturnCamToPlayer, true)
	GetMap().GetCamera().ShowStation()

func ReturnCamToPlayer():
	EnableBackUI()
	GetMap().GetCamera().FrameCamToPlayer()

func EnableBackUI():
	#$Ingame_UIManager/VBoxContainer/HBoxContainer/Panel.visible = true
	#$Ingame_UIManager/VBoxContainer/HBoxContainer/Stat_Panel.visible = true
	GetMap().ToggleUIForIntro(true)

func _enter_tree() -> void:
	var map = GetMap()
	
	map.connect("MAP_EnemyArrival", StartDogFight)
	
	#var statp = GetStatPanel()
	##connect("WRLD_StatsUpdated", statp.StatsUp)
	#connect("WRLD_StatGotLow", statp.StatsLow)
	
	#GetMap().GetPlayerShip().SetShipType(StartingShip)
	#CurrentShip = StartingShip

func TerminateWorld() -> void:
	#GetMap().GetInScreenUI().GetInventory().FlushInventory()
	var PlShip = get_tree().get_nodes_in_group("Ships")[0]
	if (PlShip is PlayerShip):
		InventoryManager.GetInstance().OnCharacterRemoved(PlShip.Cpt)
		PlShip.GetDroneDock().ClearAllDrones()

func GetDialogueProgress() -> DialogueProgressHolder:
	return $DialogueProgressHolder

func GetMap() -> Map:
	return _Map
func GetCommander() -> Commander:
	return _Command
#func GetStatPanel() -> StatPanel:
	#return GetMap()._StatPanel

#Dogfight-----------------------------------------------
var FighingFriendlyUnits : Array[Node2D]
var FighingEnemyUnits : Array[Node2D]
func StartDogFight(Friendlies : Array[Node2D], Enemies : Array[Node2D]):
	FighingFriendlyUnits = Friendlies
	FighingEnemyUnits = Enemies
	
	var FBattleStats : Array[BattleShipStats] = []
	for g in Friendlies:
		FBattleStats.append(g.GetBattleStats())
	var EBattleStats : Array[BattleShipStats] = []
	for g in Enemies:
		EBattleStats.append(g.GetBattleStats())
	var CardF = CardFightScene.instantiate() as Card_Fight
	CardF.connect("CardFightEnded", CardFightEnded)
	CardF.PlayerShips = FBattleStats
	CardF.EnemyShips = EBattleStats
	SimulationManager.GetInstance().TogglePause(true)
	#CardF.SetBattleData(FBattleStats, EBattleStats)
	Ingame_UIManager.GetInstance().AddUI(CardF, true, false)
	GetMap().ToggleUIForIntro(false)
func CardFightEnded(Survivors : Array[BattleShipStats]) -> void:
	for g in Survivors:
		var nam = g.Name
		for z in FighingFriendlyUnits:
			#if z is PlayerShip:
				#ShipData.GetInstance().SetStatValue(STAT_CONST.STATS.HULL, g.Hull)
				#FighingFriendlyUnits.erase(z)
				#break
			if nam == z.Cpt.CaptainName:
				z.Damage(z.Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) - g.Hull)
				FighingFriendlyUnits.erase(z)
				break
	#for g in FighingFriendlyUnits:
		#if (g is PlayerShip):
			#GetMap().StageFailed()
			#GameLost("Your ship got destroyed")
			#return
		#if (g is Drone):
			#
			#GetMap().GetInScreenUI().GetCapUI().OnCaptainDischarged(g.Cpt)
	for g in FighingEnemyUnits:
		var enship = g as HostileShip
		enship.Damage(99999999999)
		#MapPointerManager.GetInstance().RemoveShip(g)
		#g.free()
	SimulationManager.GetInstance().TogglePause(false)
	GetMap().ToggleUIForIntro(true)
#--------------------------------------------------------
func GameLost(reason : String):
	get_tree().paused = true
	$Map/SubViewportContainer/ViewPort/InScreenUI/Control3/PanelContainer.visible = true
	$Map/SubViewportContainer/ViewPort/InScreenUI/Control3/PanelContainer/VBoxContainer/Label.text = reason
