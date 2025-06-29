extends PanelContainer

class_name CardFightTargetSelection

@export var ShipVizScene : PackedScene

@export var ShipVizContainer : Control

signal EnemySelected(Enemy : BattleShipStats)

func _ready() -> void:
	visible = false

func SetEnemies(EnemyList : Array[BattleShipStats], AllowMove : bool = false) -> void:
	for g in EnemyList:
		var b = ShipVizScene.instantiate() as CardFightShipViz
		b.SetStats(g)
		ShipVizContainer.add_child(b)
		
		b.connect("pressed", TargetSelected.bind(g))
	visible = true
	$VBoxContainer/Button.visible = AllowMove
	
func TargetSelected(Target : BattleShipStats) -> void:
	for g in ShipVizContainer.get_children():
		g.queue_free()
	visible = false
	EnemySelected.emit(Target)


func _on_button_pressed() -> void:
	TargetSelected(null)
