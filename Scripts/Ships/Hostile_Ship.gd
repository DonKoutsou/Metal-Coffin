extends MapShip
#/////////////////////////////////////////////////////////////
#██   ██  ██████  ███████ ████████ ██ ██      ███████     ███████ ██   ██ ██ ██████  
#██   ██ ██    ██ ██         ██    ██ ██      ██          ██      ██   ██ ██ ██   ██ 
#███████ ██    ██ ███████    ██    ██ ██      █████       ███████ ███████ ██ ██████  
#██   ██ ██    ██      ██    ██    ██ ██      ██               ██ ██   ██ ██ ██      
#██   ██  ██████  ███████    ██    ██ ███████ ███████     ███████ ██   ██ ██ ██      
#/////////////////////////////////////////////////////////////
#Enemy class. Enemies that are patrolling are controlled from COMMANDER.
#If its not patrolling it needs to behavior as it is static and its just protecting city.
#/////////////////////////////////////////////////////////////
class_name HostileShip

#Direction this patrol will go towards if its a patrol
@export var Direction = -1
@export var ShipName : String
@export var Patrol : bool = true
@export var Convoy : bool = false
@export var BT : PackedScene
@export var AlarmVisual : PackedScene
#This array will be filled by commander when this ship is sent after another ship
var PursuingShips : Array[Node2D]
#This value will be filled by commander when this ship is sent to investigate a position
var PositionToInvestigate : Vector2

#Spot that was chosen to stop and refuel
var RefuelSpot : MapSpot
#Spot that was chosen to hide until alarm goese of
var RefugeSpot : MapSpot
#Filled with player ships when they can see this ship
var VisibleBy : Array[Node2D]

#var LOD : int = 0
var Captured : bool
var BTree : BeehaveTree
var BBoard : Blackboard
var UseDefaultBehavior : bool = false

var PosToSpawn : Vector2
var LoadingSave : bool = false
var Spawned : bool = false

#if lodded it means it should not process
var Lodded : bool = true

signal OnPlayerShipMet(PlayerSquad : Array[MapShip] , EnemySquad : Array[MapShip])
signal OnDestinationReached(Ship : HostileShip)
signal OnPlayerVisualContact(Ship : MapShip, SeenBy : HostileShip)
signal OnPlayerVisualLost(Ship : MapShip)
signal OnPositionInvestigated(Pos : Vector2)
signal ElintContact(Ship : MapShip, t : bool)
signal ShipSpawned
signal ShipWrecked

func  _ready() -> void:
	ElintShape.connect("area_entered", BodyEnteredElint)
	ElintShape.connect("area_exited", BodyLeftElint)
	RadarShape.connect("area_entered", BodyEnteredRadar)
	RadarShape.connect("area_exited", BodyLeftRadar)
	BodyShape.connect("area_entered", BodyEnteredBody)
	BodyShape.connect("area_exited", BodyLeftBody)
	Cpt.connect("ShipPartChanged", PartChanged)
	
	ToggleFuelRangeVisibility(false)
	call_deferred("InitialiseShip")
	
	#ENABLE FOR DEBUG PURPOSES
	#MapPointerManager.GetInstance().AddShip(self, false)


func InitialiseShip() -> void:
	global_position = PosToSpawn
	ShipSpawned.emit()
	Spawned = true
	
	if (!LoadingSave):
		for g in Cpt.CaptainStats:
			g.ForceMaxValue()
	
	if (Destroyed):
		Kill()
		return
	
	Commander.GetInstance().RegisterSelf(self)
	
	_UpdateShipIcon(Cpt.ShipIcon)
	var ElintRange = Cpt.GetStatFinalValue(STAT_CONST.STATS.ELINT)
	if (ElintRange == 0):
		ElintShape.queue_free()
	else:
		UpdateELINTTRange(ElintRange)

	UpdateVizRange(Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE))
	
	if (Patrol or Convoy):
		if (Command == null):
			FigureOutPath()
	else:
		SetSpeed(0)
		UseDefaultBehavior = true
	
	#TogglePause(SimulationManager.IsPaused())


