extends Control

class_name ExternalCardFightUI

@export var CardScene : PackedScene

@export var PlayerCardPlecement : Control

@export var EnergyBar : SegmentedBar
@export var ReservesBar : SegmentedBar

@export var ShipFallBackButton : Button

@export var PlayCardInsert : Control
@export var DrawCardInsert : Control

signal OnDeckPressed
signal OnShipFallbackPressed
signal OnPullReserves
signal OnEndTurnPressed

#signal CardPlayed(C : CardStats)

var FightScene : Card_Fight

static var Instance : ExternalCardFightUI

func _ready() -> void:
	Instance = self

func RegisterFight(Scene : Card_Fight) -> void:
	FightScene = Scene

static func GetInstacne() -> ExternalCardFightUI:
	return Instance

func GetPlayerCardPlecement() -> Control:
	return PlayerCardPlecement

func ClearHand() -> void:
	for g in PlayerCardPlecement.get_children():
		g.free()

func AddCardToHand(C : Card) -> void:
	PlayerCardPlecement.add_child(C)
	C.OnCardPressed.connect(InserCardtoPlay)

func GetEnergyBar() -> SegmentedBar:
	return EnergyBar

func GetReserveBar() -> SegmentedBar:
	return ReservesBar

func ToggleEnergyVisibility(t : bool) -> void:
	#EnergyBarParent.visible = t
	pass


func _on_deck_button_pressed() -> void:
	OnDeckPressed.emit()

func InserCardtoPlay(C : Card) -> void:
	
	var pos = C.global_position
	C.get_parent().remove_child(C)
	add_child(C)
	if (C.rotation > 0):
		var RotTw = create_tween()
		RotTw.set_ease(Tween.EASE_OUT)
		RotTw.set_trans(Tween.TRANS_QUAD)
		RotTw.tween_property(C, "rotation", 0, 0.25)
	C.global_position = pos
	var Movetw = create_tween()
	Movetw.set_ease(Tween.EASE_OUT)
	Movetw.set_trans(Tween.TRANS_QUAD)
	Movetw.tween_property(C, "global_position", PlayCardInsert.global_position, 0.5)
	await Movetw.finished
	
	
	var Cont = Control.new()
	
	Cont.size = PlayCardInsert.size
	C.get_parent().remove_child(C)
	PlayCardInsert.add_child(Cont)
	Cont.add_child(C)
	C.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	C.position = Vector2(15,3)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(Cont, "size", Vector2(PlayCardInsert.size.x, 0), 0.75)
	await tw.finished
	#CardPlayed.emit(C)
	if (!await FightScene.OnCardSelected(C)):
		var tw2 = create_tween()
		tw.set_ease(Tween.EASE_OUT)
		tw2.set_trans(Tween.TRANS_QUAD)
		tw2.tween_property(Cont, "size", Vector2(PlayCardInsert.size), 0.5)
		await tw2.finished
		Cont.remove_child(C)
		Cont.queue_free()
		PlayerCardPlecement.add_child(C)
	#Cont.queue_free()
	#C.queue_free()

func OnCardDrawn(C : Card) -> void:
	C.rotation = 0
	var Cont = Control.new()
	
	#C.get_parent().remove_child(C)
	DrawCardInsert.add_child(Cont)
	Cont.add_child(C)
	Cont.size = DrawCardInsert.size
	C.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	C.position = Vector2(15,3)
	Cont.size = Vector2(DrawCardInsert.size.x, 0)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property(Cont, "size", Vector2(DrawCardInsert.size), 0.75)
	await tw.finished
	#await Helper.GetInstance().wait(0.25)
	Cont.remove_child(C)
	AddCardToHand(C)
	Cont.queue_free()


func _on_pull_reserves_pressed() -> void:
	OnPullReserves.emit()


func _on_switch_ship_pressed() -> void:
	OnShipFallbackPressed.emit()


func _on_button_pressed() -> void:
	OnEndTurnPressed.emit()
