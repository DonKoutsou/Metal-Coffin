extends CanvasLayer
#/////////////////////////////////////////////////////////////
#███    ███  █████  ██████  
#████  ████ ██   ██ ██   ██ 
#██ ████ ██ ███████ ██████  
#██  ██  ██ ██   ██ ██      
#██      ██ ██   ██ ██      
#/////////////////////////////////////////////////////////////
#Map contains all the game. Here everything is generated from the town plecement to the enemy spawing.

#/////////////////////////////////////////////////////////////
class_name Map
@export_group("Nodes")
@export var _InScreenUI : Ingame_UIManager
@export var _ScreenUI : ScreenUI
@export var _Camera : ShipCamera
@export var MapLines : Node2D
@export var MapSpots : Node2D
@export var Region : RegionLineDrawer
@export var Road : MapLineDrawer
@export var MapLine : MapLineDrawer
@export var WeatherMan : WeatherManage
@export var WorldParent : Node
@export var MapPointerMan : MapPointerManager
#@export var _StatPanel : StatPanel
@export_group("Map Generation")
@export var TownSpotScene : PackedScene
@export var EnemyScene : PackedScene
@export var TutorialTrigger : PackedScene

@export_file("*.tres") var VillageType : String
@export_file("*.tres") var CityType : String
@export_file("*.tres") var CapitalType : String
@export_file("*.tres") var FinalCityType : String

@export_file("*.tres") var EnemyShipNameList : String
#@export var MapGenerationDistanceCurve : Curve
@export var MapSize : int
@export var VillageAmm : int
@export var CapitalAmm : int = 3
@export var MinDistance : float = 3000
@export var SpawningBounds : Vector2
@export var EnSpawner : SpawnDecider
@export var ControllerEvH : ShipControllerEventHandler
@export var UIEventH : UIEventHandler


signal MAP_EnemyArrival(FriendlyShips : Array[MapShip] , EnemyShips : Array[MapShip], Missiles : Array[Missile])
#Signal called when all cities have their neighbors configured
signal MAP_NeighborsSet
signal GenerationFinished

var M : Mutex
var TempEnemyNames: PackedStringArray
var SpotList : Array[Town]
var ShowingTutorial = false

enum UI_ELEMENT{
	PILOT_SIMULATION_BUTTON,
	PILOT_SIMULATION_SPEED_BUTTON,
	PILOT_MAP_MARKER_TOGGLE,
	CARD_FIGHT_ENERGY_BAR,
	CARD_FIGHT_RESERVE_BAR,
}

func GetUIElement(Element : UI_ELEMENT) -> Control:
	match(Element):
		UI_ELEMENT.PILOT_SIMULATION_BUTTON:
			return _ScreenUI.PilotScreen.GetUIElement(PilotScreenUI.PILOT_UI_ELEMENTS.SIMULATION_BUTTON)
		UI_ELEMENT.PILOT_SIMULATION_SPEED_BUTTON:
			return _ScreenUI.PilotScreen.GetUIElement(PilotScreenUI.PILOT_UI_ELEMENTS.SPEED_SIMULATION_BUTTON)
		UI_ELEMENT.PILOT_MAP_MARKER_TOGGLE:
			return _ScreenUI.PilotScreen.GetUIElement(PilotScreenUI.PILOT_UI_ELEMENTS.MAP_MARKER_TOGGLE)
		UI_ELEMENT.CARD_FIGHT_ENERGY_BAR:
			return _ScreenUI.CardFightUI.GetEnergyBar()
		UI_ELEMENT.CARD_FIGHT_RESERVE_BAR:
			return _ScreenUI.CardFightUI.GetReserveBar()
	return null
	
static var Instance : Map

static func GetInstance() -> Map:
	return Instance

func _enter_tree() -> void:
	Instance = self

func _ready() -> void:
	set_physics_process(false)
	$SubViewportContainer.visible = false
	_ScreenUI.connect("FullScreenToggleStarted", ToggleFullScreen)
	_Camera.connect("PositionChanged", CamPosChanged)
	_Camera.connect("ZoomChanged", CamZoomChanged)
	_InScreenUI.GetInventory().InventoryToggled.connect(HideWorld)
	MapPointerMan.TargetSelected.connect(MoveTargetSelected)
	MapPointerMan.TargetSpotSelected.connect(MoveTargetSpotSelected)

func HideWorld(t : bool) -> void:
	WorldParent.get_parent().visible = t

func _exit_tree() -> void:
	if (Roadt != null):
		Roadt.wait_to_finish()
	if (Maplt != null):
		Maplt.wait_to_finish()


