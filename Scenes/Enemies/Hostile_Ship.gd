extends MapShip

class_name HostileShip

@export var Direction = -1

@export var Cpt : Captain

@export var ShipName : String
@export var Patrol : bool = true
@export var ShipCallsign : String = "P"
#var Pursuing = false
var PursuingShips : Array[Node2D]
var LastKnownPosition : Vector2

var DestinationCity : MapSpot
var RefuelSpot : MapSpot
var Docked : bool = false
var VisibleBy : Array[Node2D]

@export var FleetShips : Array[PackedScene]
#var VisibleBy : Array[Node2D] = []

signal OnShipMet(FriendlyShips : Array[Node2D] , EnemyShips : Array[Node2D])
signal OnDestinationReached(Ship : HostileShip)
signal OnEnemyVisualContact(Ship : MapShip)
signal OnEnemyVisualLost(Ship : MapShip)
signal OnPositionInvestigated(Pos : Vector2)
signal ElintContact(Ship : MapShip, t : bool)

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
		ElintContact.emit(ClosestShip ,true)
		
func SeenShips() -> bool:
	for g in VisibleBy:
		if (g == null):
			continue
		if (g is PlayerShip or g is Drone):
			return true
	return false

func CanReachDestination() -> bool:
	var dist = Cpt.GetStat("FUEL_TANK").CurrentVelue * 10 * Cpt.GetStat("FUEL_EFFICIENCY").GetStat()
	var actualdistance = global_position.distance_to(GetCurrentDestination())
	return dist >= actualdistance

func GetCurrentDestination() -> Vector2:
	var destination
	if (PursuingShips.size() > 0):
		destination = PursuingShips[0].global_position
	else : if(LastKnownPosition != Vector2.ZERO):
		destination = LastKnownPosition
	else : if (RefuelSpot != null):
		destination = RefuelSpot.global_position
	else :
		destination = DestinationCity.global_position
	return destination
	
func FindRefuelSpot() -> void:
	var dist = Cpt.GetStat("FUEL_TANK").CurrentVelue * 10 * Cpt.GetStat("FUEL_EFFICIENCY").GetStat()
	var DistanceToDestination = global_position.distance_to(GetCurrentDestination())
	for g in get_tree().get_nodes_in_group("EnemyDestinations"):
		var spot = g as MapSpot
		if (spot.global_position.distance_to(global_position) >= dist):
			continue
		if (spot.global_position.distance_to(GetCurrentDestination()) > DistanceToDestination):
			continue
		if (spot == CurrentPort):
			continue
		RefuelSpot = spot
		print(ShipName + " will take a detour through " + RefuelSpot.SpotName + " to refuel")
		return

func  _ready() -> void:
	Commander.GetInstance().RegisterSelf(self)
	for g in FleetShips:
		var s = g.instantiate() as HostileShip
		#get_parent().add_child(s)
		$ShipDock.AddShip(s)
	#visible = false
	for g in Cpt.CaptainStats:
		g.CurrentVelue = g.GetStat()
	GetShipAcelerationNode().position.x = Cpt.GetStatValue("SPEED")
	UpdateELINTTRange(Cpt.GetStatValue("ELINT"))
	UpdateVizRange(Cpt.GetStatValue("RADAR_RANGE"))
	var cities = get_tree().get_nodes_in_group("EnemyDestinations")
	if (!Patrol):
		GetShipAcelerationNode().position.x = 0
	var nextcity = cities.find(DestinationCity) + Direction
	if (nextcity < 0 or nextcity > cities.size() - 1):
		Direction *= -1
		nextcity = cities.find(DestinationCity) + Direction
	DestinationCity = cities[nextcity]
	call_deferred("AimForCity")
	MapPointerManager.GetInstance().AddShip(self, false)
	$Elint.connect("area_entered", _on_elint_area_entered)
	$Elint.connect("area_exited", _on_elint_area_exited)
func AimForCity():
	ShipLookAt(DestinationCity.global_position)
	
func GetShipMaxSpeed() -> float:
	return Cpt.GetStatValue("SPEED")
	
func GetCity(CityName : String) -> MapSpot:
	var cities = get_tree().get_nodes_in_group("EnemyDestinations")
	var CorrectCity : MapSpot
	for g in cities:
		var cit = g as MapSpot
		if (cit.GetSpotName() == CityName):
			CorrectCity = cit
			break
	return CorrectCity
	
func Damage(amm : float) -> void:
	Cpt.GetStat("HULL").CurrentVelue -= amm
	super(amm)
	
func IsDead() -> bool:
	return Cpt.GetStat("HULL").CurrentVelue <= 0
	
func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = Cpt.GetStatValue("HULL")
	stats.FirePower = Cpt.GetStatValue("FIREPOWER")
	stats.ShipIcon = Cpt.ShipIcon
	stats.CaptainIcon = Cpt.CaptainPortrait
	stats.Name = "Enemy"
	return stats

