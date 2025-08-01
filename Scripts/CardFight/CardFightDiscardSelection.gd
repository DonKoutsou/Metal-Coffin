extends PanelContainer

class_name CardFightDiscardSelection

@export var CardScene : PackedScene
@export var Title : Label
@export var CardContainer : Control

signal CardSelected( Index : int )

func _ready() -> void:
	visible = false

func SetCards(User : BattleShipStats, Cards : Array[Card]) -> void:
	Title.text = "DISCARD ONE"
	for g in Cards.size():
		var b = CardScene.instantiate() as Card
		b.SetCardBattleStats(User, Cards[g].CStats)
		
		b.OnCardPressed.connect(TargetSelected.bind(g))
		CardContainer.call_deferred("add_child", b)
		
	visible = true

func SetCardsPick(User : BattleShipStats, Cards : Array[CardStats]) -> void:
	
	Title.text = "PICK ONE"
	for g in Cards.size():
		var b = CardScene.instantiate() as Card
		b.SetCardBattleStats(User, Cards[g])
		
		b.OnCardPressed.connect(TargetSelected.bind(g))
		CardContainer.call_deferred("add_child", b)
		
	visible = true
	
func TargetSelected(_C : Card, index : int) -> void:
	for g in CardContainer.get_children():
		g.queue_free()
	visible = false
	CardSelected.emit(index)


func _on_button_pressed() -> void:
	TargetSelected(null, -1)
