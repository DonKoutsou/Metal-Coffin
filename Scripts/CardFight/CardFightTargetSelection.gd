extends PanelContainer

class_name CardFightTargetSelection

signal EnemySelected(Enemy : BattleShipStats)

func _ready() -> void:
	visible = false

func SetEnemies(EnemyList : Array[BattleShipStats]) -> void:
	for g in EnemyList:
		var b = Button.new()
		b.text = g.Name
		$VBoxContainer/HBoxContainer.add_child(b)
		b.connect("pressed", TargetSelected.bind(g))
	visible = true
	
func TargetSelected(Target : BattleShipStats) -> void:
	for g in $VBoxContainer/HBoxContainer.get_children():
		g.queue_free()
	visible = false
	EnemySelected.emit(Target)
