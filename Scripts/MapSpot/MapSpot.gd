extends Node2D
class_name MapSpot


#@export var CityFuelReserves : float = 1000
@export var AlarmVisual : PackedScene

var PlayerFuelReserves : float = 0

signal SpotAproached(Type :MapSpot)
signal SpotLanded(Type : MapSpot)
signal SpotAlarmRaised(Notify : bool)
signal FuelReservesChanged(NewAmm : float)

var SpotType : MapSpotType
var SpotInfo : MapSpotCompleteInfo
var Merch : Array[Merchandise] = []
var WorkShopMerch : Array[Merchandise] = []
var Pos : Vector2
var Population : int
var Visited = false
var Seen = false
var AlarmRaised = false
var AlarmProgress = 0
#bool to avoid sent drones colliding with current visited spot
var NeighboringCities : Array[String]
var Connected
var Event : Happening
var SimPaused = false
#var SimSpeed : float = 1

func _ready() -> void:
	set_physics_process(false)
	SimPaused = SimulationManager.IsPaused()
	#SimSpeed = SimulationManager.SimSpeed()
	global_rotation = 0
	if (Pos != Vector2.ZERO):
		position = Pos
	if (SpotType.VisibleOnStart):
		OnSpotSeen(false)

func _exit_tree() -> void:
	if (Event != null):
		Event.PickedBy.erase(self)
#func SimulationSpeedChanged(i : float) -> void:
	#SimSpeed = i
	
func ToggleSimulation(t : bool) -> void:
	SimPaused = t

func SetNeighbord(N : Array) -> void:
	NeighboringCities = N

func SpawnEnemyPatrol():
	var host = SpotInfo.HostilePatrolShipScene.instantiate() as HostileShip
	host.CurrentPort = self
	host.ShipName = SpotInfo.HostilePatrolShipName
	get_parent().get_parent().get_parent().get_parent().add_child(host)
	host.global_position = global_position
	
func SpawnEnemyGarison():
	var host = SpotInfo.HostileShipScene.instantiate() as HostileShip
	host.CurrentPort = self
	host.ShipName = SpotInfo.HostileShipName
	get_parent().get_parent().get_parent().get_parent().add_child(host)
	host.global_position = global_position


#//////////////////////////////////////////////////////////////////
func GetSaveData() -> Resource:
	var datas = MapSpotSaveData.new()
	datas.Population = Population
	datas.SpotType = SpotType
	datas.SpotLoc = position
	datas.Seen = Seen
	datas.Visited = Visited
	datas.PlayerFuelReserves = PlayerFuelReserves
	datas.SpotInfo = SpotInfo
	datas.AlarmRaised = AlarmRaised
	datas.AlarmProgress = AlarmProgress
	datas.Merch = Merch
	datas.WorkShopMerch = WorkShopMerch
	datas.Evnt = Event
	return datas

func SetSpotData(Type : MapSpotType) -> void:
	SpotType = Type
	var Data = Type.Data as MapSpotCustomData_CompleteInfo
	
	if (Type.SpotK == MapSpotType.SpotKind.CITY_CENTER):
		Population = randi_range(10000, 50000)
	else : if (Type.SpotK == MapSpotType.SpotKind.CAPITAL):
		Population = randi_range(80000, 150000)
	else : if (Type.SpotK == MapSpotType.SpotKind.VILLAGE):
		Population = randi_range(2000, 6000)
	
	SetSize()
	
	for z in Data.PossibleIds:
		if (z.PickedBy != null):
			continue
		SpotInfo = z as MapSpotCompleteInfo

		if (SpotInfo.EnemyCity):
			add_to_group("EnemyDestinations")
		#IDs.PossibleIds.erase(ID)
		SpotInfo.PickedBy = self
		break
				
		
	
		#OnSpotAnalyzed(false)

	add_to_group(SpotType.GetSpotEnumString())

func SetSize() -> void:
	var sizething = (Population / 150000.0) as float
	var collider = $AreaNotif/CollisionShape2D.shape as CircleShape2D
	collider.radius = lerp(30, 250, sizething) / 2

func GetSpotName() -> String:
	return SpotInfo.SpotName
func GetPossibleDrops() -> Array:
	return SpotInfo.PossibleDrops
