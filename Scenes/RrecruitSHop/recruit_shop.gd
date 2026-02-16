extends Control

class_name RecruitShop

@export var Stats : CaptainStatContainer
@export var ShipButtonsParent : Control
@export var PlWaller : Wallet
@export var Inv : CharacterInventory

var CurrentShip : Captain

signal RecruitClosed

signal OnCaptainBought(Cpt : Captain)

var AvailableCaptains : Array[Captain]

func Init(Ships : Array[Captain]) -> void:
	
	AvailableCaptains = Ships
	
	for g in Ships:
		var b = Button.new()
		ShipButtonsParent.add_child(b)
		b.text = g.GetCaptainName()
		b.pressed.connect(OnShipSelected.bind(g))
	
	OnShipSelected(Ships[0])

func RefreshCaptains() -> void:
	for g in ShipButtonsParent.get_children():
		g.queue_free()
		
	for g in AvailableCaptains:
		var b = Button.new()
		ShipButtonsParent.add_child(b)
		b.text = g.GetCaptainName()
		b.pressed.connect(OnShipSelected.bind(g))
	OnShipSelected(AvailableCaptains[0])

func OnShipSelected(Ship : Captain) -> void:
	if (Ship == CurrentShip):
		return
	CurrentShip = Ship
	Stats.SetCaptain(Ship.GetDuplicate())
	Stats.ShowStats()
	Inv.InitialiseStarting(Ship)

func _on_buy_pressed() -> void:
	if (PlWaller.Funds > CurrentShip.GetValue()):
		PlWaller.AddFunds(-CurrentShip.GetValue())
		OnCaptainBought.emit(CurrentShip)
		RefreshCaptains()


func _on_close_pressed() -> void:
	RecruitClosed.emit()
	queue_free()


func _on_button_pressed() -> void:
	Stats.ShowStats()


func _on_button_2_pressed() -> void:
	Stats.ShowDeck()
