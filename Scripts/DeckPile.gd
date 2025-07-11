extends Control

class_name DeckPileUI

#@export var CardThing : PackedScene

var CurrentAmm : int = 0

signal CardAddFinished

func UpdateDeckPileAmmount(NewAmm : int) -> void:
	CurrentAmm = NewAmm
	$Label2.text = var_to_str(NewAmm)

var DeckHoverTween : Tween

func HideAmm() -> void:
	$Label2.text = "X"

func OnCardAdded(_CardPos : Vector2) -> void:
	#var C = CardThing.instantiate() as CardViz
	#C.Target = self
	#add_child(C)
	#C.global_position = CardPos
	#
	#await C.Finished
	
	CurrentAmm += 1
	$Label2.text = var_to_str(CurrentAmm)
	
	CardAddFinished.emit()
	
	if (DeckHoverTween and DeckHoverTween.is_running()):
		DeckHoverTween.kill()
	
	DeckHoverTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel(true)
	DeckHoverTween.tween_property(self,"scale", Vector2(1.1, 1.1), 0.1)
	await DeckHoverTween.finished
	if (DeckHoverTween and DeckHoverTween.is_running()):
		DeckHoverTween.kill()
	DeckHoverTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	DeckHoverTween.tween_property(self,"scale", Vector2.ONE, 0.1)
	

func OnCardDrawn() -> void:
	CurrentAmm -= 1
	$Label2.text = var_to_str(CurrentAmm)
	
	if (DeckHoverTween and DeckHoverTween.is_running()):
		DeckHoverTween.kill()
	
	DeckHoverTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).set_parallel(true)
	DeckHoverTween.tween_property(self,"scale", Vector2(1.1, 1.1), 0.2)
	await DeckHoverTween.finished
	if (DeckHoverTween and DeckHoverTween.is_running()):
		DeckHoverTween.kill()
	DeckHoverTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	DeckHoverTween.tween_property(self,"scale", Vector2.ONE, 0.2)
