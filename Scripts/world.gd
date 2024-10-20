extends Node3D
class_name World
@export var PlayerDat : PlayerData
@export var scene :PackedScene
@export var BattleScene : PackedScene

@onready var Mapz = $CanvasLayer/Map as Map
@onready var player_hp: ProgressBar = $CanvasLayer/PanelContainer3/HBoxContainer2/PanelContainer/HBoxContainer/PlayerHP
@onready var fuel: ProgressBar = $CanvasLayer/PanelContainer3/HBoxContainer2/PanelContainer3/HBoxContainer/Fuel
@onready var hull_hp: ProgressBar = $CanvasLayer/PanelContainer3/HBoxContainer2/PanelContainer2/HBoxContainer/HullHp
@onready var timer: Timer = $CanvasLayer/Timer
@onready var pause_label: Label = $CanvasLayer2/PauseLabel


var Runningstage = 0

func _ready() -> void:
	Mapz.connect("StageSellected", PrepareForJourney)
	Mapz.connect("StageSearched", StageSearch)
	player_hp.value = PlayerDat.HP
	fuel.value = PlayerDat.FUEL
	hull_hp.value = PlayerDat.HULLHP
	set_physics_process(false)
	
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Pause")):
		var paused = get_tree().paused
		get_tree().paused = !paused
		pause_label.visible = !paused
		
func StartFight(PossibleReward : Array[Item]) -> void:
	var BScene = BattleScene.instantiate() as Battle
	BScene.SupplyReward = PossibleReward
	BScene.PlayerHp = PlayerDat.HP
	$CanvasLayer.add_child(BScene)
	BScene.connect("OnBattleEnded", BattleEnded)

func BattleEnded(Resault : bool, RemainingHP : int, SupplyRew : Array[Item]) -> void:
	PlayerDat.HP = RemainingHP
	if (Resault):
		UpdateSupplies(SupplyRew)
		UpdateHP(RemainingHP)
	else :
		GameLost("You have died")

func UpdateSupplies(supps : Array[Item]) -> void:
	var inv = $CanvasLayer/PanelContainer3/Inventory as Inventory
	for g in supps.size() :
		inv.AddItem(supps[g])

func UpdateHP(NewHP : int) -> void:
	PlayerDat.HP = NewHP
	player_hp.value = NewHP
func UpdateHullHP(NewHP : int) -> void:
	PlayerDat.HULLHP = NewHP
	hull_hp.value = NewHP
func UpdateFuel(NewFuel : float) -> void:
	PlayerDat.FUEL = NewFuel
	fuel.value = NewFuel
	Mapz.ToggleClose()
	Mapz.UpdateFuelRange(NewFuel)
	
	
var fueltoConsume
var StopToFlyTo
func PrepareForJourney(st : MapSpot, stagenum : int, FuelToUse : float):
	StopToFlyTo = st
	Runningstage = stagenum
	ConsumeFuel(FuelToUse)
func ConsumeFuel(Fuel : float) -> void:
	fueltoConsume = Fuel
	PlayerDat.FUEL -= Fuel
	Mapz.ToggleClose()
	set_physics_process(true)
	timer.start()
func _physics_process(_delta: float) -> void:
	var newfuel = PlayerDat.FUEL + ((timer.time_left/timer.wait_time)  * fueltoConsume)
	Mapz.UpdateFuelRange(newfuel)
	fuel.value = newfuel

	
func StartStage() -> void:
	var sc = scene.instantiate() as TravelMinigameGame
	sc.EnemyGoal = fueltoConsume
	sc.Hull = PlayerDat.HULLHP
	sc.connect("OnGameEnded", StageDone)
	add_child(sc)
	sc.SetDestinationMesh(StopToFlyTo.SpotMesh)
	Mapz.visible = false
	$CanvasLayer.visible = false
	

func StageSearch(supplies : Array[Item])-> void:
	StartFight(supplies)
	
func StageDone(victory : bool, supplies : Array[Item], HullHP : int) -> void:
	if (victory):
		UpdateSupplies(supplies)
		Mapz.StageCleared(Runningstage)
	else :
		Mapz.StageFailed()
		GameLost("Your ship got destroyed")
	UpdateHullHP(HullHP)
	Mapz.visible = true
	$CanvasLayer.visible = true

func UseItem(It : Item) -> bool:
	if (It.ItemName == "Medical"):
		if (PlayerDat.HP == 100):
			return false
		else :
			UpdateHP(min(100, PlayerDat.HP + 20))
			return true
	else : if (It.ItemName == "Radioactive"):
		if (PlayerDat.FUEL == 100):
			return false
		else :
			UpdateFuel(min(100, PlayerDat.FUEL + 20))
			return true
	else : if (It.ItemName == "Supply"):
		if (PlayerDat.HULLHP == 100):
			return false
		else :
			UpdateHullHP(min(100, PlayerDat.HULLHP + 20))
			return true
	return false

func _on_timer_timeout() -> void:
	set_physics_process(false)
	StartStage()
	
func GameLost(reason : String):
	get_tree().paused = true
	$CanvasLayer2/PanelContainer.visible = true
	$CanvasLayer2/PanelContainer/VBoxContainer/Label.text = reason


func _on_button_pressed() -> void:
	get_tree().quit()
