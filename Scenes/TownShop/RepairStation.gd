extends PanelContainer

class_name RepairStation

@export var RepairUI : PackedScene
@export var RepairUIPlacement : Node
@export var PlayerWallet : Wallet
@export var ShipButtonsParent : Control
@export_range(-INF, +INF, 0.1)var test : float

#signal FuelTransactionFinished(BoughtFuel : float)

var AvailableShips : Array[MapShip]
var CurrentShipIndex : int

func RefreshCaptains() -> void:
	for g in ShipButtonsParent.get_children():
		g.queue_free()
		
	for g in AvailableShips.size():
		var b = Button.new()
		ShipButtonsParent.add_child(b)
		b.text = AvailableShips[g].Cpt.GetCaptainName()
		b.pressed.connect(OnShipSelected.bind(g))
		b.toggle_mode = true
		
	OnShipSelected(0)

func OnShipSelected(ShipIndex : int) -> void:
	if (ShipIndex == CurrentShipIndex):
		var b : Button = ShipButtonsParent.get_child(ShipIndex)
		b.set_pressed_no_signal(true)
		return
	else:
		var b : Button = ShipButtonsParent.get_child(CurrentShipIndex)
		b.set_pressed_no_signal(false)

func Init(HasRepair : bool, LandedShips : Array[MapShip]) -> void:
	for g in LandedShips:
		var RUI = RepairUI.instantiate() as ShipRepairUI
		RepairUIPlacement.add_child(RUI)
		RUI.Init(g.Cpt, HasRepair)

func _on_leave_pressed() -> void:
	queue_free()
