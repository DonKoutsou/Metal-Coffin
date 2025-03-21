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

signal OnPlayerShipMet(PlayerSquad : Array[Node2D] , EnemySquad : Array[Node2D])
signal OnDestinationReached(Ship : HostileShip)
signal OnPlayerVisualContact(Ship : MapShip, SeenBy : HostileShip)
signal OnPlayerVisualLost(Ship : MapShip)
signal OnPositionInvestigated(Pos : Vector2)
signal ElintContact(Ship : MapShip, t : bool)
signal ShipSpawned
signal ShipWrecked

func  _ready() -> void:
	ToggleFuelRangeVisibility(false)
	call_deferred("InitialiseShip")

	#sMapPointerManager.GetInstance().AddShip(self, false)

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
	
	TogglePause(SimulationManager.IsPaused())


func _physics_process(delta: float) -> void:
	if (Captured):
		return
	UpdateElint(delta)
	if (Paused):
		return
	
	if (UseDefaultBehavior):
		var SimulationSpeed = SimulationManager.SimSpeed()
		if (GarrissonVisualContacts.size() > 0 and VisualContactCountdown > 0):
			VisualContactCountdown -= 0.1 * SimulationSpeed
			if (VisualContactCountdown < 0):
				for c in GarrissonVisualContacts:
					OnPlayerVisualContact.emit(c, self)
				add_child(AlarmVisual.instantiate())
		
		if (!Cpt.IsResourceFull(STAT_CONST.STATS.HULL)):
			Cpt.RefillResource(STAT_CONST.STATS.HULL ,0.02 * SimulationSpeed)
		
		if (!Cpt.IsResourceFull(STAT_CONST.STATS.MISSILE_SPACE)):
			Cpt.RefillResource(STAT_CONST.STATS.MISSILE_SPACE ,0.005 * SimulationSpeed)
			
	else: if (BTree != null):
		BTree.Process_Tree()
		

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

func TogglePause(t : bool):
	Paused = t
	if (t and BTree != null):
		BTree.process_mode = Node.PROCESS_MODE_DISABLED
	else: if (BTree != null):
		BTree.process_mode = Node.PROCESS_MODE_PAUSABLE

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
	
	ship_position = PursuingShips[0].position
	ship_velocity = PursuingShips[0].GetShipSpeedVec()

	# Predict where the ship will be in a future time `t`
	var time_to_interception = (position.distance_to(ship_position)) / Cpt.GetStatFinalValue(STAT_CONST.STATS.SPEED)

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception
	#print("Calculating Intersection Point took " + var_to_str(Time.get_ticks_msec() - ms) + " msec")
	return predicted_position

func GetCurrentDestination() -> Vector2:
	var destination
	#if (RefuelSpot != null):
		#destination = RefuelSpot.global_position
	if (PursuingShips.size() > 0):
		destination = IntersectPusruing()
	else : if(PositionToInvestigate != Vector2.ZERO):
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
	if (VisibleBy.has(SeenBy)):
		return
	VisibleBy.append(SeenBy)
	if (VisibleBy.size() > 1):
		return
	
	MapPointerManager.GetInstance().AddShip(self, false)
	#SimulationManager.GetInstance().TogglePause(true)
	ShipCamera.GetInstance().FrameCamToPos(global_position)

func wait(seconds : float) -> Signal:
	return get_tree().create_timer(seconds).timeout

func OnShipUnseen(UnSeenBy : Node2D):
	VisibleBy.erase(UnSeenBy)
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
	if (Body.get_parent() is PlayerShip or Body.get_parent() is Drone):
		if (!Patrol and !Convoy):
			GarissonVisualContact(Body.get_parent())
		else:
			OnPlayerVisualContact.emit(Body.get_parent(), self)

var GarrissonVisualContacts : Array[MapShip]
var VisualContactCountdown = 10

func GarissonVisualContact(Ship : MapShip) -> void:
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
	if (Body.get_parent() is PlayerShip or Body.get_parent() is Drone):
		if (!Patrol and !Convoy):
			GarissonLostVisualContact(Body.get_parent())
		else:
			OnPlayerVisualLost.emit(Body.get_parent())

