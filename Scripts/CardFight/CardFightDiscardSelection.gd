extends PanelContainer

class_name CardFightDiscardSelection

@export var CardScene : PackedScene

@export var CardContainer : Control

signal CardSelected(C : CardStats)

func _ready() -> void:
	visible = false

func SetCards(Cards : Array[Card]) -> void:
	for g in Cards:
		var b = CardScene.instantiate() as Card
		b.SetCardStats(g.CStats, [])
		CardContainer.add_child(b)
		b.OnCardPressed.connect(TargetSelected)
		
	visible = true
	
func TargetSelected(C : Card) -> void:
	for g in CardContainer.get_children():
		g.queue_free()
	visible = false
	CardSelected.emit(C.CStats)


func _on_button_pressed() -> void:
	TargetSelected(null)
