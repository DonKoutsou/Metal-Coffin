extends Node

class_name ShipContoller

@export var _Map : Map
@export var DroneDockEventH : DroneDockEventHandler
@export var ShipControllerEventH : ShipControllerEventHandler
@export var UIEventH : UIEventHandler
@onready var ship_camera: ShipCamera = $"../Map/SubViewportContainer/ViewPort/ShipCamera"

var AvailableShips : Array[MapShip] = []

var ControlledShip : MapShip

signal FleetSeperationRequested(ControlledShip : MapShip)
signal LandingRequested(ControlledShip : MapShip)

func _ready() -> void:
	DroneDockEventH.connect("DroneDocked", OnDroneDocked)
	DroneDockEventH.connect("DroneUndocked", OnDroneUnDocked)
	UIEventH.connect("LandPressed", _on_land_button_pressed)
	UIEventH.connect("RadarButtonPressed", _on_radar_button_pressed)
	UIEventH.connect("FleetSeparationPressed", InitiateFleetSeparation)
	UIEventH.connect("RegroupPressed", _on_controlled_ship_return_pressed)
	UIEventH.connect("AccelerationChanged", AccelerationChanged)
	UIEventH.connect("SteerOffseted", SteerChanged)
	UIEventH.connect("ShipSwitchPressed", _on_controlled_ship_swtich_range_changed)
	
	#call_deferred("SetInitialShip")

func InitiateFleetSeparation() -> void:
	var Instigator = ControlledShip
	if (ControlledShip.Docked):
		Instigator = ControlledShip.Command
	FleetSeperationRequested.emit(Instigator)
	
func SetInitialShip() -> void:
	ControlledShip = $"../Map/SubViewportContainer/ViewPort/PlayerShip"
	
	ControlledShip.connect("OnShipDestroyed", OnShipDestroyed)
	ControlledShip.connect("OnShipDamaged", OnShipDamaged)
	AvailableShips.append(ControlledShip)

	_Map.GetInScreenUI().GetInventory().ShipStats.SetCaptain(ControlledShip.Cpt)
	_Map.GetInScreenUI().GetInventory().AddCharacter(ControlledShip.Cpt)
	
	UIEventH.OnAccelerationForced(ControlledShip.GetShipSpeed() / ControlledShip.GetShipMaxSpeed())
	UIEventH.OnSteerDirForced(ControlledShip.rotation)
	UIEventH.OnShipUpdated(ControlledShip)

	ShipControllerEventH.ShipChanged(ControlledShip)

func OnDroneDocked(D : Drone, Target : MapShip) -> void:
	if (!AvailableShips.has(D)):
		AvailableShips.append(D)
		if (!D.is_connected("OnShipDestroyed", OnShipDestroyed)):
			D.connect("OnShipDestroyed", OnShipDestroyed)
	D.ToggleFuelRangeVisibility(false)
	if (D == ControlledShip):
		_on_controlled_ship_swtich_range_changed()
	
	#Max speed of a ship can change when a slower ship joins the fleet, so update speed
	Target.AccelerationChanged(Target.GetShipSpeed() / Target.GetShipMaxSpeed())
	
func OnDroneUnDocked(_D : Drone, _Target : MapShip) -> void:
	#AvailableShips.append(D)
	#D.connect("OnShipDestroyed", OnShipDestroyed)
	#ControlledShip = D
	pass
func _on_radar_button_pressed() -> void:
	var Instigator = ControlledShip
	if (ControlledShip.Docked):
		Instigator = ControlledShip.Command
		
	Instigator.ToggleRadar()
	if (Instigator.RadarWorking):
		PopUpManager.GetInstance().DoFadeNotif("Radar turned on")
	else:
		PopUpManager.GetInstance().DoFadeNotif("Radar turned off")
		
func _on_land_button_pressed() -> void:
	var Instigator = ControlledShip
	if (ControlledShip.Docked):
		Instigator = ControlledShip.Command
	
	LandingRequested.emit(Instigator)
	
#Called from accelerator UI to change acceleration of currently controlled ship
func AccelerationChanged(value: float) -> void:
	if (ControlledShip.Docked):
		ControlledShip.Command.AccelerationChanged(value)
	else:
		ControlledShip.AccelerationChanged(value)
#Called from steering wheel to change tragectory of currently controlled ship
func SteerChanged(value: float) -> void:
	if (ControlledShip.Docked):
		ControlledShip.Command.Steer(value)
	else:
		ControlledShip.Steer(value)

func OnShipDamaged(Amm : float, ShowVisuals : bool) -> void:
	if (ShowVisuals):
		UIEventH.OnControlledShipDamaged(Amm)
		RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.DAMAGED)

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
			PopUpManager.GetInstance().DoFadeNotif("No ship to switch to")
			return
		ControlledShip.ToggleFuelRangeVisibility(false)
		ControlledShip = AvailableShips[newcont]
	else:
		ControlledShip.ToggleFuelRangeVisibility(false)
		ControlledShip = AvailableShips[currentcontrolled + 1]
	#ControlledShip.connect("OnShipDestroyed", OnShipDestroyed)

	
	UIEventH.OnAccelerationForced(ControlledShip.GetShipSpeed() / ControlledShip.GetShipMaxSpeed())
	UIEventH.OnSteerDirForced(ControlledShip.rotation)
	UIEventH.OnShipUpdated(ControlledShip)
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
