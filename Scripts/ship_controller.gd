extends Node

class_name ShipContoller

@export var _Map : Map
@export var DroneDockEventH : DroneDockEventHandler
@export var ShipControllerEventH : ShipControllerEventHandler
@export var UIEventH : UIEventHandler
@onready var ship_camera: ShipCamera = $"../Map/SubViewportContainer/ViewPort/ShipCamera"
@export var HappeningUI : PackedScene

var AvailableShips : Array[MapShip] = []

var ControlledShip : MapShip

func _ready() -> void:
	DroneDockEventH.connect("DroneDocked", OnDroneDocked)
	DroneDockEventH.connect("DroneUndocked", OnDroneUnDocked)
	UIEventH.connect("LandPressed", _on_land_button_pressed)
	UIEventH.connect("RadarButtonPressed", _on_radar_button_pressed)
	UIEventH.connect("RegroupPressed", _on_controlled_ship_return_pressed)
	UIEventH.connect("AccelerationChanged", AccelerationChanged)
	UIEventH.connect("SteerOffseted", SteerChanged)
	UIEventH.connect("ShipSwitchPressed", _on_controlled_ship_swtich_range_changed)
	
	#call_deferred("SetInitialShip")
	
	
func SetInitialShip() -> void:
	ControlledShip = $"../Map/SubViewportContainer/ViewPort/PlayerShip"
	ControlledShip.connect("OnShipDestroyed", OnShipDestroyed)
	AvailableShips.append(ControlledShip)

	_Map.GetInScreenUI().GetInventory().ShipStats.SetCaptain(ControlledShip.Cpt)
	_Map.GetInScreenUI().GetInventory().AddCharacter(ControlledShip.Cpt)
	
	UIEventH.OnAccelerationForced(ControlledShip.GetShipSpeed() / ControlledShip.GetShipMaxSpeed())
	UIEventH.OnSteerDirForced(ControlledShip.GetSteer())
	UIEventH.OnShipUpdated(ControlledShip)
	
	#_Map.GetInScreenUI().GetInventory().ShipStats.UpdateValues()
	ShipControllerEventH.ShipChanged(ControlledShip)

func OnDroneDocked(D : Drone, _Target : MapShip) -> void:
	if (!AvailableShips.has(D)):
		AvailableShips.append(D)
		if (!D.is_connected("OnShipDestroyed", OnShipDestroyed)):
			D.connect("OnShipDestroyed", OnShipDestroyed)
	D.ToggleFuelRangeVisibility(false)
	if (D == ControlledShip):
		_on_controlled_ship_swtich_range_changed()
	
	
func OnDroneUnDocked(D : Drone, _Target : MapShip) -> void:
	#AvailableShips.append(D)
	#D.connect("OnShipDestroyed", OnShipDestroyed)
	#ControlledShip = D
	pass
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
	Ingame_UIManager.GetInstance().AddUI(fuel, true)
	UIEventH.OnScreenUIToggled(false)
	UIEventH.OnButtonCoverToggled(true)
func FuelTransactionFinished(BFuel : float, BRepair: float, Ship : MapShip):
	var spot = Ship.CurrentPort as MapSpot
	if (spot.PlayerFuelReserves != BFuel):
		spot.CityFuelReserves -= BFuel
	if (BFuel < 0):
		#if (Ship is PlayerShip):
			#ShipData.GetInstance().ConsumeResource("FUEL", -BFuel)
		#else:
		Ship.Cpt.RefillResource(STAT_CONST.STATS.FUEL_TANK, BFuel)

	spot.PlayerFuelReserves = max(0 , BFuel)
	spot.PlayerRepairReserves = max(0, BRepair)
	
	UIEventH.OnScreenUIToggled(true)
	#SimulationManager.GetInstance().TogglePause(false)
	UIEventH.OnButtonCoverToggled(false)
func Land(Spot : MapSpot) -> bool:
	ControlledShip.HaltShip()
	var PlayedEvent = false
	if (Spot.SpotInfo.Event != null and !Spot.Visited):
		var happeningui = HappeningUI.instantiate() as HappeningInstance
		happeningui.HappeningInstigator = ControlledShip
		Ingame_UIManager.GetInstance().AddUI(happeningui, true)
		happeningui.PresentHappening(Spot.SpotInfo.Event)
		UIEventH.OnScreenUIToggled(false)
		UIEventH.OnButtonCoverToggled(true)
		happeningui.connect("HappeningFinished", HappeningFinished)
		PlayedEvent = true
	Spot.OnSpotVisited()
	return PlayedEvent
	
func HappeningFinished() -> void:
	UIEventH.OnScreenUIToggled(true)
	UIEventH.OnButtonCoverToggled(false)
#Called from accelerator UI to change acceleration of currently controlled ship
func AccelerationChanged(value: float) -> void:
	ControlledShip.AccelerationChanged(value)
#Called from steering wheel to change tragectory of currently controlled ship
func SteerChanged(value: float) -> void:
	ControlledShip.Steer(value)

func OnShipDestroyed(Sh : MapShip):
	if (Sh is PlayerShip):
		World.GetInstance().call_deferred("GameLost", "Flagshit destroyed")
		Sh.GetDroneDock().ClearAllDrones()
		return
	var NewCommander
	if (Sh.GetDroneDock().DockedDrones.size() > 0):
		NewCommander = Sh.GetDroneDock().DockedDrones[0]
		NewCommander.Command = null
	else : if (Sh.GetDroneDock().FlyingDrones.size() > 0):
		NewCommander = Sh.GetDroneDock().FlyingDrones[0]
		NewCommander.Command = null
	var Drones = []
	Drones.append_array(Sh.GetDroneDock().DockedDrones)
	for g in Drones:
		Sh.GetDroneDock().UndockDrone(g, false)
		if (g != NewCommander):
			NewCommander.GetDroneDock().DockDrone(g)
	for g in Sh.GetDroneDock().FlyingDrones:
		if (g != NewCommander):
			g.Command = NewCommander
	AvailableShips.erase(Sh)
	if (Sh == ControlledShip):
		_on_controlled_ship_swtich_range_changed()
	

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

	
	UIEventH.OnAccelerationForced(ControlledShip.GetShipSpeed() / ControlledShip.GetShipMaxSpeed())
	UIEventH.OnSteerDirForced(ControlledShip.GetSteer())
	UIEventH.OnShipUpdated(ControlledShip)
	#_Map.GetElintUI().UpdateConnectedShip(ControlledShip)
	#_Map.GetMissileUI().UpdateConnectedShip(ControlledShip)
	#_Map.GetDroneUI().UpdateConnectedShip(ControlledShip)
	#_Map.GetThrustUI().ForceValue(ControlledShip.GetShipSpeed() / ControlledShip.GetShipMaxSpeed())
	#_Map.GetSteeringWheelUI().call_deferred("CopyShipSteer", ControlledShip)
	ControlledShip.ToggleFuelRangeVisibility(true)
	FrameCamToShip()
	_Map.GetInScreenUI().GetInventory().ShipStats.SetCaptain(ControlledShip.Cpt)
	ShipControllerEventH.ShipChanged(ControlledShip)
	
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