func _InitialPlayerPlacament(StartingFuel : float, IsPrologue : bool = false):
	#find first village and make sure its visible
	var firstvilage = get_tree().get_nodes_in_group("VILLAGE")[0] as MapSpot
	firstvilage.OnSpotSeen(false)
	#place player close to first village
	var pos = firstvilage.global_position
	pos.y += 500
	var PlShip = $SubViewportContainer/ViewPort/SubViewportContainer/SubViewport/PlayerShip as MapShip
	PlShip.SetShipPosition(pos)
	#_Camera.FrameCamToPlayer()
	PlShip.ShipLookAt(firstvilage.global_position)
	PlShip.Cpt._GetStat(STAT_CONST.STATS.FUEL_TANK).ConsumeResource(PlShip.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK) - StartingFuel)
	if (IsPrologue):
		for g in PlShip.Cpt.ProvidingCaptains:
			PlShip.GetDroneDock().AddRecruit(g, false)
			g._GetStat(STAT_CONST.STATS.FUEL_TANK).ConsumeResource(g.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK) - StartingFuel)
	
	var SimulationTrigger = TutorialTrigger.instantiate() as TutTrigger
	SimulationTrigger.Inscreen = false
	SimulationTrigger.TutorialToShow = ActionTracker.Action.SIMULATION
	SimulationTrigger.TutorialTitle = "Simulation Management"
	SimulationTrigger.TutorialText = "A successfull campaign requires proper planning.\nUse the [color=#ffc315]Simulation Buttons[/color] to either [color=#f35033]Stop[/color] the simulation and think over your plans or speed up the simulations to [color=#308a4d]speed[/color] through big protions of your voyage."
	#TODO fix this
	SimulationTrigger.TutorialElement.append(Map.UI_ELEMENT.PILOT_SIMULATION_BUTTON)
	WorldParent.add_child(SimulationTrigger)
	var triggerpos = pos
	triggerpos.y -= 100
	SimulationTrigger.global_position = triggerpos
	
	var MapMarkerTrigger = TutorialTrigger.instantiate() as TutTrigger
	MapMarkerTrigger.Inscreen = false
	MapMarkerTrigger.TutorialToShow = ActionTracker.Action.MAP_MARKER
	MapMarkerTrigger.TutorialTitle = "Map Markers"
	MapMarkerTrigger.TutorialText = "Marking vital information on the map is usefull for making edjucated decisions in the future. Use the [color=#ffc315]Map Marker Editor[/color] to place text markers and measure distances. Toggle the [color=#ffc315]Map Marker Editor[/color] using the dediacted button on the [color=#ffc315]Ship Controller[/color]."
	#TODO fix this
	MapMarkerTrigger.TutorialElement.append(Map.UI_ELEMENT.PILOT_MAP_MARKER_TOGGLE)
	WorldParent.add_child(MapMarkerTrigger)
	var MapMarkerTriggerpos = pos
	MapMarkerTriggerpos.y -= 750
	MapMarkerTrigger.global_position = MapMarkerTriggerpos
	

#Called when enemy ship touches friendly one to strart a fight
func EnemyMet(FriendlyShips : Array[MapShip] , EnemyShips : Array[MapShip], Missiles : Array[BattleShipStats]):
	MAP_EnemyArrival.emit(FriendlyShips, EnemyShips, Missiles)

func ScreenControls(t : bool) -> void:
	$OuterUI/ButtonCover.visible = !t

func GetMapMarkerEditor() -> MapMarkerEditor:
	return GetInScreenUI().GetMapMarkerEditor()
	
func GetInScreenUI() -> Ingame_UIManager:
	return _InScreenUI

func GetScreenUi() -> ScreenUI:
	return _ScreenUI
	
func GetCamera() -> ShipCamera:
	return _Camera

#CAMERA DATA
static var CamZoom : float = 1
static var CamPos : Vector2 = Vector2.ZERO

func CamPosChanged(NewPos : Vector2) -> void:
	CamPos = NewPos

func CamZoomChanged(NewZoom : float) -> void:
	CamZoom = NewZoom

static func GetCameraPosition() -> Vector2:
	return CamPos

static func GetCameraZoom() -> float:
	return CamZoom

