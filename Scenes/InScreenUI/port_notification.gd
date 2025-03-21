extends Control
class_name PortNotification
@export var PortAvailableCol: Color
@export var PortUnAvailableCol: Color
@export var ShipControllerEventH : ShipControllerEventHandler

var CurrentShip : MapShip

func _ready() -> void:
	ShipControllerEventH.connect("OnControlledShipChanged", ControlledShipChanged)
	#ControlledShipChanged(ShipControllerEventH.CurrentControlled)

func ControlledShipChanged(NewShip : MapShip) -> void:
	if (CurrentShip != null):
		CurrentShip.disconnect("PortChanged", PortUpdated)
	CurrentShip = NewShip
	NewShip.connect("PortChanged", PortUpdated)
	PortUpdated(NewShip.CurrentPort)
	
func PortUpdated(NewPort : MapSpot) -> void:
	if (NewPort == null):
		modulate = PortUnAvailableCol
		$VBoxContainer/HBoxContainer/SimulationNotification.text = "NO PORTS NEARBY\nPERSMISSION TO LAND\nDENIED"
		$VBoxContainer/SimulationNotification2.text = ""
	else:
		modulate = PortAvailableCol
		$VBoxContainer/HBoxContainer/SimulationNotification.text = "FLYING OVER {0}\nPERSMISSION TO LAND\nGRANTED".format([NewPort.GetSpotName()])
		var PortThings = ""
		if (NewPort.HasFuel()):
			PortThings += "faster and cheaper refuels\n"
		if (NewPort.HasRepair()):
			PortThings += "faster and cheaper repairs\n"
		if (NewPort.HasUpgrade()):
			PortThings += "Ship parts can be upgraded\n"
		$VBoxContainer/SimulationNotification2.text = PortThings
	$VBoxContainer/SimulationNotification2.visible = NewPort != null
