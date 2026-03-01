extends Control

class_name BasePilotScreenInterface

@export var controllerEventHandler: ShipControllerEventHandler
@export var droneDockEventHandler: DroneDockEventHandler
@export var uiEventHandler: UIEventHandler

var controller: PlayerDrivenShip = null

func _ready() -> void:
	droneDockEventHandler.DroneDocked.connect(_onDroneAdded)
	droneDockEventHandler.DroneUndocked.connect(_onDroneRemoved)
	controllerEventHandler.OnControlledShipChanged.connect(_onControlledShipUpdated)
	_onControlledShipUpdated(controllerEventHandler.CurrentControlled)
	print("{0} initialised.".format([_getInterfaceName()]))

func _onDroneAdded(drone: Drone, target: MapShip) -> void:
	pass

func _onDroneRemoved(drone: Drone, target: MapShip) -> void:
	pass

func _onControlledShipUpdated(newController: PlayerDrivenShip) -> void:
	controller = newController

func _getInterfaceName() -> String:
	return "Base"
