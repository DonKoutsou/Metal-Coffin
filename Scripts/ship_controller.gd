extends Node

class_name ShipContoller

@export var ShipControllerEventH : ShipControllerEventHandler
@export var UIEventH : UIEventHandler

@export_file("*.tscn") var CptSelectSceneFile : String
@export_file("*.tscn") var DroneSceneFile : String

var ship_camera: ShipCamera

var AvailableShips : Array[PlayerDrivenShip] = []

static var ControlledShip : PlayerDrivenShip
static var ControlledShipVisibilityValue : float = 1
static var ControlledShipPosition : Vector2

signal FleetSeperationRequested(ControlledShip : PlayerDrivenShip)
signal LandingRequested(ControlledShip : PlayerDrivenShip)
signal OpenHatchRequested(ControlledShip : PlayerDrivenShip)

static var Instance : ShipContoller

func _ready() -> void:
	call_deferred("SetCamera")
	
	Instance = self
	UIEventH.LandPressed.connect(_on_land_button_pressed)
	UIEventH.OpenHatchPressed.connect(OnOpenHatchPressed)
	UIEventH.RadarButtonPressed.connect(RadarButtonPressed)
	UIEventH.FleetSeparationPressed.connect(InitiateFleetSeparation)
	UIEventH.RegroupPressed.connect(RegroupPressed)
	UIEventH.AccelerationChanged.connect(SetControlledShipSpeed)
	UIEventH.SteerOffseted.connect(SteerChanged)
	#UIEventH.ShipSwitchPressed.connect(ControlledShipSwitch)
	
	ShipControllerEventH.TargetPositionPicked.connect(OnTargetPositionChanged)
	ShipControllerEventH.OnControlledShipChanged.connect(OnShipChanged)

	
func Update(_delta: float) -> void:
	if (ControlledShip.StormValue >= 0.9):
		UIEventH.OnStorm((ControlledShip.StormValue - 0.9) * 10)
	if (SimulationManager.IsPaused()):
		return
	ControlledShipPosition = ControlledShip.global_position
	ControlledShipVisibilityValue = ControlledShip.VisibilityValue

func SetCamera() -> void:
	ship_camera = Map.GetInstance().GetCamera()

static func GetInstance() -> ShipContoller:
	return Instance

func InitiateFleetSeparation() -> void:
	var Instigator = ControlledShip
	if (ControlledShip.Docked):
		Instigator = ControlledShip.Command
	FleetSeperationRequested.emit(Instigator)
	
func SetInitialShip() -> void:
	ControlledShip = get_tree().get_nodes_in_group("PlayerShips")[0]
	
	InventoryManager.GetInstance().AddCharacter(ControlledShip.Cpt)
	
	ControlledShip.connect("OnShipDestroyed", OnShipDestroyed)
	ControlledShip.connect("OnShipDamaged", OnShipDamaged)
	
	var dock = ControlledShip.GetDroneDock() as DroneDock
	
	dock.DroneAdded.connect(RefreshUI)
	dock.DroneRemoved.connect(RefreshUI)
	
	AvailableShips.append(ControlledShip)
	ControlledShip.AChanged.connect(OnControlledShipSpeedChanged)
	ControlledShip.AForced.connect(OnControlledShipSpeedForced)
	UIEventH.OnShipUpdated(ControlledShip)

	ShipControllerEventH.ShipChanged(ControlledShip)

func RegisterSelf(D : MapShip) -> void:
	AvailableShips.append(D)

	D.ToggleFuelRangeVisibility(false)
	
	D.OnShipDestroyed.connect(OnShipDestroyed)
	D.OnShipDamaged.connect(OnShipDamaged)
	D.AChanged.connect(OnControlledShipSpeedChanged)
	D.AForced.connect(OnControlledShipSpeedForced)

func RadarButtonPressed() -> void:
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

func OnOpenHatchPressed() -> void:
	var Instigator = ControlledShip
	if (ControlledShip.Docked):
		Instigator = ControlledShip.Command
	
	OpenHatchRequested.emit(Instigator)

#Called from accelerator UI to change acceleration of currently controlled ship
func SetControlledShipSpeed(value: float) -> void:
	if (ControlledShip.Docked):
		ControlledShip.Command.AccelerationChanged(value, false)
	else:
		ControlledShip.AccelerationChanged(value, false)

func OnControlledShipSpeedChanged(NewSpeed : float) -> void:
	UIEventH.OnSpeedSet(NewSpeed / ControlledShip.GetShipMaxSpeed())

func OnControlledShipSpeedForced(NewSpeed : float) -> void:
	UIEventH.OnSpeedForced(NewSpeed / ControlledShip.GetShipMaxSpeed())

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

func RefreshUI() -> void:
	UIEventH.call_deferred("OnShipUpdated",ControlledShip)

func OnShipDestroyed(Sh : PlayerDrivenShip):
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
		if (Sh.Command != null):
			OnShipChanged(Sh.Command)
		else:
			OnShipChanged(AvailableShips[0])

func OnTargetPositionChanged(Pos : Vector2, Add : bool) -> void:
	if (ControlledShip.Command != null):
		if (Add):
			ControlledShip.Command.AddTargetLocation(Pos)
		else:
			ControlledShip.Command.SetTargetLocation(Pos)
	else:
		if (Add):
			ControlledShip.AddTargetLocation(Pos)
		else:
			ControlledShip.SetTargetLocation(Pos)

func OnShipChanged(NewShip : PlayerDrivenShip) -> void:
	ControlledShip.ToggleFuelRangeVisibility(false)
	ControlledShip = NewShip
	UIEventH.OnShipUpdated(NewShip)
	NewShip.ToggleFuelRangeVisibility(true)
	FrameCamToShip()
	#ControlledShip.AChanged.connect(OnControlledShipSpeedChanged)
	

