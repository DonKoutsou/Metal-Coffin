extends Node

class_name ShipContoller

@export var ShipControllerEventH : ShipControllerEventHandler
@export var UIEventH : UIEventHandler
@export var droneDockEventHandler: DroneDockEventHandler
@export_file("*.tscn") var CptSelectSceneFile : String
@export_file("*.tscn") var DroneSceneFile : String
@export var PlayerCaptain : Captain

var AvailableShips : Array[PlayerDrivenShip] = []

static var ControlledShip : PlayerDrivenShip
static var ControlledShipVisibilityPenaltyValue : float = 1
static var ControlledShipStormValue : float = 0
static var ControlledShipPosition : Vector2

static var AutoCorrectWind : bool = true

signal FleetSeperationRequested(ControlledShip : PlayerDrivenShip)
signal LandingRequested(ControlledShip : PlayerDrivenShip)
signal OpenHatchRequested(ControlledShip : PlayerDrivenShip)

static var Instance : ShipContoller

func _ready() -> void:
	#call_deferred("SetCamera")
	
	Instance = self
	UIEventH.LandPressed.connect(_on_land_button_pressed)
	UIEventH.OpenHatchPressed.connect(OnOpenHatchPressed)
	UIEventH.RadarButtonPressed.connect(RadarButtonPressed)
	UIEventH.FleetSeparationPressed.connect(InitiateFleetSeparation)
	UIEventH.RegroupPressed.connect(RegroupPressed)
	UIEventH.AccelerationChanged.connect(SetControlledShipSpeed)
	UIEventH.ElevationChanged.connect(SetControlledShipElevation)
	UIEventH.SteerOffseted.connect(SteerChanged)
	UIEventH.WindCorrectionToggled.connect(WindCorrectionToggle)
	#UIEventH.ShipSwitchPressed.connect(ControlledShipSwitch)
	
	ShipControllerEventH.TargetPositionPicked.connect(OnTargetPositionChanged)
	ShipControllerEventH.TargetShipPicked.connect(OnTargetShipPicked)
	ShipControllerEventH.OnControlledShipChanged.connect(OnShipChanged)

	droneDockEventHandler.DroneDocked.connect(_onDroneAdded)
	droneDockEventHandler.DroneUndocked.connect(_onDroneRemoved)

func WindCorrectionToggle(t : bool) -> void:
	AutoCorrectWind = t

func _onDroneAdded(drone: PlayerDrivenShip, target: MapShip) -> void:
	if (drone == ControlledShip):
		ShipControllerEventH.ShipChanged(target)

func _onDroneRemoved(drone: PlayerDrivenShip, target: MapShip) -> void:
	if (drone == ControlledShip):
		ShipControllerEventH.ShipChanged(target)

	
func Update() -> void:
	if (ControlledShip.StormValue >= 0.9):
		UIEventH.OnStorm((ControlledShip.StormValue - 0.9) * 10)
	UpdatePlayerInfo()


static func GetInstance() -> ShipContoller:
	return Instance

func InitiateFleetSeparation() -> void:
	var Instigator = ControlledShip
	if (ControlledShip.Docked):
		Instigator = ControlledShip.Command
	FleetSeperationRequested.emit(Instigator)

func SpawnInitialShip() -> void:
	var shipScene : PackedScene = ResourceLoader.load(DroneSceneFile)
	ControlledShip = shipScene.instantiate() as PlayerDrivenShip
	ControlledShip.Cpt = PlayerCaptain
	World.GetInstance().GetMap().WorldParent.add_child(ControlledShip)

	ControlledShip.Teleported.connect(UpdatePlayerInfo)
	InventoryManager.GetInstance().AddCharacter(ControlledShip.Cpt)
	
	ControlledShip.connect("OnShipDestroyed", OnShipDestroyed)
	ControlledShip.connect("OnShipDamaged", OnShipDamaged)
	
	var dock = ControlledShip.GetDock() as PlayerDock
	
	dock.DroneAdded.connect(RefreshUI)
	dock.DroneRemoved.connect(RefreshUI)
	
	AvailableShips.append(ControlledShip)
	ControlledShip.AChanged.connect(OnControlledShipSpeedChanged)
	ControlledShip.AForced.connect(OnControlledShipSpeedForced)
	ControlledShip.SteerChanged.connect(OnControlledShipSteerChanged)
	ControlledShip.SteerForced.connect(OnControlledShipSteerForced)
	ControlledShip.AltitudeChanged.connect(OnControlledShipElevationChanged)
	ControlledShip.TargetAltitudeChanged.connect(OnControlledShipElevationForced)

	ShipControllerEventH.ShipChanged(ControlledShip)