func _physics_process(delta: float) -> void:
	if (Paused or Docked):
		return
	
	UpdateElint(delta)
	
	if (!Patrol):
		return
	
	if (CurrentPort != null and Cpt.GetStat("FUEL_TANK").CurrentVelue < Cpt.GetStat("FUEL_TANK").GetStat()):
		Cpt.GetStat("FUEL_TANK").CurrentVelue += 0.05 * SimulationSpeed
		if (Cpt.GetStat("FUEL_TANK").CurrentVelue >= Cpt.GetStat("FUEL_TANK").GetStat()):
			GetShipAcelerationNode().position.x = Cpt.GetStat("SPEED").GetStat()
			
		else :
			return
	if (!CanReachDestination()):
		FindRefuelSpot()
	if (RefuelSpot != null):
		ShipLookAt(RefuelSpot.global_position)
	else : if (PursuingShips.size() > 0 or LastKnownPosition != Vector2.ZERO):
		updatedronecourse()
	for g in  SimulationSpeed:
		var ac = GetShipAcelerationNode().global_position
		global_position = ac
		var ftoconsume =  GetShipAcelerationNode().position.x / 10 / Cpt.GetStatValue("FUEL_EFFICIENCY")
		Cpt.GetStat("FUEL_TANK").CurrentVelue -= ftoconsume
		
	#for g in VisibleBy:
		#if (g == null):
			#continue
		#if (g is Missile):
			#continue
		#VisibleBt[g] = min(VisibleBt[g] + 0.05, 10)
		#if (VisibleBt[g] == 10 and !PursuingShips.has(g)):
			#LastKnownPosition = g.global_position
	

func updatedronecourse():
	# Get the current position and velocity of the ship
	var ship_position
	var ship_velocity
	if (PursuingShips.size() > 0):
		ship_position = PursuingShips[0].position
		ship_velocity = PursuingShips[0].GetShipSpeedVec()
	else:
		ship_position = LastKnownPosition
		ship_velocity = Vector2.ZERO
		if (ship_position.distance_to(global_position) < 10):
			OnPositionInvestigated.emit(LastKnownPosition)
			return
	# Predict where the ship will be in a future time `t`
	var time_to_interception = (position.distance_to(ship_position)) / Cpt.GetStatValue("SPEED")

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception
	ShipLookAt(predicted_position)
	GetShipAcelerationNode().position.x = Cpt.GetStatValue("SPEED")
	#global_position = GetShipAcelerationNode().global_position
	
func _on_radar_2_area_entered(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		OnEnemyVisualContact.emit(area.get_parent())
		#PursuingShips.append(area.get_parent())
		
func _on_radar_2_area_exited(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		OnEnemyVisualLost.emit(area.get_parent())
		#PursuingShips.erase(area.get_parent())
		#LastKnownPosition = area.get_parent().global_position
		
#whan this ship gets seen by player or friendly drone
func OnShipSeen(SeenBy : Node2D):
	#$Radar/Radar_Range.visible = true
	#visible = true
	if (VisibleBy.has(SeenBy)):
		return
	#VisibleBy[SeenBy] = 0
	if (VisibleBy.size() > 1):
		return
	MapPointerManager.GetInstance().AddShip(self, false)
	SimulationManager.GetInstance().TogglePause(true)
	
func OnShipUnseen(UnSeenBy : Node2D):
	VisibleBy.erase(UnSeenBy)
	#$Radar/Radar_Range.visible = VisibleBt.size() > 0


func _on_area_entered(area: Area2D) -> void:
	if (area.get_parent() == DestinationCity and Patrol):
		OnDestinationReached.emit(self)
		CurrentPort = DestinationCity
		if (Cpt.GetStat("FUEL_TANK").CurrentVelue < Cpt.GetStat("FUEL_TANK").GetStat()):
			GetShipAcelerationNode().position.x = 0
	if (area.get_parent() == RefuelSpot and Patrol):
		CurrentPort = RefuelSpot
		RefuelSpot = null
		ShipLookAt(DestinationCity.global_position)
		if (Cpt.GetStat("FUEL_TANK").CurrentVelue < Cpt.GetStat("FUEL_TANK").GetStat()):
			GetShipAcelerationNode().position.x = 0
	else :if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		var bit = area.get_collision_layer_value(3) or area.get_collision_layer_value(4)
		if (bit):
			if (area.get_parent() is PlayerShip):
				var player = area.get_parent() as PlayerShip
				var ships : Array[Node2D] = []
				ships.append(player)
				ships.append_array(player.GetDroneDock().DockedDrones)
				var hostships : Array[Node2D] = []
				hostships.append(self)
				OnShipMet.emit(ships, hostships)
			else:
				var plships : Array[Node2D] = []
				var drn = area.get_parent() as Drone
				if (drn.Docked):
					var player = PlayerShip.GetInstance()
					plships.append(player)
					plships.append_array(player.GetDroneDock().DockedDrones)
				else:
					plships.append(drn)
				
				var hostships : Array[Node2D] = []
				hostships.append(self)
				OnShipMet.emit(plships, hostships)
		else:
			OnShipSeen(area.get_parent())

func _on_area_exited(area: Area2D) -> void:
	if (area.get_parent() == CurrentPort):
		CurrentPort = null
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		OnShipUnseen(area.get_parent())

func GetSaveData() -> SD_HostileShip:
	var dat = SD_HostileShip.new()
	if (DestinationCity != null):
		dat.DestinationCityName = DestinationCity.GetSpotName()
	dat.Direction = Direction
	dat.LastKnownPosition = LastKnownPosition
	dat.Position = global_position
	dat.Cpt = Cpt
	dat.Scene = scene_file_path
	dat.ShipName = ShipName
	return dat
func LoadSaveData(Dat : SD_HostileShip) -> void:
	DestinationCity = GetCity(Dat.DestinationCityName)
	Direction = Dat.Direction
	LastKnownPosition = Dat.LastKnownPosition
	global_position = Dat.Position
	Cpt = Dat.Cpt
	ShipName = Dat.ShipName
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
	
