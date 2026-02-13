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
		CurrentShip.disconnect("LandingEnded2", PortUpdated)
		CurrentShip.disconnect("TakeoffStarted", PortUpdated)
	CurrentShip = NewShip
	NewShip.connect("PortChanged", PortUpdated)
	NewShip.connect("LandingEnded2", PortUpdated)
	NewShip.connect("TakeoffStarted", PortUpdated)
	PortUpdated()

func PortUpdated() -> void:
	if (CurrentShip.CurrentPort == null):
		#$PanelContainer4/VBoxContainer.modulate = PortUnAvailableCol
		LandingText.text = "NO PORTS NEARBY\nLANDING DENIED"
		#BuffText.text = ""
	else: if(CurrentShip.TakingOff):
		LandingText.text = "FLYING OVER {0}\nCLEAR TO LAND".format([CurrentShip.CurrentPort.GetSpotName()])
		
	else: if (CurrentShip.Altitude == 0):
		LandingText.text = "Landed on {0}".format([CurrentShip.CurrentPort.GetSpotName()])
	else:
		#$PanelContainer4/VBoxContainer.modulate = PortAvailableCol
		LandingText.text = "FLYING OVER {0}\nCLEAR TO LAND".format([CurrentShip.CurrentPort.GetSpotName()])
		#var PortThings = ""
		#if (NewPort.HasFuel()):
			#PortThings += "REFUEL TIME/COST -\n"
		#if (NewPort.HasRepair()):
			#PortThings += "REPAIR TIME/COST -\n"
		#if (NewPort.HasUpgrade()):
			#PortThings += "UPGRADE TIME/COST -\n"
		#BuffText.text = PortThings
	#BuffText.visible = NewPort != null
