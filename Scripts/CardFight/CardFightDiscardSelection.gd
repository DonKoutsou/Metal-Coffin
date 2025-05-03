extends PanelContainer

class_name CardFightDiscardSelection

@export var CardScene : PackedScene

@export var CardContainer : Control

signal CardSelected( Index : int )

func _ready() -> void:
	visible = false

func SetCards(Cards : Array[Card]) -> void:
	for g in Cards.size():
		var b = CardScene.instantiate() as Card
		b.SetCardStats(Cards[g].CStats)
		CardContainer.add_child(b)
		b.OnCardPressed.connect(TargetSelected.bind(g))
		
	visible = true
	
func TargetSelected(C : Card, index : int) -> void:
	for g in CardContainer.get_children():
		g.queue_free()
	visible = false
	CardSelected.emit(index)


func _on_button_pressed() -> void:
	TargetSelected(null, -1)
