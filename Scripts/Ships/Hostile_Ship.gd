extends MapShip

class_name HostileShip

@export var Direction = -1


@export var ShipName : String
@export var Patrol : bool = true
@export var BT : PackedScene

var PursuingShips : Array[Node2D]
var LastKnownPosition : Vector2
#var Reloading : float = 0
var Path : Array = []
var PathPart : int = 0
var RefuelSpot : MapSpot
var VisibleBy : Array[Node2D]
var BTree : BeehaveTree

signal OnShipMet(FriendlyShips : Array[Node2D] , EnemyShips : Array[Node2D])
signal OnDestinationReached(Ship : HostileShip)
signal OnEnemyVisualContact(Ship : MapShip)
signal OnEnemyVisualLost(Ship : MapShip)
signal OnPositionInvestigated(Pos : Vector2)
signal ElintContact(Ship : MapShip, t : bool)

func  _ready() -> void:
	ToggleFuelRangeVisibility(false)
	Commander.GetInstance().RegisterSelf(self)

	for g in Cpt.CaptainStats:
		g.ForceMaxValue()

	_UpdateShipIcon(Cpt.ShipIcon)
	
	UpdateELINTTRange(Cpt.GetStatFinalValue(STAT_CONST.STATS.ELINT))
	UpdateVizRange(Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE))
	
	
	if (!Patrol):
		SetSpeed(0)
	else:
		var cities = get_tree().get_nodes_in_group("EnemyDestinations")
		var nextcity = cities.find(CurrentPort) + Direction
		if (nextcity < 0 or nextcity > cities.size() - 1):
			Direction *= -1
			nextcity = cities.find(CurrentPort) + Direction
		
		#If path is full it means we are loading so skip path generation
		if (Path.size() == 0 and CurrentPort != null):
			var port = CurrentPort
			if (CurrentPort.NeighboringCities.size() == 0):
				set_physics_process(false)
				await Map.GetInstance().MAP_NeighborsSet
				set_physics_process(true)
			Path = find_path(port.GetSpotName(), cities[nextcity].GetSpotName())
			if (Path.size() == 0):
				Path = find_path(port.GetSpotName(), cities[nextcity].GetSpotName())
			PathPart = 1
		
		BTree = BT.instantiate() as BeehaveTree
		
		var bb = Blackboard.new()
		add_child(bb)
		
		BTree.blackboard = bb
		ToggleDocked(Docked)
		add_child(BTree)
		
	TogglePause(SimulationManager.IsPaused())
	#MapPointerManager.GetInstance().AddShip(self, false)
	#$Elint.connect("area_entered", _on_elint_area_entered)
	#$Elint.connect("area_exited", _on_elint_area_exited)
func _physics_process(delta: float) -> void:
	if (Paused):
		return
	UpdateElint(delta)
	
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
	
	if (CurrentPort != null):
		Cpt.FullyRefilStat(STAT_CONST.STATS.MISSILE_SPACE)
	#Reloading = 4

func UpdateElint(delta: float) -> void:
	d -= delta
	if (d > 0):
		return
	d = 0.4
	var BiggestLevel = 0
	var ClosestShip : MapShip
	for g in ElintContacts.size():
		var ship = ElintContacts.keys()[g]
		var lvl = ElintContacts.values()[g]
		var Newlvl = GetElintLevel(global_position.distance_to(ship.global_position))
		if (Newlvl > BiggestLevel):
			BiggestLevel = Newlvl
			ClosestShip = ship
		if (Newlvl != lvl):
			ElintContacts[ship] = Newlvl
	if (BiggestLevel > 0):
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
	return (total_fuel * 10 * effective_efficiency) / fleetsize
	
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
	Path = find_path(CurrentPort.GetSpotName(), DistName)
	PathPart = 1
