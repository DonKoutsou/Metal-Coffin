extends Node

@export var DroneDockEventH : DroneDockEventHandler
@onready var player_ship: PlayerShip = $"../CanvasLayer/SubViewportContainer/SubViewport/PlayerShip"
@export var HappeningUI : PackedScene

var AvailableShips : Array[Drone] = []

var ControlledShip : MapShip

func _ready() -> void:
	DroneDockEventH.connect("DroneDocked", OnDroneDocked)
	DroneDockEventH.connect("DroneUndocked", OnDroneUnDocked)
	ControlledShip = player_ship

func OnDroneDocked(D : Drone) -> void:
	AvailableShips.erase(D)
	
func OnDroneUnDocked(D : Drone) -> void:
	AvailableShips.append(D)
	ControlledShip = D

func _on_radar_button_pressed() -> void:
	ControlledShip.ToggleRadar()

func _on_land_button_pressed() -> void:
	var spot = ControlledShip.CurrentPort as MapSpot
	if (spot == null):
		PopUpManager.GetInstance().DoFadeNotif("No port to land to")
		return
	else:
		var sc = spot.FuelTradeScene as PackedScene
		var fuel = sc.instantiate() as TownScene
		fuel.HasFuel = spot.HasFuel()
		fuel.HasRepair = spot.HasRepair()
		fuel.TownFuel = spot.CityFuelReserves
		fuel.BoughtFuel = spot.PlayerFuelReserves
		fuel.BoughtRepairs = spot.PlayerRepairReserves
		fuel.connect("TransactionFinished", FuelTransactionFinished)
		Ingame_UIManager.GetInstance().AddUI(fuel, false, true)
		SimulationManager.GetInstance().TogglePause(true)
	Land(spot)
	
func FuelTransactionFinished(BFuel : float, BRepair: float, NewCurrency : float):
	ShipData.GetInstance().SetStatValue("FUNDS", NewCurrency)
	var spot = ControlledShip.CurrentPort as MapSpot
	if (spot.PlayerFuelReserves != BFuel):
		spot.CityFuelReserves -= BFuel
	if (BFuel < 0):
		ShipData.GetInstance().ConsumeResource("FUEL", -BFuel)

	spot.PlayerFuelReserves = max(0 , BFuel)
	spot.PlayerRepairReserves = max(0, BRepair)
	
	SimulationManager.GetInstance().TogglePause(false)

func Land(Spot : MapSpot) -> void:
	if (Spot.Evnt != null and !Spot.Visited):
		var happeningui = HappeningUI.instantiate() as HappeningInstance
		Ingame_UIManager.GetInstance().AddUI(happeningui, false, true)
		happeningui.PresentHappening(Spot.Evnt)
	Spot.OnSpotVisited()
	
func AccelerationChanged(value: float) -> void:
	ControlledShip.AccelerationChanged(value)

func AccelerationEnded(value_changed: float) -> void:
	pass # Replace with function body.

func SteerChanged(value: float) -> void:
	ControlledShip.Steer(deg_to_rad(value))
