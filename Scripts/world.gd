extends Node3D
class_name World
@export var PlayerDat : PlayerData
@export var scene :PackedScene
@export var BattleScene : PackedScene

@onready var Mapz = $CanvasLayer/Map as Map
@onready var player_hp: ProgressBar = $CanvasLayer/PanelContainer3/HBoxContainer2/PanelContainer/HBoxContainer/PlayerHP
@onready var fuel: ProgressBar = $CanvasLayer/PanelContainer3/HBoxContainer2/PanelContainer3/HBoxContainer/Fuel

var Runningstage = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Mapz.connect("StageSellected", StartStage)
	Mapz.connect("StageSearched", StageSearch)
	player_hp.value = PlayerDat.HP
	
func StartFight(PossibleReward : Array[Item]) -> void:
	var BScene = BattleScene.instantiate() as Battle
	BScene.SupplyReward = PossibleReward
	BScene.PlayerHp = PlayerDat.HP
	$CanvasLayer.add_child(BScene)
	BScene.connect("OnBattleEnded", BattleEnded)
	pass
func BattleEnded(Resault : bool, RemainingHP : int, SupplyRew : Array[Item]) -> void:
	PlayerDat.HP = RemainingHP
	if (Resault):
		UpdateSupplies(SupplyRew)
		UpdateHP(RemainingHP)
	pass
func UpdateSupplies(supps : Array[Item]) -> void:
	#PlayerDat.Items += supps
	var inv = $CanvasLayer/PanelContainer3/HBoxContainer/Inventory as Inventory
	for g in supps.size() :
		inv.AddItem(supps[g])

func UpdateHP(NewHP : int) -> void:
	PlayerDat.HP = NewHP
	player_hp.value = NewHP
func StartStage(st : MapSpot, stagenum : int) -> void:

	var sc = scene.instantiate() as TravelMinigameGame
	sc.connect("OnGameEnded", StageDone)
	add_child(sc)
	sc.SetDestinationMesh(st.SpotMesh)
	Mapz.visible = false
	$CanvasLayer.visible = false
	Runningstage = stagenum

func StageSearch(supplies : Array[Item])-> void:
	StartFight(supplies)
	
func StageDone(victory : bool, supplies : Array[Item]) -> void:
	if (victory):
		UpdateSupplies(supplies)
		Mapz.StageCleared(Runningstage)
	else :
		Mapz.StageFailed()
		
	Mapz.visible = true
	$CanvasLayer.visible = true
	pass
