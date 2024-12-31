extends Node

@export var DroneDockEventH : DroneDockEventHandler

@onready var ship_camera: ShipCamera = $"../CanvasLayer/SubViewportContainer/SubViewport/ShipCamera"
@export var HappeningUI : PackedScene

var AvailableShips : Array[MapShip] = []

var ControlledShip : MapShip

func _ready() -> void:
	DroneDockEventH.connect("DroneDocked", OnDroneDocked)
	DroneDockEventH.connect("DroneUndocked", OnDroneUnDocked)
	ControlledShip = $"../CanvasLayer/SubViewportContainer/SubViewport/PlayerShip"
	ControlledShip.connect("OnShipDestroyed", _on_controlled_ship_swtich_range_changed)
	AvailableShips.append(ControlledShip)
	$"../UI/ScreenUi/Elint".UpdateConnectedShip(ControlledShip)
	
func OnDroneDocked(D : Drone) -> void:
	AvailableShips.erase(D)
	D.disconnect("OnShipDestroyed", OnShipDestroyed)
	D.ToggleFuelRangeVisibility(false)
	if (D == ControlledShip):
		_on_controlled_ship_swtich_range_changed()
	
	
func OnDroneUnDocked(D : Drone) -> void:
	AvailableShips.append(D)
	D.connect("OnShipDestroyed", OnShipDestroyed)
	#ControlledShip = D

func _on_radar_button_pressed() -> void:
	ControlledShip.ToggleRadar()

func _on_land_button_pressed() -> void:
	var spot = ControlledShip.CurrentPort as MapSpot
	if (spot == null):
		PopUpManager.GetInstance().DoFadeNotif("No port to land to")
		return
	if (ControlledShip.Landing):
		return
	ControlledShip.StartLanding()
	ControlledShip.connect("LandingEnded", OnShipLanded)
	ControlledShip.connect("LandingCanceled", OnLandingCanceled)

func OnLandingCanceled(Ship : MapShip) -> void:
	Ship.disconnect("LandingEnded", OnShipLanded)
	Ship.disconnect("LandingCanceled", OnLandingCanceled)

func OnShipLanded(Ship : MapShip) -> void:
	Ship.disconnect("LandingEnded", OnShipLanded)
	Ship.disconnect("LandingCanceled", OnLandingCanceled)
	SimulationManager.GetInstance().TogglePause(true)
	var spot = Ship.CurrentPort as MapSpot
	var PlayedEvent = Land(spot)
	if (PlayedEvent):
		return
	var sc = spot.FuelTradeScene as PackedScene
	var fuel = sc.instantiate() as TownScene
	fuel.HasFuel = spot.HasFuel()
	fuel.HasRepair = spot.HasRepair()
	fuel.TownFuel = spot.CityFuelReserves
	fuel.BoughtFuel = spot.PlayerFuelReserves
	fuel.BoughtRepairs = spot.PlayerRepairReserves
	fuel.connect("TransactionFinished", FuelTransactionFinished)
	fuel.LandedShip = Ship
	Ingame_UIManager.GetInstance().AddUI(fuel, false, true)

func FuelTransactionFinished(BFuel : float, BRepair: float, NewCurrency : float):
	ShipData.GetInstance().SetStatValue("FUNDS", NewCurrency)
	var spot = ControlledShip.CurrentPort as MapSpot
	if (spot.PlayerFuelReserves != BFuel):
		spot.CityFuelReserves -= BFuel
	if (BFuel < 0):
		if (ControlledShip is PlayerShip):
			ShipData.GetInstance().ConsumeResource("FUEL", -BFuel)
		else:
			ControlledShip.Fuel -= -BFuel

	spot.PlayerFuelReserves = max(0 , BFuel)
	spot.PlayerRepairReserves = max(0, BRepair)
	
	#SimulationManager.GetInstance().TogglePause(false)

func Land(Spot : MapSpot) -> bool:
	var PlayedEvent = false
	if (Spot.SpotInfo.Event != null and !Spot.Visited):
		var happeningui = HappeningUI.instantiate() as HappeningInstance
		Ingame_UIManager.GetInstance().AddUI(happeningui, false, true)
		happeningui.PresentHappening(Spot.SpotInfo.Event)
		PlayedEvent = true
	Spot.OnSpotVisited()
	return PlayedEvent
	
#Called from accelerator UI to change acceleration of currently controlled ship
func AccelerationChanged(value: float) -> void:
	ControlledShip.AccelerationChanged(value)
#Called from steering wheel to change tragectory of currently controlled ship
func SteerChanged(value: float) -> void:
	ControlledShip.Steer(deg_to_rad(value))

func OnShipDestroyed(Sh : MapShip):
	if (Sh == ControlledShip):
		_on_controlled_ship_swtich_range_changed()
	AvailableShips.erase(Sh)

func _on_controlled_ship_swtich_range_changed() -> void:
	var currentcontrolled = AvailableShips.find(ControlledShip)
	#ControlledShip.disconnect("OnShipDestroyed", OnShipDestroyed)
	if (currentcontrolled + 1 > AvailableShips.size() - 1):
		var newcont = 0
		if (newcont == currentcontrolled):
			return
		ControlledShip.ToggleFuelRangeVisibility(false)
		ControlledShip = AvailableShips[newcont]
	else:
		ControlledShip.ToggleFuelRangeVisibility(false)
		ControlledShip = AvailableShips[currentcontrolled + 1]
	#ControlledShip.connect("OnShipDestroyed", OnShipDestroyed)
	$"../UI/ScreenUi/ThrustSlider".ForceValue(ControlledShip.GetShipSpeed() / ControlledShip.GetShipMaxSpeed())
	$"../UI/ScreenUi/SteeringWheel".ForceSteer(ControlledShip.GetSteer())
	ControlledShip.ToggleFuelRangeVisibility(true)
	FrameCamToShip()
	$"../UI/ScreenUi/Elint".UpdateConnectedShip(ControlledShip)

var camtw : Tween
func FrameCamToShip():
	if (camtw != null):
		camtw.kill()
	camtw = create_tween()
	var plpos = ControlledShip.global_position
	camtw.set_trans(Tween.TRANS_EXPO)
	camtw.tween_property(ship_camera, "global_position", plpos, plpos.distance_to(ship_camera.global_position) / 1000)


func _on_controlled_ship_return_pressed() -> void:
	if (ControlledShip is Drone and !ControlledShip.CommingBack):
		ControlledShip.ReturnToBase()
