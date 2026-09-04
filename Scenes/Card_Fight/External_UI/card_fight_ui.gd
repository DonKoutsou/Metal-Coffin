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
@export var DiscardInsertInput : Control
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
var HoveredShip : BattleShipStats

static var Instance : ExternalCardFightUI
static var HOLDING_CARD : bool = false
var AllowEnd : bool = true
var HeldCard : Card

func HideInfo() -> void:
	HardCardLabel.text = "X"
	EnergyBar.HideAmm()
	ReservesBar.HideAmm()
	DeckUI.HideAmm()
	DiscardPile.HideAmm()

func _ready() -> void:
	#set_physics_process(false)
	Instance = self
	PlayerCardPlecement.visible = true
	PlayerCardPlacementInputBlocker.visible = false
	UISoundMan.GetInstance().Refresh()

func _exit_tree() -> void:
	HOLDING_CARD = false

func ShipHovered(ship : BattleShipStats) -> void:
	HoveredShip = ship

func ShipUnhovered(ship : BattleShipStats) -> void:
	if (ship == HoveredShip):
		HoveredShip = null

func _process(_delta: float) -> void:
	if (HeldCard != null):
		if (HeldCard.get_parent() == self):
			
			var PrevPos = HeldCard.global_position + Vector2(HeldCard.size.x / 2.0, 0)
			var d = PrevPos.distance_squared_to(get_global_mouse_position())
			HeldCard.global_position = HeldCard.global_position.move_toward(get_global_mouse_position() - Vector2(HeldCard.size.x / 2.0, 0), d / 500)
			#HeldCard.global_position = get_global_mouse_position() - Vector2(HeldCard.size.x / 2.0, 0)
			var vel = PrevPos - (HeldCard.global_position + Vector2(HeldCard.size.x /2.0, 0))
			HeldCard.rotation = -vel.x / 250
			
		if (!Input.is_action_pressed("Click")):
			ReleaseCard()

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
	C.OnCardPressed.connect(HoldCard)
	#C.OnCardReleased.connect(ReleaseCard)
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

func HoldCard(C : Card) -> void:
	HOLDING_CARD = true
	#mouse_filter = Control.MOUSE_FILTER_STOP
	ToggleHandInput(false)
	InScreenCursor.Instance.ToggleMouse(false)
	C.Dissable(true)
	C.reparent(self)
	HeldCard = C
	C.rotation = 0
	PlayCardSound()
	
	#C.SetPressed()

func ReleaseCard() -> void:
	HOLDING_CARD = false
	#print("thing")
	#mouse_filter = Control.MOUSE_FILTER_IGNORE
	InScreenCursor.Instance.ToggleMouse(true)
	ToggleHandInput(true)
	
	if (HoveredShip != null):
		InserCardtoPlay(HeldCard, false)
	
	else: if (HeldCard.get_parent() == self):
		HeldCard.reparent(PlayerCardPlecement, false)
		HeldCard.Enable()
		PlayCardSound()
		
	else: if (HeldCard.get_parent() == DiscardInsert):
		##IMPLEMENT DISCARD LOGIC
		InsertCardToDiscard(HeldCard, true)
		FightScene.OnCardDiscarded(HeldCard, true)
		
	else: if (HeldCard.get_parent() == PlayCardInsert):
		InserCardtoPlay(HeldCard, true)
		
	HeldCard = null

func InserCardtoPlay(C : Card, skipTransition : bool = false) -> void:
	AllowEnd = false
	var target = HoveredShip
	C.Dissable(true)
	var xPos = (PlayCardInsert.size.x - C.size.x) / 2.0
	if (!skipTransition):

		C.reparent(self)
		C.rotation = 0

		var Movetw = create_tween()
		Movetw.set_ease(Tween.EASE_OUT)
		Movetw.set_trans(Tween.TRANS_QUAD)
		
		Movetw.tween_property(C, "global_position", PlayCardInsert.global_position + Vector2(xPos, 5), 0.25)

		PlayCardSound()
		
		await Movetw.finished

	C.TogglePerspective(true)
	var Cont = Control.new()
	
	Cont.size = PlayCardInsert.size
	PlayCardInsert.add_child(Cont)
	C.reparent(Cont)
	C.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	
	PlayCardInsertSound(CardSoundType.INSERT)
	PlayCardInsertSound(CardSoundType.DISCARD, false)
	#TWEEN
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(Cont, "size", Vector2(PlayCardInsert.size.x, 0), 0.55)
	await tw.finished
	
	PlayCardInsertSound(CardSoundType.BEEP)
	
	if (!await FightScene.OnCardSelected(C, target)):
		PlayCardInsertSound(CardSoundType.BEEPNO)
		PlayCardInsertSound(CardSoundType.EXIT)
		C.TogglePerspective(false, 1)
		C.scale = Vector2(1,1)
		
		#TWEEN
		var tw2 = create_tween()
		tw.set_ease(Tween.EASE_OUT)
		tw2.set_trans(Tween.TRANS_QUAD)
		tw2.tween_property(Cont, "size", Vector2(PlayCardInsert.size), 0.55)
		await tw2.finished
		
		Cont.remove_child(C)
		Cont.queue_free()
		PlayerCardPlecement.add_child(C)
		PlayCardSound()
	if (C != null):
		C.Enable()
	AllowEnd = true
		