func SetCurrentPort(P : MapSpot) -> void:
	CurrentPort = P
	Cpt.FullyRefilStat(STAT_CONST.STATS.MISSILE_SPACE)
	#if (P == RefuelSpot):
		#RefuelSpot = null
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
	# Get the current position and velocity of the ship
	var ship_position
	var ship_velocity
	
	ship_position = PursuingShips[0].position
	ship_velocity = PursuingShips[0].GetShipSpeedVec()

	# Predict where the ship will be in a future time `t`
	var time_to_interception = (position.distance_to(ship_position)) / Cpt.GetStatFinalValue(STAT_CONST.STATS.SPEED)

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception
	return predicted_position
func OnShipSeen(SeenBy : Node2D):
	if (VisibleBy.has(SeenBy)):
		return
	VisibleBy.append(SeenBy)
	if (VisibleBy.size() > 1):
		return
	MapPointerManager.GetInstance().AddShip(self, false)
	SimulationManager.GetInstance().TogglePause(true)
func OnShipUnseen(UnSeenBy : Node2D):
	VisibleBy.erase(UnSeenBy)
	#$Radar/Radar_Range.visible = VisibleBt.size() > 0
func _on_area_entered(area: Area2D) -> void:
	if (area.get_parent() is MapSpot):
		if (Docked):
			return
		var spot = area.get_parent() as MapSpot
		if (Path.has(spot.GetSpotName()) and Patrol):
			SetCurrentPort(spot)
			PathPart = Path.find(spot.GetSpotName())
			if (PathPart == Path.size() - 1):
				OnDestinationReached.emit(self)
			else :
				PathPart += 1
		if (spot == RefuelSpot and Patrol):
			SetCurrentPort(RefuelSpot)
	else :if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		var IsRadar = area.get_collision_layer_value(2)
		if (IsRadar):
			OnShipSeen(area.get_parent())
		else:
			var plships : Array[Node2D] = []
			var hostships : Array[Node2D] = []
			if (Docked):
				hostships.append(Command)
				hostships.append_array(Command.GetDroneDock().DockedDrones)
			else:
				hostships.append(self)
				hostships.append_array(GetDroneDock().DockedDrones)
				
			if (area.get_parent() is PlayerShip):
				var player = area.get_parent() as PlayerShip
				plships.append(player)
				plships.append_array(player.GetDroneDock().DockedDrones)
			else:
				var drn = area.get_parent() as Drone
				if (drn.Docked):
					var player = drn.Command
					plships.append(player)
					plships.append_array(player.GetDroneDock().DockedDrones)
				else:
					plships.append(drn)
					plships.append_array(drn.GetDroneDock().DockedDrones)
					
			OnShipMet.emit(plships, hostships)
	else : if (area.get_parent() == Command and CommingBack):
		var Ship = area.get_parent() as HostileShip
		Ship.GetDroneDock().DockDrone(self, true)
		var MyDroneDock = GetDroneDock()
		for g in MyDroneDock.DockedDrones:
			MyDroneDock.UndockDrone(g, false)
			Ship.GetDroneDock().DockDrone(g, false)
		for g in MyDroneDock.FlyingDrones:
			g.Command = Ship
		CommingBack = false
func _on_area_exited(area: Area2D) -> void:
	if (area.get_parent() == CurrentPort):
		if (!Docked):
			RemovePort()
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		OnShipUnseen(area.get_parent())
func _on_elint_area_entered(area: Area2D) -> void:
	if (area.get_parent() is HostileShip):
		return
	super(area)
func _on_elint_area_exited(area: Area2D) -> void:
	if (area.get_parent() is HostileShip):
		return
	if (area.get_parent() == self):
		return
	ElintContacts.erase(area.get_parent())
	ElintContact.emit(area.get_parent(), false)
