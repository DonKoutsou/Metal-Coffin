extends PanelContainer

class_name RepairStation

@export var RepairUI : PackedScene
@export var RepairUIPlacement : Node
@export var PlayerWallet : Wallet

signal FuelTransactionFinished(BoughtFuel : float)

func Init(HasRepair : bool, LandedShips : Array[MapShip]) -> void:
	for g in LandedShips:
		var RUI = RepairUI.instantiate() as ShipRepairUI
		RepairUIPlacement.add_child(RUI)
		RUI.Init(g.Cpt, HasRepair)

func _on_leave_fuel_storage_pressed() -> void:
	queue_free()
