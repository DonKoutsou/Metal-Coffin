extends Node2D
class_name MapSpot

@export var FuelTradeScene : PackedScene
@export var CityFuelReserves : float = 1000
@export var AlarmVisual : PackedScene

var PlayerFuelReserves : float = 0
var PlayerRepairReserves : float = 0

signal SpotAproached(Type :MapSpotType)
signal SpotLanded(Type : MapSpotType)
signal SpotAlarmRaised(Notify : bool)

var SpotType : MapSpotType
var SpotInfo : MapSpotCompleteInfo
var Merch : Array[Merchandise] = []
var Pos : Vector2
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

#func SimulationSpeedChanged(i : float) -> void:
	#SimSpeed = i
	
func ToggleSimulation(t : bool) -> void:
	SimPaused = t

func SetNeighbord(N : Array) -> void:
	NeighboringCities = N
	#print(GetSpotName() + " get their neighbors || " + var_to_str(NeighboringCities))
	
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
	datas.SpotType = SpotType
	datas.SpotLoc = position
	datas.Seen = Seen
	datas.Visited = Visited
	datas.CityFuelReserves = CityFuelReserves
	datas.PlayerFuelReserves = PlayerFuelReserves
	datas.SpotInfo = SpotInfo
	datas.AlarmRaised = AlarmRaised
	datas.AlarmProgress = AlarmProgress
	datas.Merch = Merch
	datas.Evnt = Event
	return datas

func SetSpotData(Data : MapSpotType) -> void:
	SpotType = Data
	if (Data.CustomData.size() > 0):
		for g in Data.CustomData:
			if (g is MapSpotCustomData_CompleteInfo):
				var IDs = g as MapSpotCustomData_CompleteInfo
				if (IDs.PossibleIds.size() == 0):
					continue

				for z in IDs.PossibleIds:
					if (z.PickedBy != null):
						continue
					SpotInfo = z as MapSpotCompleteInfo

					if (SpotInfo.EnemyCity):
						add_to_group("EnemyDestinations")
					#IDs.PossibleIds.erase(ID)
					SpotInfo.PickedBy = self
					break
				
		
	if (Data.VisibleOnStart):
		OnSpotSeen(false)
		#OnSpotAnalyzed(false)

	add_to_group(Data.GetSpotEnumString(Data.SpotK))
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
	SimulationManager.GetInstance().TogglePause(true)

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

func OnSpotAproached(AproachedBy : MapShip) -> void:
	VisitingShips.append(AproachedBy)
	
	if (AproachedBy is HostileShip):
		return
		
	SpotAproached.emit(self)
	
	if (!Seen):
		OnSpotSeen()
	
	if (SpotInfo.EnemyCity):
		if (AlarmRaised):
			Commander.GetInstance().OnEnemySeen(AproachedBy, null)
		else:
			set_physics_process(true)

func OnSpotDeparture(DepartingShip : MapShip) -> void:
	VisitingShips.erase(DepartingShip)
	if (SpotInfo.EnemyCity):
		if (AlarmRaised):
			Commander.GetInstance().OnEnemyVisualLost(DepartingShip)
		else :if (VisitingShips.size() == 0):
			set_physics_process(false)
func OnAlarmRaised(Notify : bool = false) -> void:
	var AlarmViz = AlarmVisual.instantiate()
	add_child(AlarmViz)
	SimulationManager.GetInstance().TogglePause(true)
	ShipCamera.GetInstance().FrameCamToPos(global_position)
	SpotAlarmRaised.emit(Notify)
	AlarmRaised = true
	for g in VisitingShips:
		Commander.GetInstance().OnEnemySeen(g, null)

func PlayerHasFuelReserves() -> bool:
	return PlayerFuelReserves > 0
