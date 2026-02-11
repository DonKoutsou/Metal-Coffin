extends Control

class_name ExternalCardFightUI

@export var PlayerCardPlecement : Control

@export var EventH : UIEventHandler
@export var EnergyBar : SegmentedBar
@export var ReservesBar : SegmentedBar
@export var PlayCardInsert : Control
@export var DrawCardInsert : Control
@export var DiscardInsert : Control
@export var PlayerCardPlacementInputBlocker : Control
@export var HardCardLabel : Label
@export var DeckUI : DeckPileUI
@export var DiscardPile : DiscardPileUI
@export_group("Sound Files")
@export_file("*.mp3") var CardInsertSound : String
@export_file("*.mp3") var CardOutSound : String
@export_file("*.mp3") var CardDiscardSound : String
@export_file("*.mp3") var CardSound : String
@export_file("*.mp3") var BeepSound : String
@export_file("*.mp3") var BeepNoSound : String
@export_file("*.mp3") var BeepLong : String


signal OnDeckPressed
signal OnShipFallbackPressed
signal OnPullReserves
signal OnEndTurnPressed

#signal CardPlayed(C : CardStats)

var FightScene : Card_Fight

static var Instance : ExternalCardFightUI

var AllowEnd : bool = true

func HideInfo() -> void:
	HardCardLabel.text = "X"
	EnergyBar.HideAmm()
	ReservesBar.HideAmm()
	DeckUI.HideAmm()
	DiscardPile.HideAmm()

func _ready() -> void:
	set_physics_process(false)
	Instance = self
	PlayerCardPlecement.visible = true
	PlayerCardPlacementInputBlocker.visible = false
	UISoundMan.GetInstance().Refresh()

func TogglePlayerCardPlacement(t : bool) -> void:
	PlayerCardPlecement.visible = t

func RegisterFight(Scene : Card_Fight) -> void:
	FightScene = Scene

func UpdateCardsInHandAmm(Amm : int, Max : int) -> void:
	HardCardLabel.text = "{0}/{1}".format([Amm, Max])

static func GetInstacne() -> ExternalCardFightUI:
	return Instance

func GetPlayerCardPlecement() -> Control:
	return PlayerCardPlecement

func GetCardsInHand() -> Array[Card]:
	var HandList : Array[Card]
	for g in PlayerCardPlecement.get_children():
		HandList.append(g)
	for g in PlayCardInsert.get_children():
		HandList.append(g.get_child(0))
	for g in DrawCardInsert.get_children():
		HandList.append(g.get_child(0))
	for g in DiscardInsert.get_children():
		HandList.append(g.get_child(0))
	return HandList
	
func ClearHand() -> void:
	for g in PlayerCardPlecement.get_children():
		g.free()

func UpdateCardDesc(User : BattleShipStats) -> void:
	for g : Card in PlayerCardPlecement.get_children():
		g.UpdateBattleStats(User)

func AddCardToHand(C : Card) -> void:
	C.SetRealistic()
	PlayerCardPlecement.add_child(C)
	C.OnCardPressed.connect(InserCardtoPlay)
	PlayCardSound()

func GetEnergyBar() -> SegmentedBar:
	return EnergyBar

func GetReserveBar() -> SegmentedBar:
	return ReservesBar

#func ToggleEnergyVisibility(t : bool) -> void:
	##EnergyBarParent.visible = t
	#pass

func _on_deck_button_pressed() -> void:
	OnDeckPressed.emit()

func InserCardtoPlay(C : Card) -> void:
	AllowEnd = false
	C.Dissable(true)
	PlayerCardPlecement.Blocked = true
	var pos = C.global_position
	C.get_parent().remove_child(C)
	add_child(C)
	
	C.rotation = 0
	C.global_position = pos
	var Movetw = create_tween()
	Movetw.set_ease(Tween.EASE_OUT)
	Movetw.set_trans(Tween.TRANS_QUAD)
	Movetw.tween_property(C, "global_position", PlayCardInsert.global_position + Vector2(0, -15), 0.35)
	
	var ScaleTw = create_tween()
	#ScaleTw.set_ease(Tween.EASE_IN)
	#ScaleTw.set_trans(Tween.TRANS_CUBIC)
	ScaleTw.tween_property(C, "scale", Vector2(0.85, 0.85), 0.35)
	
	PlayCardSound()
	PlayerCardPlecement.Blocked = false
	await Movetw.finished
	C.TogglePerspective(true)
	var Cont = Control.new()
	
	Cont.size = PlayCardInsert.size
	#Cont.scale.y = 0.8
	C.get_parent().remove_child(C)
	PlayCardInsert.add_child(Cont)
	Cont.add_child(C)
	C.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	C.position = Vector2(15, -5)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(Cont, "size", Vector2(PlayCardInsert.size.x, 0), 0.75)
	PlayCardInsertSound(CardSoundType.INSERT)
	await tw.finished
	PlayCardInsertSound(CardSoundType.BEEP)
	C.Enable()
	if (!await FightScene.OnCardSelected(C)):
		PlayCardInsertSound(CardSoundType.BEEPNO)
		var tw2 = create_tween()
		tw.set_ease(Tween.EASE_OUT)
		tw2.set_trans(Tween.TRANS_QUAD)
		tw2.tween_property(Cont, "size", Vector2(PlayCardInsert.size), 0.75)
		PlayCardInsertSound(CardSoundType.EXIT)
		C.TogglePerspective(false, 1)
		await tw2.finished
		Cont.remove_child(C)
		Cont.queue_free()
		PlayerCardPlecement.add_child(C)
		PlayCardSound()
	AllowEnd = true
		

