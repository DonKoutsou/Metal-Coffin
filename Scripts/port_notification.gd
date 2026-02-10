extends Control
class_name PortNotification
@export var PortAvailableCol: Color
@export var PortUnAvailableCol: Color
@export var ShipControllerEventH : ShipControllerEventHandler
#@export var BuffText : Label
@export var LandingText : Label

var CurrentShip : PlayerDrivenShip

func _ready() -> void:
	ShipControllerEventH.connect("OnControlledShipChanged", ControlledShipChanged)
	#ControlledShipChanged(ShipControllerEventH.CurrentControlled)

func ControlledShipChanged(NewShip : PlayerDrivenShip) -> void:
	if (CurrentShip != null):
		CurrentShip.disconnect("PortChanged", PortUpdated)
	CurrentShip = NewShip
	NewShip.connect("PortChanged", PortUpdated)
	PortUpdated(NewShip.CurrentPort)
	
func PortUpdated(NewPort : MapSpot) -> void:
	if (NewPort == null):
		#$PanelContainer4/VBoxContainer.modulate = PortUnAvailableCol
		LandingText.text = "NO PORTS NEARBY\nLANDING DENIED"
		#BuffText.text = ""
	else:
		#$PanelContainer4/VBoxContainer.modulate = PortAvailableCol
		LandingText.text = "FLYING OVER {0}\nCLEAR TO LAND".format([NewPort.GetSpotName()])
		#var PortThings = ""
		#if (NewPort.HasFuel()):
			#PortThings += "REFUEL TIME/COST -\n"
		#if (NewPort.HasRepair()):
			#PortThings += "REPAIR TIME/COST -\n"
		#if (NewPort.HasUpgrade()):
			#PortThings += "UPGRADE TIME/COST -\n"
		#BuffText.text = PortThings
	#BuffText.visible = NewPort != null