func _Update(delta: float) -> void:
		
	UpdateElint(delta)
	#if (Paused):
		#return
	
	for g in TrailLines:
		g.UpdateProjected(delta, 1)
	
	if (UseDefaultBehavior):
		var SimulationSpeed = SimulationManager.SimSpeed()
		if (GarrissonVisualContacts.size() > 0 and VisualContactCountdown > 0):
			VisualContactCountdown -= 0.1 * SimulationSpeed
			if (VisualContactCountdown < 0):
				for c in GarrissonVisualContacts:
					OnPlayerVisualContact.emit(c, self)

		
		if (!Cpt.IsResourceFull(STAT_CONST.STATS.HULL)):
			Cpt.RefillResource(STAT_CONST.STATS.HULL ,0.02 * SimulationSpeed)
		
		if (!Cpt.IsResourceFull(STAT_CONST.STATS.MISSILE_SPACE)):
			Cpt.RefillResource(STAT_CONST.STATS.MISSILE_SPACE ,0.005 * SimulationSpeed)
			
	else: if (BTree != null):
		BTree.Process_Tree()
		

func DoAlarmVisual() -> void:
	add_child(AlarmVisual.instantiate())

func LaunchMissile(Mis : MissileItem, Pos : Vector2) -> void:
	var missile = Mis.MissileScene.instantiate() as Missile
	missile.FiredBy = self
	missile.SetData(Mis)
	get_parent().add_child(missile)
	if (Command != null):
		missile.global_position = Command.global_position
	else:
		missile.global_position = global_position
	missile.look_at(Pos)

func UpdateElint(delta: float) -> void:
	d -= delta
	if (d > 0):
		return
	d = 0.4
	var BiggestLevel = -1
	var ClosestShip : MapShip
	for g in ElintContacts.size():
		var ship = ElintContacts.keys()[g] as MapShip
		if (!ship.RadarWorking):
			continue
		var lvl = ElintContacts.values()[g]
		var Newlvl = GetElintLevel(global_position.distance_to(ship.global_position), ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE))
		if (Newlvl > BiggestLevel):
			BiggestLevel = Newlvl
			ClosestShip = ship
		if (Newlvl != lvl):
			ElintContacts[ship] = Newlvl
	if (BiggestLevel > -1):
		if (ClosestShip.Command != null):
			ElintContact.emit(ClosestShip.Command ,true)
		else:
			ElintContact.emit(ClosestShip ,true)

func GetFuelRange() -> float:
	var fuel = Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
	var fuel_ef = Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
	var fleetsize = 1 + GetDroneDock().DockedDrones.size()
	var total_fuel = fuel
	var inverse_ef_sum = 1.0 / fuel_ef
	
	# Group ships fuel and efficiency calculations
	for g in GetDroneDock().DockedDrones:
		var ship_fuel = g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var ship_efficiency = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
		total_fuel += ship_fuel
		inverse_ef_sum += 1.0 / ship_efficiency

	var effective_efficiency = fleetsize / inverse_ef_sum
	# Calculate average efficiency for the group
	return (total_fuel * effective_efficiency) / fleetsize

func IsFuelFull() -> bool:
	for g in GetDroneDock().DockedDrones:
		if (!g.IsFuelFull()):
			return false
	return Cpt.IsResourceFull(STAT_CONST.STATS.FUEL_TANK)

func NeedsReload() -> bool:
	for g in GetDroneDock().DockedDrones:
		if (g.NeedsReload()):
			return true
	return !Cpt.IsResourceFull(STAT_CONST.STATS.MISSILE_SPACE)

func TogglePause(_t : bool):
	pass
#func TogglePause(t : bool):
	#Paused = t
	#if (t and BTree != null):
		#BTree.process_mode = Node.PROCESS_MODE_DISABLED
	#else: if (BTree != null):
		#BTree.process_mode = Node.PROCESS_MODE_PAUSABLE

