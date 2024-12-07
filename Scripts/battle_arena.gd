extends Control
class_name BattleArena

@export var ShipStatPanel : PackedScene

@export var playerships : Array[BattleShipStats] = []
@export var EnemyShips : Array[BattleShipStats] = []

@export var PlayerShipScene : PackedScene
@export var EnemyShipScene : PackedScene

var ReadyPlayerShips : Array[BattleShipStats] = []
signal OnBattleEnded(Survivors : Array[BattleShipStats])

var CurrentPlShip : DF_PlayerShip
var CurrentEnemyShip : DF_EnemyShip
# Called when the node enters the scene tree for the first time.
func SetBattleData(PlShips : Array[BattleShipStats], EnemShips : Array[BattleShipStats]):
	playerships.append_array(PlShips)
	EnemyShips.append_array(EnemShips)
func _ready() -> void:
	#$SubViewportContainer/SubViewport/PlShip.set_physics_process(false)
	#$SubViewportContainer/SubViewport/EnemyShip.set_physics_process(false)
	$TouchScreenButton.visible = OS.get_name() != "Windows"
	$TouchScreenButton2.visible = OS.get_name() != "Windows"
	$TouchScreenButton3.visible = OS.get_name() != "Windows"
	
	for g in playerships:
		var panel = ShipStatPanel.instantiate() as ShipBattleStatPanel
		panel.SetShip(g)
		panel.connect("OnShipSelected", ShipSelected)
		$Control2/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2.add_child(panel)
	for g in EnemyShips:
		var panel = ShipStatPanel.instantiate() as ShipBattleStatPanel
		panel.SetShip(g)
		panel.ToggleClickable(false)
		$Control2/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer3/HBoxContainer3.add_child(panel)
	
	
func OnPlShipDest(_Ship : DF_PlayerShip):
	ReadyPlayerShips.remove_at(0)
	if (ReadyPlayerShips.size() == 0):
		queue_free()
		OnBattleEnded.emit(ReadyPlayerShips)
		return
	var NewShip = PlayerShipScene.instantiate() as DF_PlayerShip
	NewShip.connect("OnShipDestroyed", OnPlShipDest)
	NewShip.SetShipStats(ReadyPlayerShips[0])
	$SubViewportContainer/SubViewport.add_child(NewShip)
	NewShip.global_position = $SubViewportContainer/SubViewport/PlSpawnPoint.global_position
	CurrentPlShip = NewShip
	CurrentEnemyShip.pl_ship = NewShip
func OnEnemtShipDest(_Ship : DF_EnemyShip):
	EnemyShips.remove_at(0)
	if (EnemyShips.size() == 0):
		ReadyPlayerShips[0].Hull = CurrentPlShip.HP
		queue_free()
		OnBattleEnded.emit(ReadyPlayerShips)
		return
	var NewShip = EnemyShipScene.instantiate() as DF_EnemyShip
	NewShip.connect("OnShipDestroyed", OnEnemtShipDest)
	NewShip.SetShipStats(EnemyShips[0])
	$SubViewportContainer/SubViewport.add_child(NewShip)
	NewShip.global_position = $SubViewportContainer/SubViewport/EnemySpawnPoint.global_position
	NewShip.pl_ship = CurrentPlShip
	CurrentEnemyShip = NewShip
func ShipSelected(Ship : ShipBattleStatPanel):
	if (!ReadyPlayerShips.has(Ship.stats)):
		ReadyPlayerShips.append(Ship.stats)
		Ship.SetNumber(ReadyPlayerShips.find(Ship.stats) + 1)
	else:
		ReadyPlayerShips.erase(Ship.stats)
		Ship.RedactNumber()
		for g in $Control2/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2.get_children():
			if (ReadyPlayerShips.has(g.stats)):
				g.SetNumber(ReadyPlayerShips.find(g.stats) + 1)

func _on_button_pressed() -> void:
	if (playerships.size() > ReadyPlayerShips.size()):
		return
	$Control2.queue_free()
	var plship = PlayerShipScene.instantiate() as DF_PlayerShip
	plship.connect("OnShipDestroyed", OnPlShipDest)
	plship.SetShipStats(ReadyPlayerShips[0])
	var enemship = EnemyShipScene.instantiate() as DF_EnemyShip
	enemship.connect("OnShipDestroyed", OnEnemtShipDest)
	enemship.SetShipStats(EnemyShips[0])
	$SubViewportContainer/SubViewport.add_child(plship)
	plship.global_position = $SubViewportContainer/SubViewport/PlSpawnPoint.global_position
	enemship.pl_ship = plship
	CurrentPlShip = plship
	$SubViewportContainer/SubViewport.add_child(enemship)
	enemship.global_position = $SubViewportContainer/SubViewport/EnemySpawnPoint.global_position
	CurrentEnemyShip = enemship
	