func HasFuel() -> bool:
	var hasf = false
	
	for g in SpotInfo.PossibleDrops:
		if g is UsableItem and g.StatUseName == STAT_CONST.STATS.FUEL_TANK:
			hasf = true
			break
	
	return hasf
func HasRepair() -> bool:
	var hasf = false
	for g in SpotInfo.PossibleDrops:
		if g is UsableItem and g.StatUseName == STAT_CONST.STATS.HULL:
			hasf = true
			break
	return hasf
func HasUpgrade() -> bool:
	var hasu = false
	for g in SpotInfo.PossibleDrops:
		if g.ItemName == "Material":
			hasu = true
			break
	return hasu
#//////////////////////////////////////////////////////////////////
func OnSpotVisited(PlayAnim : bool = true) -> void:
	#if (!Analyzed):
		#OnSpotAnalyzed(PlayAnim)
	if (!Visited):
		SpotLanded.emit(self)
	if (!Seen):
		OnSpotSeen(PlayAnim)
	Visited = true
#Called when radar sees a mapspot
func OnSpotSeen(PlayAnim : bool = true) -> void:
	call_deferred("AddMapSpot", PlayAnim)
	
func AddMapSpot(PlayAnim : bool) -> void:
	MapPointerManager.GetInstance().AddSpot( self, PlayAnim)
	Seen = true
	SimulationManager.GetInstance().SpeedToggle(false)

func PlaySound():
	var sound = AudioStreamPlayer2D.new()
	sound.bus = "MapSounds"
	sound.volume_db = 10
	sound.stream = load("res://Assets/Sounds/radar-beeping-sound-effect-192404.mp3")
	add_child(sound)
	sound.play()

func _physics_process(delta: float) -> void:
	if (SimPaused):
		return
	
	AlarmProgress += delta * SimulationManager.SimSpeed()
	
	if (AlarmProgress > 300):
		set_physics_process(false)
		OnAlarmRaised(true)

var VisitingShips : Array[MapShip] = []
var VisitingHostiles : Array[MapShip] = []
func OnSpotAproached(AproachedBy : MapShip) -> void:
	if (AproachedBy is HostileShip):
		VisitingHostiles.append(AproachedBy)
		return
		
	VisitingShips.append(AproachedBy)
	if (AproachedBy.Command == null):
		SimulationManager.GetInstance().SpeedToggle(false)
		Map.GetInstance().GetCamera().FrameCamToPos(global_position, 1, false)
		SpotAproached.emit(self)
	else:
		AproachedBy.GetDroneDock()
	if (!Seen):
		OnSpotSeen()
	
	if (SpotInfo.EnemyCity):
		if (AlarmRaised):
			Commander.GetInstance().OnEnemySeen(AproachedBy, null)
		else:
			set_physics_process(true)

func OnSpotDeparture(DepartingShip : MapShip) -> void:
	if (DepartingShip is HostileShip):
		VisitingHostiles.erase(DepartingShip)
		return
	
	VisitingShips.erase(DepartingShip)
	if (SpotInfo.EnemyCity):
		if (AlarmRaised):
			Commander.GetInstance().OnEnemyVisualLost(DepartingShip)
		else :if (VisitingShips.size() == 0):
			set_physics_process(false)
			
func OnAlarmRaised(Notify : bool = false) -> void:
	var AlarmViz = AlarmVisual.instantiate()
	add_child(AlarmViz)
	SimulationManager.GetInstance().SpeedToggle(false)
	Map.GetInstance().GetCamera().FrameCamToPos(global_position)
	SpotAlarmRaised.emit(Notify)
	AlarmRaised = true
	for g in VisitingShips:
		Commander.GetInstance().OnEnemySeen(g, null)

func SetFuelReserves(NewAmm : float) -> void:
	PlayerFuelReserves = NewAmm
	FuelReservesChanged.emit(PlayerFuelReserves)

func AddToFuelReserves(Amm : float) -> void:
	PlayerFuelReserves = max(0, PlayerFuelReserves + Amm)
	FuelReservesChanged.emit(PlayerFuelReserves)

func PlayerHasFuelReserves() -> bool:
	return PlayerFuelReserves > 0