var camtw : Tween
func FrameCamToShip():
	#if (camtw != null):
		#camtw.kill()
	#camtw = create_tween()
	#var plpos = ControlledShip.global_position
	#camtw.set_trans(Tween.TRANS_EXPO)
	#camtw.tween_property(ship_camera, "global_position", plpos, plpos.distance_to(ship_camera.global_position) / 1000)
	ship_camera.FrameCamToShip(ControlledShip, 1, false)
	
func RegroupPressed() -> void:
	
	if (ControlledShip is PlayerShip):
		PopupManager.GetInstance().DoFadeNotif("Can't merge flagship with other fleets")
		return
	
	var ShipList = get_tree().get_nodes_in_group("PlayerShips")
	var CapList : Array[Captain]
	for Ship in ShipList:
		if (Ship.Docked or Ship == ControlledShip or Ship == ControlledShip.Command):
			continue
			
		CapList.append(Ship.Cpt)
	
	if (CapList.size() == 0):
		PopupManager.GetInstance().DoFadeNotif("No available captains to regroup with")
		return
	
	var CaptainSelectScreen : PackedScene = ResourceLoader.load(CptSelectSceneFile)
	var CaptainSelect = CaptainSelectScreen.instantiate() as ItemTransfer
	CaptainSelect.SetData(CapList, "Choose Fleet to Regroup With")
	
	Ingame_UIManager.GetInstance().AddUI(CaptainSelect)
	
	await CaptainSelect.CharacterSelected
	if (CaptainSelect.SelectedCharacter != null):
		ControlledShip.Regroup(CaptainSelect.SelectedCharacter.CaptainShip)
			
func GetSaveData() -> PlayerSaveData:
	var pldata = PlayerSaveData.new()
	var Ships = get_tree().get_nodes_in_group("PlayerShips")
	var Cam = ShipCamera.GetInstance()
	pldata.CameraPos = Cam.global_position
	pldata.CameraZoom = Cam.zoom
	
	#pldata.Worldview = WorldView.GetInstance().GetSaveData()
	for g : PlayerDrivenShip in Ships:
		if (g.Command == null):
			if g is PlayerShip:
				pldata.Pos = g.global_position
				pldata.Rot = g.global_rotation
				pldata.PlayerFleet = g.GetDroneDock().GetSaveData()
				pldata.Speed = g.GetShipSpeed()
				pldata.Altitude = g.Altitude
				pldata.RepairParts = g.Cpt.Repair_Parts
				pldata.TempName = g.Cpt.TempName
			else :
				var FleetData = FleetSaveData.new()
				if (g is Drone):
					FleetData.CommanderData = g.GetSaveData()
				FleetData.DockedShips.append_array(g.GetDroneDock().GetSaveData())
				pldata.FleetData.append(FleetData)
	
	return pldata

func LoadSaveData(Data : PlayerSaveData) -> void:
	var Player = get_tree().get_nodes_in_group("PlayerShips")[0] as PlayerShip
	Player.SetShipPosition(Data.Pos)
	Player.ForceSteer(Data.Rot)
	Player.Cpt.Repair_Parts = Data.RepairParts
	Player.Cpt.OnCharacterNameChanged(Data.TempName)
	#WorldView.GetInstance().LoadData(Data.Worldview)
	for Ship in Data.PlayerFleet:
		var DroneScene : PackedScene = ResourceLoader.load(DroneSceneFile)
		var DockedShip = DroneScene.instantiate() as Drone
		DockedShip.Cpt = Ship.Cpt
		DockedShip.Cpt.Repair_Parts = Ship.RepairParts
		DockedShip.Cpt.OnCharacterNameChanged(Ship.TempName)
		Player.GetDroneDock().AddDrone(DockedShip)
	Player.SetSpeed(Data.Speed)
	Player.UpdateAltitude(Data.Altitude)
	var ShipPlecement = Player.get_parent()
	
	var RegroupingShips : Dictionary[Drone, String]
	
	for Command in Data.FleetData:
		var DroneScene : PackedScene = ResourceLoader.load(DroneSceneFile)
		var CommanderShip = DroneScene.instantiate() as Drone
		
		if (Command.CommanderData.CommingBack):
			RegroupingShips[CommanderShip] = Command.CommanderData.RegroupTargetName

		CommanderShip.Cpt = Command.CommanderData.Cpt
		CommanderShip.Cpt.Repair_Parts = Command.CommanderData.RepairParts
		CommanderShip.Cpt.OnCharacterNameChanged(Command.CommanderData.TempName)
		ShipPlecement.add_child(CommanderShip)
		CommanderShip.SetShipPosition(Command.CommanderData.Pos)
		CommanderShip.ForceSteer(Command.CommanderData.Rot)
		CommanderShip.SetSpeed(Command.CommanderData.Speed)
		CommanderShip.UpdateAltitude(Command.CommanderData.Altitude)
		for Ship in Command.DockedShips:
			var DockedShip = DroneScene.instantiate() as Drone
			DockedShip.Cpt = Ship.Cpt
			DockedShip.Cpt.Repair_Parts = Ship.RepairParts
			DockedShip.Cpt.OnCharacterNameChanged(Ship.TempName)
			CommanderShip.GetDroneDock().AddDrone(DockedShip)
	
	var AllShips = get_tree().get_nodes_in_group("PlayerShips")
	for ToRegoup in RegroupingShips:
		for Target : PlayerDrivenShip in AllShips:
			if Target.GetShipName() == RegroupingShips[ToRegoup]:
				ToRegoup.Regroup(Target)
				break
	
	var Cam = ShipCamera.GetInstance()
	Cam.ForceZoom(Data.CameraZoom)
	Cam.ForceCamPosition(Data.CameraPos)
