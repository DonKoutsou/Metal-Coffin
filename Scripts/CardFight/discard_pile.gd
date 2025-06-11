extends Control

class_name DiscardPileUI

#@export var CardThing : PackedScene

var DeckHoverTween : Tween

var CurrentAmm : int = 0

func HideAmm() -> void:
	$Label.text = "X"

func UpdateDiscardPileAmmount(NewAmm : int) -> void:
	CurrentAmm = NewAmm
	$Label.text = var_to_str(NewAmm)

func OnCardRemoved() -> void:
	CurrentAmm -= 1
	$Label.text = var_to_str(CurrentAmm)
	if (DeckHoverTween and DeckHoverTween.is_running()):
		DeckHoverTween.kill()
	
	DeckHoverTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel(true)
	DeckHoverTween.tween_property(self,"scale", Vector2(1.1, 1.1), 0.2)
	await DeckHoverTween.finished
	if (DeckHoverTween and DeckHoverTween.is_running()):
		DeckHoverTween.kill()
	DeckHoverTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	DeckHoverTween.tween_property(self,"scale", Vector2.ONE, 0.2)

func OnCardDiscarded(CardPos : Vector2) -> void:
	#var C = CardThing.instantiate() as CardViz
	#C.Target = self
	#add_child(C)
	#C.global_position = CardPos
	#
	#await C.Finished
	
	CurrentAmm += 1
	
	$Label.text = var_to_str(CurrentAmm)
	
	if (DeckHoverTween and DeckHoverTween.is_running()):
		DeckHoverTween.kill()
	
	DeckHoverTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel(true)
	DeckHoverTween.tween_property(self,"scale", Vector2(1.1, 1.1), 0.2)
	await DeckHoverTween.finished
	if (DeckHoverTween and DeckHoverTween.is_running()):
		DeckHoverTween.kill()
	DeckHoverTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	DeckHoverTween.tween_property(self,"scale", Vector2.ONE, 0.2)
	
	