func BodyEnteredBody(Body : Area2D) -> void:
	if (Captured):
		return
	if (Body.get_parent() is MapSpot):
		#if (Docked):
			#return
		var spot = Body.get_parent() as MapSpot
		if (Path.has(spot.GetSpotName())):
			
			SetCurrentPort(spot)
			PathPart = Path.find(spot.GetSpotName())
			if (PathPart == Path.size() - 1):
				OnDestinationReached.emit(self)
			else :
				PathPart += 1
				
		if (spot == RefuelSpot):
			SetCurrentPort(RefuelSpot)
	else :if (Body.get_parent() is PlayerShip or Body.get_parent() is Drone):
		if (Destroyed):
			var Wonfunds = Cpt.ProvidingFunds
			World.GetInstance().PlayerWallet.AddFunds(Wonfunds)
			PopUpManager.GetInstance().DoFadeNotif("{0} drahma added".format([Wonfunds]))
			call_deferred("DestroyEnemyDebry")
		#TODO expand logic to allow for convoys with guards
		else : if (Convoy):
			var Ship = Body.get_parent()
			var FleetCommander : MapShip
			if (Ship.Command == null):
				FleetCommander = Ship
			else:
				FleetCommander = Ship.Command
			FleetCommander.GetDroneDock().AddCaptive(self)
		else:
			var plships : Array[Node2D] = []
			var hostships : Array[Node2D] = []
			if (Docked):
				hostships.append(Command)
				hostships.append_array(Command.GetDroneDock().DockedDrones)
			else:
				hostships.append(self)
				hostships.append_array(GetDroneDock().DockedDrones)
				
			if (Body.get_parent() is PlayerShip):
				var player = Body.get_parent() as PlayerShip
				plships.append(player)
				plships.append_array(player.GetDroneDock().DockedDrones)
			else:
				var drn = Body.get_parent() as Drone
				if (drn.Docked):
					var player = drn.Command
					plships.append(player)
					plships.append_array(player.GetDroneDock().DockedDrones)
				else:
					plships.append(drn)
					plships.append_array(drn.GetDroneDock().DockedDrones)
					
			OnPlayerShipMet.emit(plships, hostships)
	else : if (Body.get_parent() == Command and CommingBack):
		var Ship = Body.get_parent() as HostileShip
		Ship.GetDroneDock().DockDrone(self, true)
		var MyDroneDock = GetDroneDock()
		for g in MyDroneDock.DockedDrones:
			MyDroneDock.UndockDrone(g, false)
			Ship.GetDroneDock().DockDrone(g, false)
		for g in MyDroneDock.FlyingDrones:
			g.Command = Ship
		CommingBack = false
	
func BodyLeftBody(Body : Area2D) -> void:
	if (Body.get_parent() == CurrentPort):
		if (!Docked):
			RemovePort()
	if (Body.get_parent() is PlayerShip or Body.get_parent() is Drone):
		OnShipUnseen(Body.get_parent())

#//////////////////////////////////////////////////////
 #██████  ███████ ████████ ████████ ███████ ██████  ███████ 
#██       ██         ██       ██    ██      ██   ██ ██      
#██   ███ █████      ██       ██    █████   ██████  ███████ 
#██    ██ ██         ██       ██    ██      ██   ██      ██ 
 #██████  ███████    ██       ██    ███████ ██   ██ ███████ 

func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)
	stats.FirePower = Cpt.GetStatFinalValue(STAT_CONST.STATS.FIREPOWER)
	stats.Speed = Cpt.GetStatFinalValue(STAT_CONST.STATS.SPEED)
	stats.ShipIcon = Cpt.ShipIcon
	stats.CaptainIcon = Cpt.CaptainPortrait
	stats.Name = GetShipName()
	stats.Funds = Cpt.ProvidingFunds
	var EnemyCards : Dictionary
	for g in Cpt.Cards:
		EnemyCards[g] = 1
	stats.Cards = EnemyCards
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

func DestroyEnemyDebry() -> void:
	MapPointerManager.GetInstance().RemoveShip(self)
	queue_free()
	get_parent().remove_child(self)
