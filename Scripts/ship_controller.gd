extends Node

class_name ShipContoller

@export var _Map : Map
@export var DroneDockEventH : DroneDockEventHandler
@export var ShipControllerEventH : ShipControllerEventHandler
@export var UIEventH : UIEventHandler
@onready var ship_camera: ShipCamera = $"../Map/SubViewportContainer/ViewPort/ShipCamera"
@export var CaptainSelectScreen : PackedScene
@export var DroneScene : PackedScene

var AvailableShips : Array[MapShip] = []

var ControlledShip : MapShip

signal FleetSeperationRequested(ControlledShip : MapShip)
signal LandingRequested(ControlledShip : MapShip)

static var Instance : ShipContoller

func _ready() -> void:
	Instance = self
	#DroneDockEventH.connect("DroneDocked", OnDroneDocked)
	#DroneDockEventH.connect("DroneUndocked", OnDroneUnDocked)
	UIEventH.connect("LandPressed", _on_land_button_pressed)
	UIEventH.connect("RadarButtonPressed", _on_radar_button_pressed)
	UIEventH.connect("FleetSeparationPressed", InitiateFleetSeparation)
	UIEventH.connect("RegroupPressed", _on_controlled_ship_return_pressed)
	UIEventH.connect("AccelerationChanged", AccelerationChanged)
	UIEventH.connect("SteerOffseted", SteerChanged)
	UIEventH.connect("ShipSwitchPressed", _on_controlled_ship_swtich_range_changed)
	
	#call_deferred("SetInitialShip")

static func GetInstance() -> ShipContoller:
	return Instance

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

	_Map.GetInScreenUI().GetInventory().AddCharacter(ControlledShip.Cpt)
	
	UIEventH.OnShipUpdated(ControlledShip)

	ShipControllerEventH.ShipChanged(ControlledShip)

func RegisterSelf(D : MapShip) -> void:
	AvailableShips.append(D)

	D.ToggleFuelRangeVisibility(false)
	D.connect("OnShipDestroyed", OnShipDestroyed)

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
		World.GetInstance().call_deferred("GameLost", "Flagship destroyed")
		Sh.GetDroneDock().ClearAllDrones()
		return
	var NewCommander
	if (Sh.GetDroneDock().DockedDrones.size() > 0):
		NewCommander = Sh.GetDroneDock().DockedDrones[0]
		Sh.GetDroneDock().UndockDrone(NewCommander)
		NewCommander.Command = null

	for DockedShip in range(Sh.GetDroneDock().DockedDrones.size() - 1, -1, -1):
		Sh.GetDroneDock().UndockDrone(Sh.GetDroneDock().DockedDrones[DockedShip])
		NewCommander.GetDroneDock().DockDrone(Sh.GetDroneDock().DockedDrones[DockedShip])

	for Captive in range(Sh.GetDroneDock().Captives.size() - 1, -1, -1):
		if (NewCommander != null):
			Sh.GetDroneDock().UndockCaptive(Sh.GetDroneDock().Captives[Captive])
			NewCommander.GetDroneDock().DockCaptive(Sh.GetDroneDock().Captives[Captive])
		else:
			Sh.GetDroneDock().ReleaseCaptive(Captive)

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

	
	#UIEventH.OnAccelerationForced(ControlledShip.GetShipSpeed() / ControlledShip.GetShipMaxSpeed())
	#UIEventH.OnSteerDirForced(ControlledShip.rotation)
	UIEventH.OnShipUpdated(ControlledShip)
	ControlledShip.ToggleFuelRangeVisibility(true)
	FrameCamToShip()
	#_Map.GetInScreenUI().GetInventory().ShipStats.SetCaptain(ControlledShip.Cpt)
	ShipControllerEventH.ShipChanged(ControlledShip)
	
var camtw : Tween
func FrameCamToShip():
	#if (camtw != null):
		#camtw.kill()
	#camtw = create_tween()
	#var plpos = ControlledShip.global_position
	#camtw.set_trans(Tween.TRANS_EXPO)
	#camtw.tween_property(ship_camera, "global_position", plpos, plpos.distance_to(ship_camera.global_position) / 1000)
	ship_camera.FrameCamToPos(ControlledShip.global_position)
func _on_controlled_ship_return_pressed() -> void:
	if (ControlledShip is Drone and !ControlledShip.CommingBack):
		var CaptainSelect = CaptainSelectScreen.instantiate() as ItemTransfer
		
		var ShipList = get_tree().get_nodes_in_group("PlayerShips")
		var CapList : Array[Captain]
		for g in range(ShipList.size() - 1, -1, -1):
			if (ShipList[g].Docked or ShipList[g] == ControlledShip):
				ShipList.remove_at(g)
				continue
				
			CapList.append(ShipList[g].Cpt)
		
		CaptainSelect.SetData(CapList, "Choose Fleet to Regroup With")
		
		Ingame_UIManager.GetInstance().AddUI(CaptainSelect)
		
		await CaptainSelect.CharacterSelected
		if (CaptainSelect.SelectedCharacter != null):
			ControlledShip.Regroup(CaptainSelect.SelectedCharacter.CaptainShip)

func GetSaveData() -> PlayerSaveData:
	var pldata = PlayerSaveData.new()
	var Ships = get_tree().get_nodes_in_group("PlayerShips")
	
	for g : MapShip in Ships:
		if (g.Command == null):
			if g is PlayerShip:
				pldata.Pos = g.global_position
				pldata.PlayerFleet = g.GetDroneDock().GetSaveData()
			else :
				var FleetData = FleetSaveData.new()
				if (g is Drone):
					FleetData.CommanderData = g.GetSaveData()
				FleetData.DockedShips.append_array(g.GetDroneDock().GetSaveData())
				pldata.FleetData.append(FleetData)
	
	return pldata

func LoadSaveData(Data : PlayerSaveData) -> void:
	var Player = get_tree().get_nodes_in_group("PlayerShips")[0] as PlayerShip
	Player.global_position = Data.Pos
	for Ship in Data.PlayerFleet:
		var DockedShip = DroneScene.instantiate() as Drone
		DockedShip.Cpt = Ship.Cpt
		Player.GetDroneDock().AddDrone(DockedShip)
	
	var ShipPlecement = Player.get_parent()
	
	for Command in Data.FleetData:
		var CommanderShip = DroneScene.instantiate() as Drone
		CommanderShip.Cpt = Command.CommanderData.Cpt
		ShipPlecement.add_child(CommanderShip)
		CommanderShip.global_position = Command.CommanderData.Pos
		CommanderShip.global_rotation = Command.CommanderData.Rot
		for Ship in Command.DockedShips:
			var DockedShip = DroneScene.instantiate() as Drone
			DockedShip.Cpt = Ship.Cpt
			CommanderShip.GetDroneDock().AddDrone(DockedShip)
