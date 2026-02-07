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

var SpotName : String
var Region : MapSpotCompleteInfo.REGIONS
#@export var Event : Happening
var EnemyCity : bool = false
var PossibleDrops : Array[Item]
var Merch : Array[Merchandise] = []
var WorkShopMerch : Array[Merchandise] = []
var Pos : Vector2

#Current population of spot
var Population : int
# Is true if player has landed on the spot
var Visited = false
# Is true if player has arrived at location
var Seen = false

#Alarm
var AlarmRaised = false
var AlarmProgress = 0

#bool to avoid sent drones colliding with current visited spot
var NeighboringCities : Array[String]
var Event : Happening

var VisitingShips : Array[MapShip] = []
var VisitingHostiles : Array[MapShip] = []


func _ready() -> void:
	#set_physics_process(false)
	#SimSpeed = SimulationManager.SimSpeed()
	global_rotation = 0
	if (Pos != Vector2.ZERO):
		position = Pos
	if (SpotType.VisibleOnStart):
		OnSpotSeen(false)

func Update(delta: float) -> void:
	if (EnemyCity and !AlarmRaised and VisitingShips.size() > 0):
		AlarmProgress += delta
		
		if (AlarmProgress > 300):
			OnAlarmRaised(true)

func _exit_tree() -> void:
	if (Event != null):
		Event.PickedBy.erase(self)


func SetNeighbord(N : Array) -> void:
	NeighboringCities = N


#//////////////////////////////////////////////////////////////////
func GetSaveData() -> Resource:
	var datas = MapSpotSaveData.new()
	datas.Population = Population
	datas.SpotType = SpotType
	datas.SpotLoc = position
	datas.Seen = Seen
	datas.Visited = Visited
	datas.PlayerFuelReserves = PlayerFuelReserves
	datas.SpotName =SpotName
	datas.Region = Region
	datas.EnemyCity = EnemyCity
	datas.PossibleDrops = PossibleDrops
	datas.AlarmRaised = AlarmRaised
	datas.AlarmProgress = AlarmProgress
	datas.Merch = Merch
	datas.WorkShopMerch = WorkShopMerch
	datas.Evnt = Event
	return datas

func SetSpotData(Type : MapSpotType, Data : MapSpotCustomData_CompleteInfo) -> void:
	SpotType = Type
	
	if (Type.SpotK == MapSpotType.SpotKind.CITY_CENTER):
		Population = randi_range(10000, 50000)
	else : if (Type.SpotK == MapSpotType.SpotKind.CAPITAL):
		Population = randi_range(80000, 150000)
	else : if (Type.SpotK == MapSpotType.SpotKind.VILLAGE):
		Population = randi_range(2000, 6000)
	
	SetSize()
	
	for z : MapSpotCompleteInfo in Data.PossibleIds:
		if (z.PickedBy != null):
			continue
		
		SpotName = z.SpotName
		Region = z.Region
		EnemyCity = z.EnemyCity
		PossibleDrops = z.PossibleDrops

		if (EnemyCity):
			add_to_group("EnemyDestinations")
		#IDs.PossibleIds.erase(ID)
		z.PickedBy = self
		break

	add_to_group(SpotType.GetSpotEnumString())

func SetSize() -> void:
	var sizething = (Population / 150000.0) as float
	var collider = $AreaNotif/CollisionShape2D.shape as CircleShape2D
	collider.radius = lerp(30, 250, sizething) / 2

func GetSpotName() -> String:
	return SpotName
func GetPossibleDrops() -> Array:
	return PossibleDrops
	
func HasFuel() -> bool:
	var hasf = false
	
	for g in PossibleDrops:
		if g is UsableItem and g.StatUseName == STAT_CONST.STATS.FUEL_TANK:
			hasf = true
			break
	
	return hasf
	
func HasRepair() -> bool:
	var hasf = false
	for g in PossibleDrops:
		if g is UsableItem and g.StatUseName == STAT_CONST.STATS.HULL:
			hasf = true
			break
	return hasf
	
func HasUpgrade() -> bool:
	var hasu = false
	for g in PossibleDrops:
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




func OnSpotAproached(AproachedBy : MapShip) -> void:
	# if ship is hostile we return
	if (AproachedBy is HostileShip):
		VisitingHostiles.append(AproachedBy)
		return
	#make sure to store all curreny visiting ships
	VisitingShips.append(AproachedBy)
	
	# check if apreaching ship is commander of fleet, if ship has no commander it means they are a commander
	if (AproachedBy.Command == null):
		# stop simulation speeding and frame camera to player to let them know
		SimulationManager.GetInstance().SpeedToggle(false)
		Map.GetInstance().GetCamera().FrameCamToPos(global_position, 1, false)
		SpotAproached.emit(self)
	else:
		AproachedBy.GetDroneDock()
	
	#if haven't arrived before, mark as visited
	if (!Seen):
		OnSpotSeen()
	
	if (EnemyCity):
		if (AlarmRaised):
			Commander.GetInstance().OnEnemySeen(AproachedBy, null)


func OnSpotDeparture(DepartingShip : MapShip) -> void:
	if (DepartingShip is HostileShip):
		VisitingHostiles.erase(DepartingShip)
		return
	
	VisitingShips.erase(DepartingShip)
	if (EnemyCity):
		if (AlarmRaised):
			Commander.GetInstance().OnEnemyVisualLost(DepartingShip)
			
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
