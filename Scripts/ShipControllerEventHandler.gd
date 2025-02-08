extends Resource

class_name ShipControllerEventHandler

signal OnControlledShipChanged(Ship : MapShip)

var CurrentControlled : MapShip

func ShipChanged(NewShip : MapShip) -> void:
	CurrentControlled = NewShip
	OnControlledShipChanged.emit(NewShip)