func ToggleDocked(t : bool) -> void:
	Docked = t
	if (BTree != null):
		BTree.enabled = !t
		BTree.set_physics_process(!t)


#///////////////////////////////////////////////////
#██████  ███████ ███████ ████████ ██ ███    ██  █████  ████████ ██  ██████  ███    ██     ███    ███  █████  ███    ██  █████   ██████  ███    ███ ███████ ███    ██ ████████ 
#██   ██ ██      ██         ██    ██ ████   ██ ██   ██    ██    ██ ██    ██ ████   ██     ████  ████ ██   ██ ████   ██ ██   ██ ██       ████  ████ ██      ████   ██    ██    
#██   ██ █████   ███████    ██    ██ ██ ██  ██ ███████    ██    ██ ██    ██ ██ ██  ██     ██ ████ ██ ███████ ██ ██  ██ ███████ ██   ███ ██ ████ ██ █████   ██ ██  ██    ██    
#██   ██ ██           ██    ██    ██ ██  ██ ██ ██   ██    ██    ██ ██    ██ ██  ██ ██     ██  ██  ██ ██   ██ ██  ██ ██ ██   ██ ██    ██ ██  ██  ██ ██      ██  ██ ██    ██    
#██████  ███████ ███████    ██    ██ ██   ████ ██   ██    ██    ██  ██████  ██   ████     ██      ██ ██   ██ ██   ████ ██   ██  ██████  ██      ██ ███████ ██   ████    ██    

#Path to destination City
var Path : Array = []
#Current Stage of the path
var PathPart : int = 0

var PursuitPath : Array = []
var PursuitPathPart : int = 0

func SetPositionToInvestigate(Pos : Vector2) -> void:
	PositionToInvestigate = Pos
	if (Pos != Vector2(0,0)):
		if (!CanReachPosition(Pos)):
			FindPursuitPath(Pos)

func SetPursuitTarget(Target : MapShip) -> void:
	PursuingShips.append(Target)
	var Pos = Target.global_position
	if (!CanReachPosition(Pos)):
		FindPursuitPath(Pos)

#Crates a path to the destination city
func FigureOutPath() -> void:
	var cities = get_tree().get_nodes_in_group("EnemyDestinations")
	var nextcity = cities.find(CurrentPort) + Direction
	if (nextcity < 0 or nextcity > cities.size() - 1):
		Direction *= -1
		nextcity = cities.find(CurrentPort) + Direction
	
	#If path is full it means we are loading so skip path generation
	if (Path.size() == 0 and CurrentPort != null):
		var port = CurrentPort
		
		if (CurrentPort.NeighboringCities.size() == 0):
			await Map.GetInstance().MAP_NeighborsSet
			
		Path = Helper.GetInstance().FindPath(port.GetSpotName(), cities[nextcity].GetSpotName())
		if (Path.size() == 0):
			Path = Helper.GetInstance().FindPath(port.GetSpotName(), cities[nextcity].GetSpotName())
		PathPart = 1
	
	BTree = BT.instantiate() as BeehaveTree
	#TODO Test different tickrateson android
	BBoard = Blackboard.new()
	add_child(BBoard)
	BBoard.set_value("TickRate", 1)
	BTree.blackboard = BBoard
	ToggleDocked(Docked)
	add_child(BTree)
	#if (OS.get_name() == "Android"):
		#BTree.tick_rate = 10
	BBoard.set_value("TickRate", 1)

func CanReachDestination() -> bool:
	var dist = GetFuelRange()
	var actualdistance = global_position.distance_to(GetCurrentDestination())
	return dist >= actualdistance

func CanReachPosition(Pos : Vector2) -> bool:
	var dist = GetFuelRange()
	var actualdistance = global_position.distance_to(Pos)
	return dist >= actualdistance