func _on_radar_2_area_entered(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		OnEnemyVisualContact.emit(area.get_parent())
		#PursuingShips.append(area.get_parent())
func _on_radar_2_area_exited(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		OnEnemyVisualLost.emit(area.get_parent())
		#PursuingShips.erase(area.get_parent())
		#LastKnownPosition = area.get_parent().global_position
func find_path(start_city: String, end_city: String) -> Array:
	#var cities = get_tree().get_nodes_in_group("EnemyDestinations")
	var queue = []
	var visited = {}
	var parent = {}
	
	# Initialize the BFS
	queue.append(start_city)
	visited[start_city] = true
	parent[start_city] = null
	
	# Perform the BFS
	while queue.size() > 0:
		var current_city = queue.pop_front()
		
		# If we reached the end_city, reconstruct the path
		if current_city == end_city:
			return reconstruct_path(parent, end_city)
		
		# Explore neighboring cities
		var Cit = GetCity(current_city)
		if (Cit.NeighboringCities.size() == 0):
			printerr(Cit.GetSpotName + " has no neighboring cities. Seems sus.")
		for neighbor in Cit.NeighboringCities:
			if not visited.has(neighbor):
				queue.append(neighbor)
				visited[neighbor] = true
				parent[neighbor] = current_city
	
	# If no path is found, return an empty array
	print(GetShipName() + " has failed to find a path from " + start_city + " to " + end_city)
	return []
func reconstruct_path(parent: Dictionary, end_city: String) -> Array:
	var path = []
	var current_city = end_city
	while current_city != null:
		path.append(current_city)
		current_city = parent[current_city]
		
	path.reverse()  # Reverse the path to get it from start to end
	return path
func GetCurrentDestination() -> Vector2:
	var destination
	#if (RefuelSpot != null):
		#destination = RefuelSpot.global_position
	if (PursuingShips.size() > 0):
		destination = IntersectPusruing()
	else : if(LastKnownPosition != Vector2.ZERO):
		destination = LastKnownPosition
		if (LastKnownPosition.distance_to(global_position) < 0.5):
			OnPositionInvestigated.emit(LastKnownPosition)
	else : if (Path.size() > 0):
		destination = GetCity(Path[PathPart]).global_position
	else : 
		destination = global_position
	return destination
func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL)
	stats.FirePower = Cpt.GetStatFinalValue(STAT_CONST.STATS.FIREPOWER)
	stats.Speed = Cpt.GetStatFinalValue(STAT_CONST.STATS.SPEED)
	stats.ShipIcon = Cpt.ShipIcon
	stats.CaptainIcon = Cpt.CaptainPortrait
	stats.Name = Cpt.CaptainName
	return stats
func GetCity(CityName : String) -> MapSpot:
	var cities = get_tree().get_nodes_in_group("EnemyDestinations")
	var CorrectCity : MapSpot
	for g in cities:
		var cit = g as MapSpot
		if (cit.GetSpotName() == CityName):
			CorrectCity = cit
			break
	return CorrectCity
func GetShipName() -> String:
	return ShipName
func GetShipSpeed() -> float:
	if (Docked):
		return Command.GetShipSpeed()
	return super()

func GetSaveData() -> SD_HostileShip:
	var dat = SD_HostileShip.new()
	dat.Path = Path
	dat.PathPart = PathPart
	dat.Direction = Direction
	dat.Position = global_position
	dat.Cpt = Cpt
	dat.Scene = scene_file_path
	dat.Patrol = Patrol
	dat.ShipName = ShipName
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
	#positioning happens on script wich respawns ship
	#global_position = Dat.Position
	Cpt = Dat.Cpt
	ShipName = Dat.ShipName
	#WeaponInventory = Dat.WeaponInventory 
func IsFuelFull() -> bool:
	for g in GetDroneDock().DockedDrones:
		if (!g.IsFuelFull()):
			return false
	return Cpt.IsResourceFull(STAT_CONST.STATS.FUEL_TANK)
func IsDamaged() -> bool:
	for g in GetDroneDock().DockedDrones:
		if (g.IsDamaged()):
			return true
	return !Cpt.IsResourceFull(STAT_CONST.STATS.HULL)
func TogglePause(t : bool):
	Paused = t
	if (t and BTree != null):
		BTree.process_mode = Node.PROCESS_MODE_DISABLED
	else: if (BTree != null):
		BTree.process_mode = Node.PROCESS_MODE_PAUSABLE
func ChangeSimulationSpeed(i : int):
	super(i)
	#$BeehaveTree.tick_rate = 1 / i
func ToggleDocked(t : bool) -> void:
	Docked = t
	if (BTree != null):
		BTree.enabled = !t
		BTree.set_physics_process(!t)
