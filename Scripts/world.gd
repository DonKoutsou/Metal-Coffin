extends Control
class_name World

@export var ShipDat : ShipData
@export var StartingShip : BaseShip
@export var ShipTradeScene : PackedScene
@export var DogfightScene : PackedScene
@export var CardFightScene : PackedScene

#ship player is currently using
var CurrentShip : BaseShip
# array holding the strings of the stats that we have already notified the player that are getting low
var StatsNotifiedLow : Array[String] = []

signal WRLD_OnGameEnded
signal WRLD_StatsUpdated(StatN : String)
signal WRLD_StatGotLow(StatN : String)

var Loading = false

static var Instance : World

static func GetInstance() -> World:
	return Instance

func _ready() -> void:
	$Inventory.Player = GetMap().GetPlayerShip()
	#UISoundMan.GetInstance().Refresh()
	Instance = self
	if (!Loading):
		PlayIntro()

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
	
	#Inventory Signals
	var inventory = GetInventory()
	inventory.connect("INV_OnItemAdded", OnItemAdded)
	inventory.connect("INV_OnItemRemoved", OnItemRemoved)
	inventory.connect("INV_OnItemUsed", OnItemUsed)
	inventory.connect("INV_OnShipPartDamaged", OnItemDamaged)
	inventory.connect("INV_OnShipPartFixed", OnItemRepaired)
	
	
	var statp = GetStatPanel()
	connect("WRLD_StatsUpdated", statp.StatsUp)
	connect("WRLD_StatGotLow", statp.StatsLow)
	
	ShipDat.connect("SD_StatsUpdated", OnStatsUpdated)
	
	GetInventory().call_deferred("UpdateShipInfo",StartingShip)
	ShipDat.ApplyShipStats(StartingShip.Buffs)
	
	GetMap().GetPlayerShip().SetShipType(StartingShip)
	CurrentShip = StartingShip

func TerminateWorld() -> void:
	ShipDat.RemoveShipStats(CurrentShip.Buffs)
	GetInventory().FlushInventory()
	GetMap().GetPlayerShip().GetDroneDock().ClearAllDrones()

func OnStatsUpdated(StatName : String):
	if (ShipDat.GetStat(StatName).GetCurrentValue() < ShipDat.GetStat(StatName).GetStat() * 0.2):
		if (!StatsNotifiedLow.has(StatName)):
			StatsNotifiedLow.append(StatName)
			#TODO
			#var plship = PlayerShip.GetInstance()
			#if (plship != null):
				#plship.OnStatLow(StatName)
			WRLD_StatGotLow.emit(StatName)
	else:
		if (StatsNotifiedLow.has(StatName)):
			StatsNotifiedLow.remove_at(StatsNotifiedLow.find(StatName))
	WRLD_StatsUpdated.emit(StatName)
	ItemBuffStat(StatName)

func StartShipTrade(NewShip : BaseShip) -> void:
	SimulationManager.GetInstance().TogglePause(true)
	var tradesc = ShipTradeScene.instantiate() as ShipTrade
	$Ingame_UIManager.add_child(tradesc)
	tradesc.StartTrade(CurrentShip, NewShip)
	tradesc.connect("OnTradeFinished", ChangeShip)

func ChangeShip(NewShip : BaseShip) -> void:
	SimulationManager.GetInstance().TogglePause(false)
	if (NewShip == CurrentShip):
		return
	GetInventory().UpdateShipInfo(NewShip)
	ShipDat.RemoveShipStats(CurrentShip.Buffs)
	ShipDat.ApplyShipStats(NewShip.Buffs)
	GetInventory().UpdateSize()
	GetMap().GetPlayerShip().SetShipType(NewShip)
	CurrentShip = NewShip

func GetShipSaveData() -> SaveData:
	var dat = SaveData.new()
	dat.DataName = "Ship"
	var Datas : Array[Resource]
	Datas.append(CurrentShip)
	dat.Datas = Datas
	return dat

func LoadData(Data : Resource) -> void:
	var dat = Data as StatSave
	ShipDat.SetStatValue("FUNDS", dat.Value[0])
	ShipDat.SetStatValue("HULL", dat.Value[1])
	ShipDat.SetStatValue("FUEL", dat.Value[2])
	ItemBuffStat("FUEL")
	