func ToFarFromRefuel() -> bool:
	var dist = GetFuelRange()
	#var DistanceToDestination = global_position.distance_to(GetCurrentDestination())
	for g in get_tree().get_nodes_in_group("EnemyDestinations"):
		var spot = g as MapSpot
		if (spot.global_position.distance_to(global_position) < dist):
			return false
	return true

func SetNewDestination(DistName : String) -> void:
	Path = Helper.GetInstance().FindPath(CurrentPort.GetSpotName(), DistName)
	PathPart = 1

func FindPursuitPath(Pos : Vector2) -> void:
	var ClosestToPosition = Helper.GetInstance().GetClosestSpot(Pos)
	var Closest : MapSpot
	if (CurrentPort != null):
		Closest = CurrentPort
	else:
		Closest = Helper.GetInstance().GetClosestSpot(global_position)
	Path = Helper.GetInstance().FindPath(Closest.GetSpotName(), ClosestToPosition.GetSpotName())
	print("{0} has created a pursuit path from {1} to {2}".format([GetShipName(), Closest.GetSpotName(), ClosestToPosition.GetSpotName()]))
	PathPart = 1

func SetCurrentPort(P : MapSpot) -> void:
	CurrentPort = P
	for g in GetDroneDock().DockedDrones:
		g.SetCurrentPort(P)

func RemovePort():
	if (Docked):
		return
	#if (CurrentPort == RefuelSpot):
		#RefuelSpot = null
	CurrentPort = null
	for g in GetDroneDock().DockedDrones:
		g.CurrentPort = null

func IntersectPusruing() -> Vector2:
	#var ms = Time.get_ticks_msec()
	# Get the current position and velocity of the ship
	var ship_position
	var ship_velocity
	
	ship_position = PursuingShips[0].global_position
	ship_velocity = PursuingShips[0].GetShipSpeedVec()

	var Distance = global_position.distance_to(ship_position)
	
	if (Distance < 10):
		OnReachedPursuing()
	
	# Predict where the ship will be in a future time `t`
	var speed = GetShipSpeed()
	var time_to_interception = (global_position.distance_to(ship_position)) / (speed / 360)

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception
	#print("Calculating Intersection Point took " + var_to_str(Time.get_ticks_msec() - ms) + " msec")
	return predicted_position

func OnReachedPursuing() -> void:
	var plships : Array[MapShip] = []
	var hostships : Array[MapShip] = []
	if (Docked):
		hostships.append(Command)
		hostships.append_array(Command.GetDroneDock().DockedDrones)
	else:
		hostships.append(self)
		hostships.append_array(GetDroneDock().DockedDrones)

	var Ship : MapShip = PursuingShips[0]
	if (Ship.Command == null):
		plships.append(Ship)
		for g in Ship.GetDroneDock().GetDockedShips():
			if (g is HostileShip):
				hostships.append(g)
			else:
				plships.append(g)
	else:
		var FleetCommander = Ship.Command
		plships.append(FleetCommander)
		for g in FleetCommander.GetDroneDock().GetDockedShips():
			if (g is HostileShip):
				hostships.append(g)
			else:
				plships.append(g)
				
	OnPlayerShipMet.emit(plships, hostships)

func GetCurrentDestination() -> Vector2:
	var destination
	#if (RefuelSpot != null):
		#destination = RefuelSpot.global_position
	if (PursuingShips.size() > 0):
		destination = IntersectPusruing()
	else : if(PositionToInvestigate != Vector2.ZERO):
		if (PursuitPath.size() - 1 > PursuitPathPart):
			destination = Helper.GetInstance().GetCityByName(PursuitPath[PursuitPathPart]).global_position
		else:
			destination = PositionToInvestigate
			if (PositionToInvestigate.distance_to(global_position) <= 4):
				OnPositionInvestigated.emit(PositionToInvestigate)
	else: if(RefugeSpot != null) :
		destination = RefugeSpot.global_position
	else : if (Path.size() > 0):
		destination = Helper.GetInstance().GetCityByName(Path[PathPart]).global_position
	else : 
		destination = global_position
	return destination