#CALLED BY WORLD AFTER STAGE IS FINISHED AND WE HAVE REACHED THE NEW PLANET
func Arrival(Spot : MapSpot) -> void:
	var PlayerShips : Array[MapShip]
	var HostileShips : Array[MapShip]
	var Convoys : Array[MapShip]
	
	#TODO find better way for this
	for Ship in Spot.VisitingShips:
		if (!PlayerShips.has(Ship)):
			PlayerShips.append(Ship)
			if (Ship.Command == null):
				for Docked in Ship.GetDroneDock().GetDockedShips():
					if (Docked is MapShip and !PlayerShips.has(Docked)):
						PlayerShips.append(Docked)
					else: if (Docked is HostileShip and !HostileShips.has(Docked)):
						HostileShips.append(Docked)
						Convoys.append(Docked)
	for Ship in Spot.VisitingHostiles:
		if (!HostileShips.has(Ship)):
			HostileShips.append(Ship)
			if (Ship.Convoy):
				Convoys.append(Ship)
			if (Ship.Command == null):
				for Docked in Ship.GetDroneDock().GetDockedShips():
					if (!HostileShips.has(Docked)):
						HostileShips.append(Docked)
					if (Docked.Convoy):
						Convoys.append(Docked)
	
	var StartFight : bool = false
	
	if (PlayerShips.size() > 0 and HostileShips.size() > 0):
		for g in HostileShips:
			if (g.Convoy == false):
				StartFight = true
				break
	
	if (StartFight):
		EnemyMet(PlayerShips, HostileShips, [])
	#else:
		#for g in Convoys:
			#g.Command.GetDroneDock().UndockCaptive(g)
			#World.GetInstance().PlayerWallet.AddFunds(g.Cpt.ProvidingFunds * 2)
			#g.Evaporate()
	#var plships : Array[Node2D] = []
	#var hostships : Array[Node2D] = []
	#if (Docked):
		#hostships.append(Command)
		#hostships.append_array(Command.GetDroneDock().DockedDrones)
	#else:
		#hostships.append(self)
		#hostships.append_array(GetDroneDock().DockedDrones)
		#
	#if (Body.get_parent() is PlayerShip):
		#var player = Body.get_parent() as PlayerShip
		#plships.append(player)
		#plships.append_array(player.GetDroneDock().DockedDrones)
	#else:
		#var drn = Body.get_parent() as Drone
		#if (drn.Docked):
			#var player = drn.Command
			#plships.append(player)
			#plships.append_array(player.GetDroneDock().DockedDrones)
		#else:
			#plships.append(drn)
			#plships.append_array(drn.GetDroneDock().DockedDrones)
	#if (ShowingTutorial):
		#SimulationManager.GetInstance().TogglePause(true)
		#var DiagText : Array[String] = ["You have reached a place you can land, make sure you stop in time so you can land.", "Landing on different prots allows you to refuel, repair and upgrade you ship and also fine possible recruits"]
		#Ingame_UIManager.GetInstance().CallbackDiag(DiagText, load("res://Assets/artificial-hive.png"), "Seg", LandTutorialShown, false)
	
func LandTutorialShown():
	SimulationManager.GetInstance().TogglePause(false)
	ShowingTutorial = false

#/////////////////////////////////////////////////////////////
#███████  █████  ██    ██ ███████     ██ ██       ██████   █████  ██████  
#██      ██   ██ ██    ██ ██         ██  ██      ██    ██ ██   ██ ██   ██ 
#███████ ███████ ██    ██ █████     ██   ██      ██    ██ ███████ ██   ██ 
	 #██ ██   ██  ██  ██  ██       ██    ██      ██    ██ ██   ██ ██   ██ 
#███████ ██   ██   ████   ███████ ██     ███████  ██████  ██   ██ ██████ 
 
func GetSaveData() ->SaveData:
	var dat = SaveData.new()
	dat.DataName = "Towns"
	var Datas : Array[Resource] = []
	for g in SpotList.size():
		if (SpotList[g] == null):
			continue
		Datas.append(SpotList[g].GetSaveData())
	dat.Datas = Datas
	return dat

func GetMapMarkerEditorSaveData() -> SaveData:
	var dat = SaveData.new()
	dat.DataName = "MarkerEditor"
	var EditorData = SD_MapMarkerEditor.new()
	for g in MapLines.get_children():
		if (g is MapMarkerLine):
			EditorData.AddLine(g)
		else : if (g is MapMarkerText):
			EditorData.AddText(g)
	dat.Datas.append(EditorData)
	return dat


func LoadMapMarkerEditorSaveData(Data : SD_MapMarkerEditor) -> void:
	GetMapMarkerEditor().LoadData(Data)


func LoadSaveData(Data : Array[Resource]) -> void:
	var WorldSize : float = 100000
	for g in Data.size():
		var dat = Data[g] as TownSaveData
		
		var sc = load(dat.TownScenePath).instantiate() as Town
		sc.LoadingData = true
		MapSpots.add_child(sc)
		sc.connect("TownSpotAproached", Arrival)
		
		sc.LoadSaveData(dat)
		SpotList.insert(g, sc)
		
		if (dat.TownLoc.y < WorldSize): 
			WorldSize = dat.TownLoc.y
			
	ShipCamera.WorldBounds = (Vector2(SpawningBounds.x, WorldSize))
	#WeatherManage.WorldBounds = Vector2(SpawningBounds.x, WorldSize)
	#WeatherManage.WorldBounds = (Vector2(SpawningBounds.x, WorldSize))
	#call_deferred("GenerateRoads")
	#_Camera.call_deferred("FrameCamToPlayer")

