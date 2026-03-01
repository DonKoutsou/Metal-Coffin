extends Resource

class_name ShipControllerEventHandler

signal OnControlledShipChanged(Ship : PlayerDrivenShip)

var CurrentControlled : PlayerDrivenShip

func ShipChanged(NewShip : PlayerDrivenShip) -> void:
	CurrentControlled = NewShip
	OnControlledShipChanged.emit(NewShip)

signal TargetPositionPicked(pos : Vector2, Add : bool)
signal TargetShipPicked(Target : MapShip)
signal TargetAltitudeChanged(Offset : float)

func OnTargetPositionPicked(pos : Vector2) -> void:
	TargetPositionPicked.emit(pos, false)

func OnTargetPositionAdded(pos : Vector2) -> void:
	TargetPositionPicked.emit(pos, true)

func OnTargetShipSelected(Target : MapShip) -> void:
	TargetShipPicked.emit(Target)

func OnTargetAltitudeChanged(Offset : float) -> void:
	TargetAltitudeChanged.emit(Offset)
	CurrentControlled.UpdateTargetAltitude(Offset)