#/////////////////////////////////////////////////////
#██████  ██   ██ ██    ██ ███████ ██  ██████ ███████     ███████ ██    ██ ███████ ███    ██ ████████ ███████ 
#██   ██ ██   ██  ██  ██  ██      ██ ██      ██          ██      ██    ██ ██      ████   ██    ██    ██      
#██████  ███████   ████   ███████ ██ ██      ███████     █████   ██    ██ █████   ██ ██  ██    ██    ███████ 
#██      ██   ██    ██         ██ ██ ██           ██     ██       ██  ██  ██      ██  ██ ██    ██         ██ 
#██      ██   ██    ██    ███████ ██  ██████ ███████     ███████   ████   ███████ ██   ████    ██    ███████ 
#Overriding events from MapShip as extra functionality is needed for enemies to let know of the COMMANDER of what was found/lost

func OnShipSeen(SeenBy : Node2D):
	if (Docked):
		Command.OnShipSeen(SeenBy)
		return
	if (VisibleBy.has(SeenBy)):
		return
	VisibleBy.append(SeenBy)
	if (VisibleBy.size() > 1):
		return
	
	MapPointerManager.GetInstance().AddShip(self, false, true)
	for g in GetDroneDock().DockedDrones:
		g.VisibleBy.append(SeenBy)
		MapPointerManager.GetInstance().AddShip(g, false)
		
	SimulationManager.GetInstance().SpeedToggle(false)
	
	Map.GetInstance().GetCamera().FrameCamToPos(global_position,1, false)

func wait(seconds : float) -> Signal:
	return get_tree().create_timer(seconds).timeout

func OnShipUnseen(UnSeenBy : Node2D):
	if (Docked):
		Command.OnShipUnseen(UnSeenBy)
		return
		
	VisibleBy.erase(UnSeenBy)
	for g in GetDroneDock().DockedDrones:
		g.VisibleBy.erase(UnSeenBy)
	#$Radar/Radar_Range.visible = VisibleBt.size() > 0
	
func BodyEnteredElint(area: Area2D) -> void:
	if (Captured):
		return
	if (area.get_parent() is HostileShip):
		return
	super(area)
	
func BodyLeftElint(area: Area2D) -> void:
	if (area.get_parent() is HostileShip):
		return
	if (area.get_parent() == self):
		return
	ElintContacts.erase(area.get_parent())
	ElintContact.emit(area.get_parent(), false)



func BodyEnteredRadar(Body : Area2D) -> void:
	if (Captured):
		return
	if (Body.get_parent() is PlayerDrivenShip):
		if (!Patrol and !Convoy):
			GarissonVisualContact(Body.get_parent())
		else:
			OnPlayerVisualContact.emit(Body.get_parent(), self)

var GarrissonVisualContacts : Array[MapShip]
var VisualContactCountdown = 10

func GarissonVisualContact(Ship : MapShip) -> void:
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.GARISSION_ALARM)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.GARISSION_ALARM)
		ActionTracker.GetInstance().ShowTutorial("Surprise Atack", "When entering enemy cities you are given a small time frame where you can surprise the enemy, that time is signified by the red bar above the enemies ship marker. If the bar finishes the alarm will be raised and an enemy patrol will start heading your way. Its recomended to invade cities with faster ships and initiating combat fast before getting detected", [], true)
		
	if (GarrissonVisualContacts.size() == 0):
		#if (Patrol):
			#VisualContactCountdown = 5
		#else:
		VisualContactCountdown = 10
			
	if (VisualContactCountdown < 0):
		OnPlayerVisualContact.emit(Ship, self)
		
	GarrissonVisualContacts.append(Ship)

