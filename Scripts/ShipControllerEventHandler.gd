extends Resource

class_name ShipControllerEventHandler

signal OnControlledShipChanged(Ship : PlayerDrivenShip)

var CurrentControlled : PlayerDrivenShip

func ShipChanged(NewShip : PlayerDrivenShip) -> void:
	CurrentControlled = NewShip
	OnControlledShipChanged.emit(NewShip)

signal TargetPositionPicked(pos : Vector2)

func OnTargetPositionPicked(pos : Vector2) -> void:
	TargetPositionPicked.emit(pos)