#/////////////////////////////////////////////////////////////
#██ ███    ██ ██████  ██    ██ ████████     ██   ██  █████  ███    ██ ██████  ██      ██ ███    ██  ██████  
#██ ████   ██ ██   ██ ██    ██    ██        ██   ██ ██   ██ ████   ██ ██   ██ ██      ██ ████   ██ ██       
#██ ██ ██  ██ ██████  ██    ██    ██        ███████ ███████ ██ ██  ██ ██   ██ ██      ██ ██ ██  ██ ██   ███ 
#██ ██  ██ ██ ██      ██    ██    ██        ██   ██ ██   ██ ██  ██ ██ ██   ██ ██      ██ ██  ██ ██ ██    ██ 
#██ ██   ████ ██       ██████     ██        ██   ██ ██   ██ ██   ████ ██████  ███████ ██ ██   ████  ██████ 


func _MAP_INPUT(event: InputEvent) -> void:
	if (event is InputEventScreenTouch):
		_Camera._HANDLE_TOUCH(event)
	else : if (event is InputEventScreenDrag):
		_Camera._HANDLE_DRAG(event)
	else : if (event.is_action_pressed("ZoomIn")):
		_Camera._HANDLE_ZOOM(0.25)
	else : if (event.is_action_pressed("ZoomOut")):
		_Camera._HANDLE_ZOOM(-0.25)
	else : if (event is InputEventMouseMotion):
		if (Input.is_action_pressed("Click")):
			_Camera.UpdateCameraPos(event.relative)
			_InScreenUI.MousePointer.SwitchMouse(InScreenCursor.MouseMode.DIRECTIONAL)
	else : if (event.is_action_released("Click")):
		_InScreenUI.MousePointer.SwitchMouse(InScreenCursor.MouseMode.NORMAL)
		#_InScreenUI.MousePosChanged(event.position)
	else : if (event is InputEventMouseButton):
		if (event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
			_Camera.get_global_mouse_position()
			var pos = _Camera.get_global_mouse_position()
			if (Input.is_action_pressed("Cnt")):
				ControllerEvH.OnTargetPositionAdded(pos)
				PopUpManager.GetInstance().DoFadeNotif("Updating Course")
			else:
				ControllerEvH.OnTargetPositionPicked(pos)
				PopUpManager.GetInstance().DoFadeNotif("Updating Course")

func MouseIn() -> void:
	_InScreenUI.MousePointer.MouseIn()

func MouseOut() -> void:
	_InScreenUI.MousePointer.MouseOut()

func MoveTargetSpotSelected(Spot : SpotMarker) -> void:
	if (Input.is_action_pressed("Cnt")):
		ControllerEvH.OnTargetPositionAdded(Spot.global_position)
		PopUpManager.GetInstance().DoFadeNotif("Updating Course Towards\n{0}".format([Spot.SpotNameLabel.text]))
	else:
		ControllerEvH.OnTargetPositionPicked(Spot.global_position)
		PopUpManager.GetInstance().DoFadeNotif("Updating Course Towards\n{0}".format([Spot.SpotNameLabel.text]))

func MoveTargetSelected(Target : MapShip) -> void:
	ControllerEvH.OnTargetShipSelected(Target)
	PopUpManager.GetInstance().DoFadeNotif("Updating Course")

#/////////////////////////////////////////////////////////////
#███    ███  █████  ██████       ██████  ███████ ███    ██ ███████ ██████   █████  ████████ ██  ██████  ███    ██ 
#████  ████ ██   ██ ██   ██     ██       ██      ████   ██ ██      ██   ██ ██   ██    ██    ██ ██    ██ ████   ██ 
#██ ████ ██ ███████ ██████      ██   ███ █████   ██ ██  ██ █████   ██████  ███████    ██    ██ ██    ██ ██ ██  ██ 
#██  ██  ██ ██   ██ ██          ██    ██ ██      ██  ██ ██ ██      ██   ██ ██   ██    ██    ██ ██    ██ ██  ██ ██ 
#██      ██ ██   ██ ██           ██████  ███████ ██   ████ ███████ ██   ██ ██   ██    ██    ██  ██████  ██   ████ 

var GenThread : Thread

func GenerateMap() -> void:
	#if (SpotList.size() == 0):
	GenThread = Thread.new()
	GenThread.start(GenerateMapThreaded)
	#_InitialPlayerPlacament()
	ShowingTutorial = true

func GenerateMapThreaded() -> void:
	var time = Time.get_ticks_msec()
	
	var CapitalCitySpots : Array[int] = []
	for z in CapitalAmm:
		var spot = roundi(MapSize/CapitalAmm * (z + 1)) - randi_range(2, 5)
		CapitalCitySpots.append(spot)
		
	var VillageSpots : Array[int] = []
	
	for z in VillageAmm:
		var spot = roundi(MapSize/VillageAmm * z)
		if (CapitalCitySpots.has(spot)):
			spot += 1
		VillageSpots.append(spot)
	
	var WorldSize : float = 100000
	
	var FinalCitySpotType = ResourceLoader.load(FinalCityType, "", ResourceLoader.CACHE_MODE_REUSE) as MapSpotType
	var FinalCityData = FinalCitySpotType.GetData()
	var CapitalSpotType = ResourceLoader.load(CapitalType, "", ResourceLoader.CACHE_MODE_REUSE) as MapSpotType
	var CapitalData = CapitalSpotType.GetData()
	var VillageSpotType = ResourceLoader.load(VillageType, "", ResourceLoader.CACHE_MODE_REUSE) as MapSpotType
	var VillageData = VillageSpotType.GetData()
	var CitySpotType = ResourceLoader.load(CityType, "", ResourceLoader.CACHE_MODE_REUSE) as MapSpotType
	var CityData = CitySpotType.GetData()
	
	var town_positions = poisson_disk_sampling(SpawningBounds, MinDistance, MapSize)
	var sorted_positions = sort_positions_by_y(town_positions)
	
	var GeneratedSpots : Array[Town] = []
	for g in sorted_positions.size() :

		#SET THE TYPE
		var sc = TownSpotScene.instantiate() as Town
		var pos = sorted_positions[g]
		
		#centering positions
		pos.x -= SpawningBounds.x / 2
		#algorith gives values from 0 towards possetive y, we want the opposite
		pos.y -= sorted_positions[0].y
		
		if (g == sorted_positions.size() - 1):
			sc.GenerateCity(FinalCitySpotType, FinalCityData)
		else : if (CapitalCitySpots.has(g)):
			sc.GenerateCity(CapitalSpotType, CapitalData)
		else :if (VillageSpots.has(g)):
			sc.GenerateCity(VillageSpotType, VillageData)
		else:
			sc.GenerateCity(CitySpotType, CityData)
			
		sc.connect("TownSpotAproached", Arrival)

		sc.Pos = pos
		if (pos.y < WorldSize):
			WorldSize = pos.y
		MapSpots.call_deferred("add_child", sc)
		
		GeneratedSpots.append(sc)
	
	call_deferred("MapGenFinished", GeneratedSpots, WorldSize)
	
	for g in GeneratedSpots:
		g.call_deferred("SetMerch", EnSpawner.GetMerchForPosition(g.Pos.y, g.GetSpot().HasUpgrade()), EnSpawner.GetWorkshopMerchForPosition(g.Pos.y, g.GetSpot().HasUpgrade()))
		g.call_deferred("SetRecruits", EnSpawner.GetRecruitsForPosition(g.Pos.y, g.GetSpot().HasRecruit()))
	
	
	if (OS.is_debug_build()):
		print("Generating map took " + var_to_str(Time.get_ticks_msec() - time) + " msec")

func sort_positions_by_y(positions: Array) -> Array:
	var sorted = positions.duplicate()
	sorted.sort_custom(
		func(a: Vector2, b: Vector2) -> bool:
			return a.y > b.y
	)
	return sorted


func poisson_disk_sampling(region_size: Vector2, min_dist: float, max_samples: int = 0) -> Array:
	const K := 45 # samples per point
	
	var cell_size = min_dist / sqrt(2)
	var grid_size = Vector2(ceil(region_size.x / cell_size), ceil(region_size.y / cell_size))
	var grid = []
	for i in range(int(grid_size.x * grid_size.y)):
		grid.append(null)
	
	var points = []
	var spawn_points = []
	
	var initial_point = Vector2(
		randf_range(0, region_size.x),
		randf_range(0, region_size.y)
	)
	points.append(initial_point)
	spawn_points.append(initial_point)
	grid[_grid_index(initial_point, cell_size, grid_size)] = initial_point
	
	while spawn_points.size() > 0:
		var spawn_index = randi() % spawn_points.size()
		var center = spawn_points[spawn_index]
		var found = false
		for i in range(K):
			var angle = randf() * PI * 2.0
			var rad = randf_range(min_dist, min_dist * 2.0)
			var dir = Vector2(cos(angle), sin(angle))
			var candidate = center + dir * rad
			if _is_valid(candidate, region_size, cell_size, grid, grid_size, min_dist):
				points.append(candidate)
				spawn_points.append(candidate)
				grid[_grid_index(candidate, cell_size, grid_size)] = candidate
				found = true
				break
		if not found:
			spawn_points.remove_at(spawn_index)
		if max_samples > 0 and points.size() >= max_samples:
			break
	return points

func _is_valid(point: Vector2, region_size: Vector2, cell_size: float, grid: Array, grid_size: Vector2, min_dist: float) -> bool:
	# Check within bounds
	if point.x < 0 or point.x >= region_size.x or point.y < 0 or point.y >= region_size.y:
		return false

	var cell = Vector2i(point / cell_size)
	for y in range(max(cell.y - 2, 0), min(cell.y + 3, grid_size.y)):
		for x in range(max(cell.x - 2, 0), min(cell.x + 3, grid_size.x)):
			var idx = x + y * int(grid_size.x)
			var other = grid[idx]
			if other != null and point.distance_to(other) < min_dist:
				return false
	return true

func _grid_index(point: Vector2, cell_size: float, grid_size: Vector2) -> int:
	var x = int(point.x / cell_size)
	var y = int(point.y / cell_size)
	x = clamp(x, 0, int(grid_size.x) - 1)
	y = clamp(y, 0, int(grid_size.y) - 1)
	return x + y * int(grid_size.x)

func MapGenFinished(Spots : Array[Town], WorldSize : float) -> void:
	Happening.OnWorldGenerated(WorldSize)
	SpotList.append_array(Spots)
	GenThread.wait_to_finish()
	GenerationFinished.emit()
	ShipCamera.WorldBounds = (Vector2(SpawningBounds.x, WorldSize))

var EventThread : Thread

func GenerateEvents() -> void:
	EventThread = Thread.new()
	EventThread.start(GenerateEventsThreaded)

func GenerateEventsThreaded() -> void:
	var SpotGroups = ["CAPITAL", "CITY_CENTER", "VILLAGE"]

	for g in SpotGroups:
		var Spots : Array
		Spots.append_array(get_tree().get_nodes_in_group(g))
		Spots.shuffle()
		
		var SpEvents = EventManager.GetInstance().GetSpecialEventsForSpotType(MapSpotType.SpotKind[g])
		
		while SpEvents.size() > 0 and Spots.size() > 0:
			#var EventToGive = SpEvents[0]

			var S = Spots.pick_random() as MapSpot
			var YPos = S.get_parent().Pos.y
			var E = FigureOutEvent(YPos, SpEvents)
			if (E != null):
				S.Event = E
				E.PickedBy.append(S)
				SpEvents.erase(E)
				print("Picked happening {0} for {1}".format([E.HappeningName, S.GetSpotName()]))
				if (E.CrewRecruit):
					S.call_deferred("add_to_group", "CrewRecruitTown")
					
			Spots.erase(S)

		#var Events = (Spots[0] as MapSpot).SpotType.GetNormalEvents()
		Spots.clear()
		Spots.append_array(get_tree().get_nodes_in_group(g))
		Spots.shuffle()
		var Events = EventManager.GetInstance().GetEventsForSpotType(MapSpotType.SpotKind[g])
		while Events.size() > 0 and Spots.size() > 0:
			var Sp = Spots.pick_random()
			if (Sp.Event != null):
				var Hap = FigureOutEvent(Sp.get_parent().Pos.y, Events)
				if (Hap != null):
					print("Picked happening {0} for {1}".format([Hap.HappeningName, Sp.GetSpotName()]))

					Hap.PickedBy.append(Sp)
					Sp.Event = Hap
			
			Spots.erase(Sp)
	call_deferred("EventGenFinished")

func FigureOutEvent(YPos : float, Events : Array) -> Happening:
	if (Events == null or Events.size() == 0):
		return null
	var GameSt : Happening.GameStage = Happening.GetStageForYPos(YPos)
	
	var PossibleHappenings : Array[Happening]
	for g in Events:
		if (g.PickedBy.size() >= g.AllowedAppearances):
			continue
		if (g.HappeningAppearance == GameSt or g.HappeningAppearance == Happening.GameStage.ANY):
			PossibleHappenings.append(g)
	
	if (PossibleHappenings.size() > 0):
		var Hap = PossibleHappenings.pick_random() as Happening
		if (Hap != null):
			return Hap
	
	return null

func EventGenFinished() -> void:
	EventThread.wait_to_finish()
	GenerationFinished.emit()

#/////////////////////////////////////////////////////////////
#███████ ███    ██ ███████ ███    ███ ██    ██     ███████ ██████   █████  ██     ██ ███    ██ ██ ███    ██  ██████  
#██      ████   ██ ██      ████  ████  ██  ██      ██      ██   ██ ██   ██ ██     ██ ████   ██ ██ ████   ██ ██       
#█████   ██ ██  ██ █████   ██ ████ ██   ████       ███████ ██████  ███████ ██  █  ██ ██ ██  ██ ██ ██ ██  ██ ██   ███ 
#██      ██  ██ ██ ██      ██  ██  ██    ██             ██ ██      ██   ██ ██ ███ ██ ██  ██ ██ ██ ██  ██ ██ ██    ██ 
#███████ ██   ████ ███████ ██      ██    ██        ███████ ██      ██   ██  ███ ███  ██   ████ ██ ██   ████  ██████  


var EnemySpawnTh : Thread

func SpawnTownEnemies() -> void:
	M = Mutex.new()
	EnSpawner.Init()
	TempEnemyNames.clear()
	var List : StringList = await Helper.GetInstance().LoadThreaded(EnemyShipNameList).Sign
	TempEnemyNames.append_array(List.Texts)
	EnemySpawnTh = Thread.new()
	EnemySpawnTh.start(SpawnTownEnemiesThreaded.bind(SpotList))
	
	
func RespawnEnemies(EnemyData : Array[Resource]) -> void:
	M = Mutex.new()
	EnSpawner.Init()
	#TempEnemyNames.append_array(EnemyShipNames)
	EnemySpawnTh = Thread.new()
	EnemySpawnTh.start(RespawnEnemiesThreaded.bind(EnemyData))


func SpawnTownEnemiesThreaded(Towns : Array[Town]) -> void:
	for T in Towns:
		var Spot = T.GetSpot()
		#var time = Time.get_ticks_msec()
		if (T.IsEnemy()):
			SpawnSpotFleet(Spot, false, false, T.Pos)
		if (Spot.GetPossibleDrops().size() == 3):
			SpawnSpotFleet(Spot, true, false, T.Pos)
		#print("Spawning fleet took " + var_to_str(Time.get_ticks_msec() - time) + " msec")
	
	#spawn convoy
	for g in Towns.size() / 3.0:
		var T = Towns[g * 3]
		var Spot = T.GetSpot()
		if (T.IsEnemy()):
			SpawnSpotFleet(Spot, false, true, T.Pos)
	
	#GenerationFinished.emit()
	call_deferred("SpawnFin")

func SpawnFin() -> void:
	call_deferred("FGenerationFinished")

func SpawnSpotFleet(Spot : MapSpot, Patrol : bool, Convoy : bool,  Pos : Vector2) -> void:
	print("Spawning for {0}".format([Spot.GetSpotName()]))
	var Fleet = EnSpawner.GetSpawnsForLocation(Pos.y, Patrol, Convoy)
	var SpawnedFleet = []
	#var SpawnedCallsigns = []
	for f in Fleet:
		var Ship = EnemyScene.instantiate() as HostileShip
		Ship.Cpt = f

		Ship.CurrentPort = Spot
		Ship.Patrol = Patrol
		Ship.Convoy = Convoy
		#if (TempEnemyNames.size() > 0):
		M.lock()
		var ShipName = TempEnemyNames[TempEnemyNames.size() - 1]
		Ship.ShipName = ShipName
		TempEnemyNames.remove_at(TempEnemyNames.size() - 1)
		M.unlock()
		#SpawnedCallsigns.append(f.ShipCallsign)
		SpawnedFleet.append(Ship)
		Ship.PosToSpawn = Pos
		Ship.connect("OnPlayerShipMet", EnemyMet)
		WorldParent.call_deferred("add_child", Ship)
		#call_deferred("AddEnemyToHierarchy", Ship, Pos)
		if (Fleet.find(f) != 0):
			Ship.ToggleDocked(true)
			Ship.Command = SpawnedFleet[0]
			SpawnedFleet[0].GetDroneDock().call_deferred("DockShip", Ship)
	#print("A fleet consisting of {0} was spawned at the port of {1}. Patrol = {2}".format([var_to_str(SpawnedCallsigns), Spot.GetSpotName(), Patrol]))
	#TempEnemyNames.clear()

func RespawnEnemiesThreaded(EnemyData : Array[Resource]) -> void:
	var SpawnedEnems : Array[HostileShip] = []
	for g in EnemyData:
		var ship = EnemyScene.instantiate() as HostileShip
		ship.LoadSaveData(g)
		SpawnedEnems.append(ship)
		ship.PosToSpawn = g.Position
		ship.connect("OnPlayerShipMet", EnemyMet)
		WorldParent.call_deferred("add_child", ship)

		#call_deferred("AddEnemyToHierarchy", ship, g.Position)
		if (g.CommandName != ""):
			var com
			for z in SpawnedEnems:
				if (z.GetShipName() == g.CommandName):
					com = z
			ship.ToggleDocked(true)
			ship.Command = com
			com.GetDroneDock().call_deferred("DockShip", ship)
			
		
	#call_deferred("FGenerationFinished")
	call_deferred("EnemySpawnFinished")


func FindEnemyByName(Name : String) -> HostileShip:
	for g in get_tree().get_nodes_in_group("Enemy"):
		if (g.GetShipName() == Name):
			return g
	return null


func FGenerationFinished() -> void:
	GenerationFinished.emit()


func RespawnMissiles(MissileData : Array[Resource]) -> void:
	for g in MissileData:
		var dat = g as MissileSaveData
		var missile = (load(dat.Scene) as PackedScene).instantiate() as Missile
		missile.Distance = dat.Distance
		missile.MissileName = dat.MisName
		missile.Speed = dat.MisSpeed
		WorldParent.add_child(missile)
		missile.global_position = dat.Pos
		missile.global_rotation = dat.Rot
		missile.DistanceTraveled = dat.DistanceTraveled
		missile.ShipMet.connect(EnemyMet)
	for g in get_tree().get_nodes_in_group("Enemy"):
		g.connect("OnShipMet", EnemyMet)


func GetMissileSaveData() -> SaveData:
	var dat = SaveData.new()
	dat.DataName = "Missiles"
	var Datas : Array[Resource] = []
	for g in get_tree().get_nodes_in_group("Missiles"):
		var mis = g as Missile
		Datas.append(mis.GetSaveData())
	dat.Datas = Datas
	return dat


func EnemySpawnFinished() -> void:
	EnemySpawnTh.wait_to_finish()
	#set_physics_process(true)
	
	
	
#/////////////////////////////////////////////////////////////
#██████   ██████   █████  ██████       ██████  ███████ ███    ██ ███████ ██████   █████  ████████ ██  ██████  ███    ██ 
#██   ██ ██    ██ ██   ██ ██   ██     ██       ██      ████   ██ ██      ██   ██ ██   ██    ██    ██ ██    ██ ████   ██ 
#██████  ██    ██ ███████ ██   ██     ██   ███ █████   ██ ██  ██ █████   ██████  ███████    ██    ██ ██    ██ ██ ██  ██ 
#██   ██ ██    ██ ██   ██ ██   ██     ██    ██ ██      ██  ██ ██ ██      ██   ██ ██   ██    ██    ██ ██    ██ ██  ██ ██ 
#██   ██  ██████  ██   ██ ██████       ██████  ███████ ██   ████ ███████ ██   ██ ██   ██    ██    ██  ██████  ██   ████

var Maplt : Thread
var Roadt : Thread
var Regiont : Thread
var Mut : Mutex

func GenerateRoads() -> void:
	var CityGroups = ["CAPITAL", "CITY_CENTER"]
	var AllSpotGroups = ["CAPITAL", "CITY_CENTER", "VILLAGE"]
	var Spots : Array
	for g in CityGroups:
		Spots.append_array(get_tree().get_nodes_in_group(g))
	var cityloc : PackedVector2Array
	for g in Spots:
		cityloc.append(g.global_position)
		
	var Spots2 : Array
	for g in AllSpotGroups:
		Spots2.append_array(get_tree().get_nodes_in_group(g))
	var cityloc2 : PackedVector2Array
	for g in Spots2:
		cityloc2.append(g.global_position)
		
	Region._DrawBorders(Spots2)
	
	Road.Generate(cityloc2)
	MapLine.Generate(cityloc)
	
	MapLine.PathsGenerated.connect(GeneratePathsFromLines)
	#Regiont = Thread.new()
	#Regiont.start(_DrawBorders.bind(Spots2))
	
	
func GeneratePathsFromLines(Lines : Array):
	GenerationFinished.emit()
	var time = Time.get_ticks_msec()
	if (OS.is_debug_build()):
		print("Connecting neighboring cities based on generated paths")
		
	var SpotGroups = ["CAPITAL", "CITY_CENTER"]
	var Cits : Array
	for g in SpotGroups:
		Cits.append_array(get_tree().get_nodes_in_group(g))

	for g : MapSpot in Cits:
		var SpotPos = g.global_position
		var Neighbors : Array[String] = []
		for Line in Lines:
			if (Line.has(SpotPos)):
				for v in Cits:
					if (v == g):
						continue
					if (Neighbors.has(v.SpotName)):
						continue
					var SpotPos2 = v.global_position
					if (Line.has(SpotPos2)):
						Neighbors.append(v.SpotName)
						break
		g.SetNeighbord(Neighbors)
	MAP_NeighborsSet.emit()
	GenerationFinished.emit()
	if (OS.is_debug_build()):
		print("Connection of neighboring cities finished in {0} ms".format([Time.get_ticks_msec() - time]))


#/////////////////////////////////////////////////////////////
#SCREEN RESIZING
const ScreenPos = Vector2(67.0,62.0)
const NormalPos = Vector2(342, 62)
const OriginalSize = Vector2(869, 595.0)
const NormalSize = Vector2(595, 595)
const FullSize = Vector2(1148.0, 595.0)

func ToggleFullScreen(NewState : ScreenUI.ScreenState) -> void:
	
	#$SubViewportContainer.visible = false
	
	#var toggle = await _ScreenUI.FullScreenToggleStarted
	
	if (NewState == ScreenUI.ScreenState.FULL_SCREEN):
		$SubViewportContainer.position = ScreenPos
		$SubViewportContainer.size = FullSize
		_InScreenUI.ToggleCrtEffect(true)
		_InScreenUI.SetScreenRes(FullSize)
	else: if (NewState == ScreenUI.ScreenState.HALF_SCREEN):
		$SubViewportContainer.position = ScreenPos
		$SubViewportContainer.size = OriginalSize
		_InScreenUI.ToggleCrtEffect(true)
		_InScreenUI.SetScreenRes(OriginalSize)
	else: if (NewState == ScreenUI.ScreenState.NORMAL_SCREEN):
		$SubViewportContainer.position = NormalPos
		$SubViewportContainer.size = NormalSize
		_InScreenUI.ToggleCrtEffect(true)
		_InScreenUI.SetScreenRes(NormalSize)
	else:
		$SubViewportContainer.position = Vector2.ZERO
		$SubViewportContainer.size = get_viewport().get_visible_rect().size
		_InScreenUI.ToggleCrtEffect(false)
	$SubViewportContainer.visible = true