func PausePressed() -> void:
	PlayerCardPlecement.visible = !get_tree().paused

func ToggleHandInput(t : bool) -> void:
	PlayerCardPlacementInputBlocker.visible = !t

func InsertCardToDiscard(C : Card) -> void:
	AllowEnd = false
	C.Dissable(true)
	var pos = C.global_position
	C.get_parent().remove_child(C)
	add_child(C)
	
	C.rotation = 0
	C.global_position = pos
	var Movetw = create_tween()
	Movetw.set_ease(Tween.EASE_OUT)
	Movetw.set_trans(Tween.TRANS_QUAD)
	Movetw.tween_property(C, "global_position", DiscardInsert.global_position + Vector2(15, 5), 0.5)
	
	PlayCardSound()
	await Movetw.finished
	
	var Cont = Control.new()
	C.TogglePerspective(true)
	Cont.size = DiscardInsert.size
	#Cont.scale.y = 0.8
	C.get_parent().remove_child(C)
	DiscardInsert.add_child(Cont)
	Cont.add_child(C)
	C.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	C.position = Vector2(15, -5)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(Cont, "size", Vector2(DiscardInsert.size.x, 0), 0.75)
	PlayCardInsertSound(CardSoundType.DISCARD)
	await tw.finished
	PlayCardInsertSound(CardSoundType.BEEP)
	C.Enable()
	AllowEnd = true

func CardDrawFail() -> void:
	PlayCardInsertSound(CardSoundType.BEEPNO)

func OnCardDrawn(C : Card) -> void:
	AllowEnd = false
	C.Dissable(true)
	PlayCardInsertSound(CardSoundType.BEEPLONG)
	await Helper.GetInstance().wait(0.1)
	PlayCardInsertSound(CardSoundType.EXIT)
	await Helper.GetInstance().wait(0.1)
	C.rotation = 0
	C.ForcePersp(true)
	C.TogglePerspective(false, 1)
	var Cont = Control.new()
	C.SetRealistic()
	#C.get_parent().remove_child(C)
	DrawCardInsert.add_child(Cont)
	Cont.add_child(C)
	Cont.size = DrawCardInsert.size
	C.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	C.position = Vector2(15, -5)
	Cont.size = Vector2(DrawCardInsert.size.x, 0)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(Cont, "size", Vector2(DrawCardInsert.size), 0.75)
	
	await tw.finished
	#await Helper.GetInstance().wait(0.25)
	Cont.remove_child(C)
	AddCardToHand(C)
	Cont.queue_free()
	C.Enable()
	AllowEnd = true

func _on_pull_reserves_pressed() -> void:
	OnPullReserves.emit()


func _on_switch_ship_pressed() -> void:
	OnShipFallbackPressed.emit()


func _on_button_pressed() -> void:
	if (PlayCardInsert.get_child_count() > 0 or DrawCardInsert.get_child_count() > 0 or DiscardInsert.get_child_count()):
		PopUpManager.GetInstance().DoFadeNotif("Can't End Turn while playing a card")
		return
	OnEndTurnPressed.emit()

func PlayCardSound() -> void:
	var S = DeletableSoundGlobal.new()
	S.stream = ResourceLoader.load(CardSound)
	S.autoplay = true
	S.pitch_scale = randf_range(0.8, 1.2)
	#S.bus = "MapSounds"
	add_child(S)
	S.volume_db = - 20

func PlayCardInsertSound(type : CardSoundType) -> void:
	var S = DeletableSoundGlobal.new()
	S.stream = GetSoundSample(type)
	S.autoplay = true
	S.pitch_scale = randf_range(0.8, 1.2)
	#S.bus = "MapSounds"
	add_child(S)
	S.volume_db = - 7

func GetSoundSample(type : CardSoundType) -> AudioStream:
	var Sample : AudioStream
	if (type == CardSoundType.DISCARD):
		Sample = ResourceLoader.load(CardDiscardSound)
	else : if (type == CardSoundType.INSERT):
		Sample = ResourceLoader.load(CardInsertSound)
		
	else : if (type == CardSoundType.EXIT):
		Sample = ResourceLoader.load(CardOutSound)
	else : if (type == CardSoundType.BEEP):
		Sample = ResourceLoader.load(BeepSound)
	else : if (type == CardSoundType.BEEPNO):
		Sample = ResourceLoader.load(BeepNoSound)
	else : if (type == CardSoundType.BEEPLONG):
		Sample = ResourceLoader.load(BeepLong)
	return Sample
	
enum CardSoundType{
	DISCARD,
	INSERT,
	EXIT,
	BEEP,
	BEEPNO,
	BEEPLONG,
}


func _on_pause_pressed() -> void:
	EventH.OnPausePressed()

func _physics_process(delta: float) -> void:
	Input.mouse_mode =  Input.MOUSE_MODE_VISIBLE
	#Input.set_deferred("mouse_mode", Input.MOUSE_MODE_VISIBLE)


func MouseIn() -> void:
	set_physics_process(true)



func MouseOut() -> void:
	set_physics_process(false)
