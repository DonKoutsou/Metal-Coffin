extends Control
class_name BattleArena

@export var ShipStatPanel : PackedScene

@export var playerships : Array[BattleShipStats] = []
@export var EnemyShips : Array[BattleShipStats] = []

var ReadyPlayerShips : Array[ShipBattleStatPanel] = []

signal OnBattleEnded(Survivors : Array[BattleShipStats])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SubViewportContainer/SubViewport/PlShip.set_physics_process(false)
	$SubViewportContainer/SubViewport/EnemyShip.set_physics_process(false)
	$SubViewportContainer/SubViewport/TouchScreenButton.visible = OS.get_name() != "Windows"
	$SubViewportContainer/SubViewport/TouchScreenButton2.visible = OS.get_name() != "Windows"
	$SubViewportContainer/SubViewport/TouchScreenButton3.visible = OS.get_name() != "Windows"
	
	for g in playerships:
		var panel = ShipStatPanel.instantiate() as ShipBattleStatPanel
		panel.SetShip(g)
		panel.connect("OnShipSelected", ShipSelected)
		$Control2/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2.add_child(panel)

func ShipSelected(Ship : ShipBattleStatPanel):
	if (!ReadyPlayerShips.has(Ship)):
		ReadyPlayerShips.append(Ship)
		Ship.SetNumber(ReadyPlayerShips.find(Ship) + 1)
	else:
		ReadyPlayerShips.erase(Ship)
		Ship.RedactNumber()
		for g in ReadyPlayerShips:
			g.SetNumber(ReadyPlayerShips.find(g) + 1)

func _on_button_pressed() -> void:
	$Control2.queue_free()
	$SubViewportContainer/SubViewport/PlShip.set_physics_process(true)
	$SubViewportContainer/SubViewport/EnemyShip.set_physics_process(true)
