extends Node2D
class_name MapSpot

@export var FuelTradeScene : PackedScene
@export var CityFuelReserves : float = 1000

var PlayerFuelReserves : float = 0
var PlayerRepairReserves : float = 0

signal SpotAproached(Type :MapSpotType)
signal SpotLanded(Type : MapSpotType)

var SpotType : MapSpotType
var SpotInfo : MapSpotCompleteInfo
var Pos : Vector2
var Visited = false
var Seen = false
#bool to avoid sent drones colliding with current visited spot
var CurrentlyVisiting = false
var NeighboringCities : Array[String]
var Connected

func _ready() -> void:
	global_rotation = 0
	if (Pos != Vector2.ZERO):
		position = Pos

func SetNeighbord(N : Array) -> void:
	NeighboringCities = N
	print(GetSpotName() + " get their neighbors || " + var_to_str(NeighboringCities))
	
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
	var datas = MapSpotSaveData.new().duplicate()
	datas.SpotType = SpotType
	datas.SpotLoc = position
	datas.Seen = Seen
	datas.Visited = Visited
	datas.CityFuelReserves = CityFuelReserves
	datas.PlayerFuelReserves = PlayerFuelReserves
	datas.SpotInfo = SpotInfo
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
					#if (ID.PickedBy != null):
					#continue
					#SpotName = spotid.SpotName
					#Evnt = spotid.Event
					#EnemyCity = spotid.EnemyCity
					#SpawnHostileShip = spotid.SpawnHostileShip
					#PossibleDrops = spotid.PossibleDrops
					#HostilePatrolToSpawn = spotid.HostilePatrolShipScene
					#HostilePatrolName = spotid.HostilePatrolShipName
					#HostileGarison = spotid.HostileShipScene
					#HostileGarisonName = spotid.HostileShipName
					
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
		if g is UsableItem and g.StatUseName == "FUEL":
			hasf = true
			break
	
	return hasf
func HasRepair() -> bool:
	var hasf = false
	for g in SpotInfo.PossibleDrops:
		if g is UsableItem and g.StatUseName == "HULL":
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
#Called when drone visits a mapspot
func OnSpotSeenByDrone(PlayAnim : bool = true) -> void:
	call_deferred("AddMapSpot", PlayAnim)
	
#func OnSpotVisitedByDrone() -> void:
	#if (!Analyzed):
		#OnSpotAnalyzed()
#func OnSpotAnalyzed(PlayAnim : bool = true) ->void:
	#call_deferred("SpotAnalyzedSignal", PlayAnim)
	#Analyzed = true
	
#func SpotAnalyzedSignal(PlayAnim: bool)-> void:
	#SpotAnalazyed.emit(PlayAnim)

func PlaySound():
	var sound = AudioStreamPlayer2D.new()
	sound.bus = "MapSounds"
	sound.volume_db = 10
	sound.stream = load("res://Assets/Sounds/radar-beeping-sound-effect-192404.mp3")
	add_child(sound)
	sound.play()
	
func AreaEntered(area: Area2D):
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		if (area.get_collision_layer_value(1)):
			if (!Seen):
				OnSpotSeen()
				#OnSpotAnalyzed()
		#else: if (area.get_collision_layer_value(2)):
			#if (!Analyzed):
				#OnSpotAnalyzed()
		else: if (area.get_collision_layer_value(3)):
			CurrentlyVisiting = true
			var ship = area.get_parent()
			ship.SetCurrentPort(self)
			SpotAproached.emit(self)
			if (!Seen):
				OnSpotSeen()
				#OnSpotAnalyzed()
		#else: if (area.get_collision_layer_value(4)):
			#CurrentlyVisiting = true
			#var ship = area.get_parent() as Drone
			#ship.SetCurrentPort(self)
			#SpotAproached.emit(self)
func AreaExited(area: Area2D):
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		if (area.get_collision_layer_value(3)):
			CurrentlyVisiting = false
			var ship = area.get_parent() 
			ship.RemovePort()