func RegisterSelf(D : MapShip) -> void:
	AvailableShips.append(D)

	D.ToggleFuelRangeVisibility(false)
	
	

func RadarButtonPressed() -> void:
	var Instigator = ControlledShip
	if (ControlledShip.Docked):
		Instigator = ControlledShip.Command
		
	Instigator.ToggleRadar(!Instigator.RadarShape.Working)
	if (Instigator.RadarShape.Working):
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

func SetControlledShipElevation(value: float) -> void:
	var newalt = Helper.mapvalue(value, -1000, 10000)
	if (ControlledShip.Docked):
		ControlledShip.Command.SetTargetAltitude(newalt)
	else:
		ControlledShip.SetTargetAltitude(newalt)
	
		
func OnControlledShipSpeedChanged(NewSpeed : float) -> void:
	UIEventH.OnSpeedSet(NewSpeed / ControlledShip.GetShipMaxSpeed())

func OnControlledShipSpeedForced(NewSpeed : float) -> void:
	UIEventH.OnSpeedForced(NewSpeed / ControlledShip.GetShipMaxSpeed())

func OnControlledShipSteerChanged(NewSteer : float) -> void:
	UIEventH.OnSteerSet(NewSteer)

func OnControlledShipSteerForced(NewSteer : float) -> void:
	UIEventH.OnSteerForced(NewSteer)

func OnControlledShipElevationChanged(NewElevation : float) -> void:
	UIEventH.OnElevationSet(NewElevation / 10000)

func OnControlledShipElevationForced(NewElevation : float) -> void:
	UIEventH.OnElevationForced(NewElevation / 10000)

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
	#if (Sh is PlayerShip):
		#World.GetInstance().call_deferred("GameLost", "Flagship destroyed")
		#Sh.GetDock().ClearAllDrones()
		#return
	#Repartent ships commanded by defeated ship
	if (Sh.IsCommander()):
		var NewCommander : PlayerDrivenShip
		if (Sh.GetDock().GetDockedShips().size() > 0):
			NewCommander = Sh.GetDock().GetDockedShips()[0]
			Sh.GetDock().UndockShip(NewCommander)
			NewCommander.Command = null
			NewCommander.TargetLocations = Sh.TargetLocations
			NewCommander.TargetShip = Sh.TargetShip

			for DockedShip in range(Sh.GetDock().GetDockedShips().size() - 1, -1, -1):
				Sh.GetDock().UndockShip(Sh.GetDock().GetDockedShips()[DockedShip])
				NewCommander.GetDock().DockShip(Sh.GetDock().GetDockedShips()[DockedShip])

			for Captive in range(Sh.GetDock().Captives.size() - 1, -1, -1):
				if (NewCommander != null):
					Sh.GetDock().UndockCaptive(Sh.GetDock().Captives[Captive])
					NewCommander.GetDock().DockCaptive(Sh.GetDock().Captives[Captive])
				else:
					Sh.GetDock().ReleaseCaptive(Captive)

	AvailableShips.erase(Sh)
	#Game End condition
	if (AvailableShips.size() == 0):
		World.GetInstance().call_deferred("GameLost", "Flagship destroyed")
		Sh.GetDock().ClearAllDrones()
		return
	
	#If ship was being controlled, change control to new ship
	if (Sh == ControlledShip):
		if (Sh.Command != null):
			ShipControllerEventH.ShipChanged(Sh.Command)
		else:
			ShipControllerEventH.ShipChanged(AvailableShips[0])


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

func OnTargetShipPicked(Target : MapShip) -> void:
	ControlledShip.AddTargetShip(Target)
	

func OnShipChanged(NewShip : PlayerDrivenShip) -> void:
	ControlledShip.OnShipDestroyed.disconnect(OnShipDestroyed)
	ControlledShip.OnShipDamaged.disconnect(OnShipDamaged)
	ControlledShip.AChanged.disconnect(OnControlledShipSpeedChanged)
	ControlledShip.AForced.disconnect(OnControlledShipSpeedForced)
	ControlledShip.SteerChanged.disconnect(OnControlledShipSteerChanged)
	ControlledShip.SteerForced.disconnect(OnControlledShipSteerForced)
	
	NewShip.OnShipDestroyed.connect(OnShipDestroyed)
	NewShip.OnShipDamaged.connect(OnShipDamaged)
	NewShip.AChanged.connect(OnControlledShipSpeedChanged)
	NewShip.AForced.connect(OnControlledShipSpeedForced)
	NewShip.SteerChanged.connect(OnControlledShipSteerChanged)
	NewShip.SteerForced.connect(OnControlledShipSteerForced)
	
	ControlledShip.ToggleFuelRangeVisibility(false)
	ControlledShip.Teleported.disconnect(UpdatePlayerInfo)
	
	ControlledShip = NewShip
	UIEventH.OnShipUpdated(NewShip)
	NewShip.ToggleFuelRangeVisibility(true)
	FrameCamToShip()
	ControlledShip.Teleported.connect(UpdatePlayerInfo)
	#ShipControllerEventH.ShipChanged(ControlledShip)
	#ControlledShip.AChanged.connect(OnControlledShipSpeedChanged)