func PausePressed() -> void:
	PlayerCardPlecement.visible = !get_tree().paused

func ToggleHandInput(t : bool) -> void:
	if (t):
		PlayerCardPlecement.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		PlayerCardPlecement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PlayerCardPlacementInputBlocker.visible = !t

func InsertCardToDiscard(C : Card, skipTransition : bool = false) -> void:
	AllowEnd = false
	C.Dissable(true)
	C.rotation = 0
	var xPos = (DiscardInsert.size.x - C.size.x) / 2
	if (!skipTransition):
		var pos = C.global_position
		C.get_parent().remove_child(C)
		add_child(C)
		
		
		C.global_position = pos
		var Movetw = create_tween()
		Movetw.set_ease(Tween.EASE_OUT)
		Movetw.set_trans(Tween.TRANS_QUAD)
		Movetw.tween_property(C, "global_position", DiscardInsert.global_position + Vector2(xPos, 5), 0.25)
		
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
	
	C.position = Vector2(xPos, -5)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(Cont, "size", Vector2(DiscardInsert.size.x, 0), 0.55)
	PlayCardInsertSound(CardSoundType.DISCARD)
	await tw.finished
	PlayCardInsertSound(CardSoundType.BEEP)
	C.Enable()
	Cont.queue_free()
	AllowEnd = true

func CardDrawFail() -> void:
	PlayCardInsertSound(CardSoundType.BEEPNO)

func OnCardDrawn(C : Card) -> void:
	AllowEnd = false
	C.Dissable(true)
	PlayCardInsertSound(CardSoundType.BEEPLONG)
	await Helper.wait(0.1)
	PlayCardInsertSound(CardSoundType.EXIT)
	PlayCardInsertSound(CardSoundType.DISCARD, false)
	await Helper.wait(0.1)
	C.rotation = 0
	var Cont = Control.new()
	C.SetRealistic()
	#C.get_parent().remove_child(C)
	DrawCardInsert.add_child(Cont)
	Cont.add_child(C)
	C.ForcePersp(true)
	C.TogglePerspective(false, 1)
	Cont.size = DrawCardInsert.size
	var xPos = (DrawCardInsert.size.x - C.size.x) / 2
	C.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	C.position = Vector2(xPos, -5)
	Cont.size = Vector2(DrawCardInsert.size.x, 0)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(Cont, "size", Vector2(DrawCardInsert.size), 0.55)
	
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
	if (PlayCardInsert.get_child_count() > 1 or DrawCardInsert.get_child_count() > 1 or DiscardInsert.get_child_count() > 1):
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
	S.volume_db = - 5

var playingSounds : Array[CardSoundType]

func PlayCardInsertSound(type : CardSoundType, stack : bool = true) -> void:
	if (!stack):
		if (playingSounds.has(type)):
			return
		playingSounds.append(type)
	var S = DeletableSoundGlobal.new()
	S.stream = GetSoundSample(type)
	S.autoplay = true
	S.pitch_scale = randf_range(0.8, 1.2)
	S.bus = "Sounds"
	add_child(S)
	#S.volume_db = - 7
	S.finished.connect(SoundEnded.bind(type))

func SoundEnded(type : CardSoundType) -> void:
	playingSounds.erase(type)


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
	PlayerCardPlecement.visible = !get_tree().paused

func MouseIn() -> void:
	InScreenCursor.Instance.ToggleMouse(false)
	Input.mouse_mode =  Input.MOUSE_MODE_VISIBLE

func MouseOut() -> void:
	if (HeldCard == null):
		InScreenCursor.Instance.ToggleMouse(true)


var InsertTween : Tween

func _on_card_discard_input_mouse_entered() -> void:
	if (HeldCard != null):
		HeldCard.reparent(DiscardInsert, true)
		HeldCard.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		HeldCard.rotation = 0
		var xPos = (DiscardInsert.size.x - HeldCard.size.x) / 2
		HeldCard.position = Vector2(xPos, 55)
		InsertTween = create_tween()
		InsertTween.set_ease(Tween.EASE_OUT)
		InsertTween.set_trans(Tween.TRANS_BACK)
		InsertTween.tween_property(HeldCard, "position", Vector2(xPos, -5), 0.25)


func _on_card_discard_input_mouse_exited() -> void:
	if (HeldCard != null):
		if (InsertTween != null):
			InsertTween.kill()
		HeldCard.reparent(self)


func _on_card_insert_input_mouse_entered() -> void:
	if (HeldCard != null):
		HeldCard.reparent(PlayCardInsert, false)
		HeldCard.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		HeldCard.rotation = 0
		var xPos = (PlayCardInsert.size.x - HeldCard.size.x) / 2
		HeldCard.position = Vector2(xPos, 55)
		InsertTween = create_tween()
		InsertTween.set_ease(Tween.EASE_OUT)
		InsertTween.set_trans(Tween.TRANS_BACK)
		InsertTween.tween_property(HeldCard, "position", Vector2(xPos, -5), 0.25)


func _on_card_insert_input_mouse_exited() -> void:
	if (HeldCard != null):
		if (InsertTween != null):
			InsertTween.kill()
		HeldCard.reparent(self)
