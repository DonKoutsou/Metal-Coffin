extends Control

class_name RecruitShop

@export var Stats : CaptainStatContainer
@export var ShipButtonsParent : Control
@export var PlWaller : Wallet
#@export var Inv : CharacterInventory

var CurrentShip : Captain
var currentIndex : int = -1

signal RecruitClosed

signal OnCaptainBought(Cpt : Captain)

var AvailableCaptains : Array[Captain]

func _exit_tree() -> void:
	if (CurrentShip != null):
		CurrentShip._CharInv.queue_free()

func Init(Ships : Array[Captain]) -> void:
	
	AvailableCaptains = Ships
	
	RefreshCaptains()
	
	var B : Button = ShipButtonsParent.get_child(0)
	B.set_pressed_no_signal(true)
	
	Stats.ShowStats()

func RefreshCaptains() -> void:
	for g in ShipButtonsParent.get_children():
		g.queue_free()
	
	for g in AvailableCaptains.size():
		var b = Button.new()
		ShipButtonsParent.add_child(b)
		b.text = AvailableCaptains[g].GetCaptainName()
		b.pressed.connect(OnShipSelected.bind(g))
		b.toggle_mode = true

	OnShipSelected(0)

func OnShipSelected(ShipIndex : int) -> void:
	if (ShipIndex == currentIndex):
		var B : Button = ShipButtonsParent.get_child(currentIndex)
		B.set_pressed_no_signal(true)
		return
	if (CurrentShip != null):
		CurrentShip._CharInv.queue_free()
		var B : Button = ShipButtonsParent.get_child(currentIndex)
		B.set_pressed_no_signal(false)
		
	CurrentShip = AvailableCaptains[ShipIndex].GetDuplicate()

	currentIndex = ShipIndex
	CurrentShip.RegisterInventory(CharacterInventory.newInv(CurrentShip))
	Stats.SetCaptain(CurrentShip)
	#Stats.ShowStats()
	#Inv.InitialiseStarting(Ship)

func _on_buy_pressed() -> void:
	if (PlWaller.Funds > CurrentShip.GetValue()):
		var s = PopUpManager.GetInstance().DoConfirm("Buy ship for {0} drahma?".format([CurrentShip.GetValue()]), "Yes", null)
		s.Sign.connect(OnBuyConfirmed)
	else:
		PopUpManager.GetInstance().DoFadeNotif("Not enough funds")

func OnBuyConfirmed(t : bool) -> void:
	if (t):
		PlWaller.AddFunds(-CurrentShip.GetValue())
		OnCaptainBought.emit(AvailableCaptains[currentIndex].duplicate(true))
		
		CurrentShip._CharInv.queue_free()
		AvailableCaptains.remove_at(currentIndex)
		CurrentShip = null
		if (AvailableCaptains.size() == 0):
			_on_close_pressed()
		else:
			RefreshCaptains()

func _on_close_pressed() -> void:
	RecruitClosed.emit()
	queue_free()


func _on_button_pressed() -> void:
	Stats.ShowStats()

func _on_button_2_pressed() -> void:
	Stats.ShowDeck()

func _on_button_3_pressed() -> void:
	Stats.ShowInvetory()
	
func _on_button_4_pressed() -> void:
	Stats.ShowDisposition()