func GarissonLostVisualContact(Ship : MapShip) -> void:
	if (VisualContactCountdown <= 0):
		OnPlayerVisualLost.emit(Ship)

	GarrissonVisualContacts.erase(Ship)
	if (GarrissonVisualContacts.size() == 0):
		VisualContactCountdown = 10

func BodyLeftRadar(Body : Area2D) -> void:
	if (Body.get_parent() is PlayerDrivenShip):
		if (!Patrol and !Convoy):
			GarissonLostVisualContact(Body.get_parent())
		else:
			OnPlayerVisualLost.emit(Body.get_parent())

func BodyEnteredBody(Body : Area2D) -> void:
	if (Captured):
		return
	if (Body.get_parent() is MapSpot):
		if (Docked):
			return
		var spot = Body.get_parent() as MapSpot
		SetCurrentPort(spot)
		spot.OnSpotAproached(self)
		for g in GetDroneDock().GetDockedShips():
			SetCurrentPort(spot)
			spot.OnSpotAproached(g)
		if (Path.has(spot.GetSpotName())):
			PathPart = Path.find(spot.GetSpotName())
			if (PathPart == Path.size() - 1):
				OnDestinationReached.emit(self)
			else :
				PathPart += 1
		if (PursuitPath.has(spot.GetSpotName())):
			if (PursuitPathPart < PursuitPath.size() - 1):
				PathPart += 1

	else :if (Body.get_parent() is PlayerDrivenShip):
		if (Destroyed):
			var Wonfunds = Cpt.ProvidingFunds
			World.GetInstance().PlayerWallet.AddFunds(Wonfunds)
			PopUpManager.GetInstance().DoFadeNotif("{0} drahma added".format([Wonfunds]))
			call_deferred("DestroyEnemyDebry")
		#TODO expand logic to allow for convoys with guards
		else : if (Convoy):
			Evaporate()
			World.GetInstance().PlayerWallet.AddFunds(Cpt.ProvidingFunds)
			PopUpManager.GetInstance().DoFadeNotif("Convoy Plundered\n{0} Drahma added".format([Cpt.ProvidingFunds]))


	#else : if (Body.get_parent() == RegroupTarget and CommingBack):
		#var Ship = Body.get_parent() as HostileShip
		#Ship.GetDroneDock().DockDrone(self, true)
		#var MyDroneDock = GetDroneDock()
		#for g in MyDroneDock.DockedDrones:
			#MyDroneDock.UndockDrone(g)
			#Ship.GetDroneDock().DockDrone(g, false)
		##for g in MyDroneDock.FlyingDrones:
			##g.Command = Ship
		#CommingBack = false
	
func BodyLeftBody(Body : Area2D) -> void:
	if (Body.get_parent() == CurrentPort):
		if (!Docked):
			CurrentPort.OnSpotDeparture(self)
			for g in GetDroneDock().GetDockedShips():
				CurrentPort.OnSpotDeparture(g)
			RemovePort()
			
	#if (Body.get_parent() is PlayerShip or Body.get_parent() is Drone):
		#OnShipUnseen(Body.get_parent())

#//////////////////////////////////////////////////////
 #██████  ███████ ████████ ████████ ███████ ██████  ███████ 
#██       ██         ██       ██    ██      ██   ██ ██      
#██   ███ █████      ██       ██    █████   ██████  ███████ 
#██    ██ ██         ██       ██    ██      ██   ██      ██ 
 #██████  ███████    ██       ██    ███████ ██   ██ ███████ 

func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL)
	stats.CurrentHull = Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)
	stats.FirePower = Cpt.GetStatFinalValue(STAT_CONST.STATS.FIREPOWER)
	stats.Speed = (Cpt.GetStatFinalValue(STAT_CONST.STATS.THRUST) * 1000) / Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	stats.ShipIcon = Cpt.ShipIcon
	stats.CaptainIcon = Cpt.CaptainPortrait
	stats.Name = GetShipName()
	stats.Funds = Cpt.ProvidingFunds
	stats.Weight = Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	stats.MaxShield =  Cpt.GetStatFinalValue(STAT_CONST.STATS.MAX_SHIELD)
	stats.Convoy = Convoy
	stats.Cards = Cpt.GetCardList()
	return stats
	
