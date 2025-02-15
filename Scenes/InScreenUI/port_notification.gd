extends Control
class_name PortNotification
@export var PortAvailableCol: Color
@export var PortUnAvailableCol: Color
@export var ShipControllerEventH : ShipControllerEventHandler

var CurrentShip : MapShip

func _ready() -> void:
	ShipControllerEventH.connect("OnControlledShipChanged", ControlledShipChanged)
	ControlledShipChanged(ShipControllerEventH.CurrentControlled)

func ControlledShipChanged(NewShip : MapShip) -> void:
	if (CurrentShip != null):
		CurrentShip.disconnect("PortChanged", PortUpdated)
	CurrentShip = NewShip
	NewShip.connect("PortChanged", PortUpdated)
	PortUpdated(NewShip.CurrentPort)
	
func PortUpdated(NewPort : MapSpot) -> void:
	if (NewPort == null):
		modulate = PortUnAvailableCol
		$SimulationNotification.text = "NO PORTS NEARBY\nPERSMISSION TO LAND\nDENIED"
	else:
		modulate = PortAvailableCol
		$SimulationNotification.text = "CURRENTLY FLYING OVER {0}\nPERSMISSION TO LAND\nGRANTED".format([NewPort.GetSpotName()])