func GetInventory() -> Inventory:
	return $Inventory

func GetDialogueProgress() -> DialogueProgressHolder:
	return $DialogueProgressHolder

func GetMap() -> Map:
	return $Map

func GetStatPanel() -> StatPanel:
	return $Map/OuterUI/HBoxContainer/Stat_Panel

func TestTrade() -> void:
	StartShipTrade(load("res://Resources/Ships/Ship2.tres") as BaseShip)
func OnItemAdded(It : Item) -> void:
	if (It is ShipPart and !It.IsDamaged):
		ShipDat.ApplyShipPartStat(It)
		ItemBuffStat(It.UpgradeName)
func OnItemRemoved(It : Item) -> void:
	if (It is ShipPart and !It.IsDamaged):
		ShipDat.RemoveShipPartStat(It)
		ItemBuffStat(It.UpgradeName)
func OnItemRepaired(Part : ShipPart) -> void:
	ShipDat.ApplyShipPartStat(Part)
	ItemBuffStat(Part.UpgradeName)
func OnItemDamaged(Part : ShipPart) -> void:
	ShipDat.RemoveShipPartStat(Part)
	ItemBuffStat(Part.UpgradeName)
func OnItemUsed(It : UsableItem) -> void:
	ShipDat.RefilResource(It.StatUseName, 20)
	ItemBuffStat(It.StatUseName)
	
func ItemBuffStat(UpName : String) -> void:
	if (UpName == "VIZ_RANGE"):
		GetMap().GetPlayerShip().UpdateVizRange(ShipDat.GetStat("VIZ_RANGE").GetStat())
	if UpName == "ELINT":
		GetMap().GetPlayerShip().UpdateELINTTRange(ShipDat.GetStat("ELINT").GetStat())

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Pause")):
		Pause()

func Pause() -> void:
	var paused = get_tree().paused
	get_tree().paused = !paused
	$Map/SubViewportContainer/ViewPort/InScreenUI/Control3/PauseContainer.visible = !paused

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
	Ingame_UIManager.GetInstance().AddUI(CardF, false, true)
func CardFightEnded(Survivors : Array[BattleShipStats]) -> void:
	for g in Survivors:
		var nam = g.Name
		for z in FighingFriendlyUnits:
			if z is PlayerShip and nam == "Player":
				ShipData.GetInstance().SetStatValue("HULL", g.Hull)
				FighingFriendlyUnits.erase(z)
				break
			if z is Drone and nam == z.Cpt.CaptainName:
				z.Damage(z.Cpt.GetStatValue("HULL") - g.Hull)
				FighingFriendlyUnits.erase(z)
				break
	for g in FighingFriendlyUnits:
		if (g is PlayerShip):
			GetMap().StageFailed()
			GameLost("Your ship got destroyed")
			return
		if (g is Drone):
			CaptainUI.GetInstance().OnCaptainDischarged(g.Cpt)
	for g in FighingEnemyUnits:
		var enship = g as HostileShip
		enship.Damage(99999999999)
		#MapPointerManager.GetInstance().RemoveShip(g)
		#g.free()
	SimulationManager.GetInstance().TogglePause(false)

#--------------------------------------------------------
func GameLost(reason : String):
	get_tree().paused = true
	$Ingame_UIManager/PanelContainer.visible = true
	$Ingame_UIManager/PanelContainer/VBoxContainer/Label.text = reason
func _on_save_pressed() -> void:
	SaveLoadManager.GetInstance().Save(self)
	PopUpManager.GetInstance().DoFadeNotif("Save successful")
func _on_exit_pressed() -> void:
	WRLD_OnGameEnded.emit()
func _on_pause_pressed() -> void:
	Pause()
func _on_return_pressed() -> void:
	Pause()
func On_Game_Lost_Button_Pressed() -> void:
	WRLD_OnGameEnded.emit()
func _on_captain_button_pressed() -> void:
	CaptainUI.GetInstance()._on_captain_button_pressed()