func GetShipName() -> String:
	return ShipName
	
func GetShipSpeed() -> float:
	if (Docked):
		return Command.GetShipSpeed()
	return super()

#/////////////////////////////////////////////////////////////
#███████  █████  ██    ██ ███████     ██ ██       ██████   █████  ██████  
#██      ██   ██ ██    ██ ██         ██  ██      ██    ██ ██   ██ ██   ██ 
#███████ ███████ ██    ██ █████     ██   ██      ██    ██ ███████ ██   ██ 
	 #██ ██   ██  ██  ██  ██       ██    ██      ██    ██ ██   ██ ██   ██ 
#███████ ██   ██   ████   ███████ ██     ███████  ██████  ██   ██ ██████ 

func GetSaveData() -> SD_HostileShip:
	var dat = SD_HostileShip.new()
	dat.Path = Path
	dat.PathPart = PathPart
	dat.Direction = Direction
	dat.Position = global_position
	dat.Cpt = Cpt
	dat.Scene = scene_file_path
	dat.Patrol = Patrol
	dat.Convoy = Convoy
	dat.ShipName = ShipName
	dat.Destroyed = Destroyed
	if (Command != null):
		dat.CommandName = Command.GetShipName()
	#dat.WeaponInventory = WeaponInventory
	return dat
	
func LoadSaveData(Dat : SD_HostileShip) -> void:
	#DestinationCity = GetCity(Dat.DestinationCityName)
	Path = Dat.Path
	PathPart = Dat.PathPart
	Direction = Dat.Direction
	Patrol = Dat.Patrol
	Convoy = Dat.Convoy
	#positioning happens on script wich respawns ship
	#global_position = Dat.Position
	
	Cpt = Dat.Cpt
	ShipName = Dat.ShipName
	Destroyed = Dat.Destroyed
	LoadingSave = true
	#WeaponInventory = Dat.WeaponInventory

#///////////////////////////////////////////////////
#██████   █████  ███    ███  █████   ██████  ██ ███    ██  ██████  
#██   ██ ██   ██ ████  ████ ██   ██ ██       ██ ████   ██ ██       
#██   ██ ███████ ██ ████ ██ ███████ ██   ███ ██ ██ ██  ██ ██   ███ 
#██   ██ ██   ██ ██  ██  ██ ██   ██ ██    ██ ██ ██  ██ ██ ██    ██ 
#██████  ██   ██ ██      ██ ██   ██  ██████  ██ ██   ████  ██████  

#When Killed outside of battle (With missile) enemies will leave behind wreck, then this bool will be true
var Destroyed : bool

func IsDamaged() -> bool:
	for g in GetDroneDock().DockedDrones:
		if (g.IsDamaged()):
			return true
	return !Cpt.IsResourceFull(STAT_CONST.STATS.HULL)

func Evaporate() -> void:
	OnShipDestroyed.emit(self)
	Destroyed = true
	if (ElintShape != null):
		ElintShape.queue_free()
	if (CurrentPort != null):
		CurrentPort.OnSpotDeparture(self)
	RadarShape.queue_free()
	MapPointerManager.GetInstance().RemoveShip(self)
	queue_free()
	get_parent().remove_child(self)

func Kill() -> void:
	OnShipDestroyed.emit(self)
	Destroyed = true
	if (ElintShape != null):
		ElintShape.queue_free()
		
	RadarShape.queue_free()
	ShipWrecked.emit()
	if (CurrentPort != null):
		CurrentPort.OnSpotDeparture(self)
	
func DestroyEnemyDebry() -> void:
	MapPointerManager.GetInstance().RemoveShip(self)
	get_parent().remove_child(self)
	queue_free()
	
