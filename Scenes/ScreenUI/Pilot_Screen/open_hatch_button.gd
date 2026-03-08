extends Button

class_name OpenHatchButton

@export var ShipControllerEventH : ShipControllerEventHandler

var CurrentShip : PlayerDrivenShip

func _ready() -> void:
	ShipControllerEventH.OnControlledShipChanged.connect(ControlledShipChanged)
	ControlledShipChanged(ShipControllerEventH.CurrentControlled)

func ControlledShipChanged(NewShip : PlayerDrivenShip) -> void:
	if (CurrentShip != null):
		CurrentShip.disconnect("PortChanged", PortUpdated)
		CurrentShip.disconnect("AltitudeChanged", PortUpdated)
	CurrentShip = NewShip
	NewShip.connect("PortChanged", PortUpdated)
	NewShip.connect("AltitudeChanged", PortUpdated)
	PortUpdated(0)

func PortUpdated(NewAlt : float) -> void:
	if (CurrentShip.CurrentPort != null and CurrentShip.Landed()):
		disabled = false
	else:
		disabled = true