func UpdatePlayerInfo() -> void:
	ControlledShipPosition = ControlledShip.global_position
	ControlledShipVisibilityPenaltyValue = ControlledShip.RadarShape.VisualRangePenalty
	ControlledShipStormValue = ControlledShip.StormValue

var camtw : Tween
func FrameCamToShip():
	#if (camtw != null):
		#camtw.kill()
	#camtw = create_tween()
	#var plpos = ControlledShip.global_position
	#camtw.set_trans(Tween.TRANS_EXPO)
	#camtw.tween_property(ship_camera, "global_position", plpos, plpos.distance_to(ship_camera.global_position) / 1000)
	Map.GetInstance().GetCamera().FrameCamToShip(ControlledShip, 1, false)
	
func RegroupPressed() -> void:
	#if (ControlledShip is PlayerShip):
		#PopupManager.GetInstance().DoFadeNotif("Can't merge flagship\nwith other fleets")
		#return
	
	var ShipList = get_tree().get_nodes_in_group("PlayerShips")
	var CapList : Array[Captain]
	for Ship in ShipList:
		if (Ship.Docked or Ship == ControlledShip or Ship == ControlledShip.Command):
			continue
			
		CapList.append(Ship.Cpt)
	
	if (CapList.size() == 0):
		PopupManager.GetInstance().DoFadeNotif("No available captains\nto regroup with")
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
			#if g is PlayerShip:
				#pldata.Pos = g.global_position
				#pldata.Rot = g.global_rotation
				#pldata.PlayerFleet = g.GetDock().GetSaveData()
				#pldata.Speed = g.GetShipSpeed()
				#pldata.Altitude = g.Altitude
				#pldata.RepairParts = g.Cpt.Repair_Parts
				#pldata.TempName = g.Cpt.TempName
			#else :
			var FleetData = FleetSaveData.new()
			FleetData.CommanderData = g.GetSaveData()
			FleetData.DockedShips.append_array(g.GetDock().GetSaveData())
			pldata.FleetData.append(FleetData)
	
	return pldata

func LoadSaveData(Data : PlayerSaveData) -> void:
	var RegroupingShips : Dictionary[PlayerDrivenShip, String]
	var ShipPlecement = World.GetInstance().GetMap().WorldParent
	
	var DroneScene : PackedScene = ResourceLoader.load(DroneSceneFile)
	
	for CommandIndex in Data.FleetData.size():
		var Command = Data.FleetData[CommandIndex]
		var CommanderShip : PlayerDrivenShip
		if (CommandIndex == 0):
			CommanderShip = get_tree().get_nodes_in_group("PlayerShips")[0]
		else:
			CommanderShip = DroneScene.instantiate() as PlayerDrivenShip
			CommanderShip.Cpt = Command.CommanderData.Cpt
			ShipPlecement.add_child(CommanderShip)
		
		if (Command.CommanderData.CommingBack):
			RegroupingShips[CommanderShip] = Command.CommanderData.RegroupTargetName

		CommanderShip.Cpt.Repair_Parts = Command.CommanderData.RepairParts
		CommanderShip.Cpt.OnCharacterNameChanged(Command.CommanderData.TempName)
		
		CommanderShip.SetShipPosition(Command.CommanderData.Pos)
		CommanderShip.ForceSteer(Command.CommanderData.Rot)
		CommanderShip.SetSpeed(Command.CommanderData.Speed)
		CommanderShip.UpdateAltitude(Command.CommanderData.Altitude)
		for Ship in Command.DockedShips:
			var DockedShip = DroneScene.instantiate() as PlayerDrivenShip
			DockedShip.Cpt = Ship.Cpt
			DockedShip.Cpt.Repair_Parts = Ship.RepairParts
			DockedShip.Cpt.OnCharacterNameChanged(Ship.TempName)
			CommanderShip.GetDock().AddShip(DockedShip)
	
	var AllShips = get_tree().get_nodes_in_group("PlayerShips")
	for ToRegoup in RegroupingShips:
		for Target : PlayerDrivenShip in AllShips:
			if Target.GetShipName() == RegroupingShips[ToRegoup]:
				ToRegoup.Regroup(Target)
				break
	
	var Cam = ShipCamera.GetInstance()
	Cam.ForceZoom(Data.CameraZoom)
	Cam.ForceCamPosition(Data.CameraPos)
