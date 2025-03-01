extends Node2D

class_name Commander

@export var Armaments : Dictionary

@export_flags_2d_physics var layers_2d_physics

static var Instance : Commander

var Fleet : Array[HostileShip] = []

var PursuitOrders : Array[PursuitOrder]
var InvestigationOrders : Array[InvestigationOrder]

var EnemyPositionsToInvestigate : Dictionary
var KnownEnemies : Dictionary

var SimPaused : bool = false
var SimSpeed : int = 1

func OnSimulationPaused(t : bool) -> void:
	SimPaused = t
	$BeehaveTree.set_physics_process(!t)
func OnSimulationSpeedChanged(i : int) -> void:
	SimSpeed = i
	#$BeehaveTree.tick_rate = i
#ORDER MANAGEMENT////////////////////////////////////////////////////////////////
func OrderShipToAtack(Ship : HostileShip, Target : MapShip) -> void:
	var Armament = GetCheapestArmamentForDistance(Ship.global_position.distance_to(Target.global_position))
	Ship.Cpt.ConsumeResource(STAT_CONST.STATS.MISSILE_SPACE, Armaments[Armament])
	Ship.LaunchMissile(Armament, Target.global_position)
	
func OrderShipToPursue(Ship : HostileShip, Target : MapShip) -> void:
	Ship.PursuingShips.append(Target)
	for g in PursuitOrders:
		if (g.Target == Target):
			g.Receivers.append(Ship)
			return
	#if no ongoing order found make a new one
	var Order = PursuitOrder.new()
	Order.Receivers.append(Ship)
	Order.Target = Target
	Target.connect("OnShipDestroyed", PursuitOrderCompleted)
	PursuitOrders.append(Order)
#completing pusuit mission means ships has been killed
#remove mission from list and make sure all assigned ships know about it
func PursuitOrderCompleted(TargetShip : MapShip) -> void:
	for g in PursuitOrders:
		if (g.Target == TargetShip):
			for z in g.Receivers:
				z.PursuingShips.clear()
			PursuitOrders.erase(g)
			TargetShip.disconnect("OnShipDestroyed", PursuitOrderCompleted)
			return

func PursuitOrderCanceled(TargetShip : MapShip) -> void:
	for g in PursuitOrders:
		if (g.Target == TargetShip):
			for z in g.Receivers:
				z.PursuingShips.clear()
			PursuitOrders.erase(g)
			TargetShip.disconnect("OnShipDestroyed", PursuitOrderCompleted)
			return

func OrderShipToInvestigate(Ship : HostileShip, Target : Vector2, SignalOrigin : MapShip) -> void:
	Ship.LastKnownPosition = Target
	for g in InvestigationOrders:
		if (g.ShipTrigger == SignalOrigin):
			g.Receivers.append(Ship)
			Ship.connect("OnPositionInvestigated", InvestigationOrderComplete)
			print(Ship.ShipName + " has been ordered to investigate position : " + var_to_str(Target) + " for potential enemies.")
			return
	var Order = InvestigationOrder.new()
	Order.Receivers.append(Ship)
	Ship.connect("OnPositionInvestigated", InvestigationOrderComplete)
	Order.Target = Target
	Order.ShipTrigger = SignalOrigin
	InvestigationOrders.append(Order)
	print(Ship.ShipName + " has been ordered to investigate position : " + var_to_str(Target) + " for potential enemies.")

func UpdateInvestigationPos(newpos : Vector2, originship : MapShip) -> void:
	for g in InvestigationOrders:
		if (g.ShipTrigger == originship):
			g.Target = newpos
			for z in g.Receivers:
				z.LastKnownPosition = newpos
	print("Investigation position updated to : " + var_to_str(newpos))
	
func InvestigationOrderComplete(Pos : Vector2) -> void:
	for g in InvestigationOrders:
		if (g.Target == Pos):
			for z in g.Receivers:
				z.disconnect("OnPositionInvestigated", InvestigationOrderComplete)
				z.LastKnownPosition = Vector2.ZERO
				#z.ShipLookAt(z.GetCurrentDestination())
			InvestigationOrders.erase(g)
			EnemyPositionsToInvestigate.erase(g.ShipTrigger)
			print("Position : " + var_to_str(Pos) + "has been investigated.")
			return
	
#SIGNAL RECEIVERS///////////////////////////////////////////////////
func OnShipDestroyed(Ship : HostileShip) -> void:
	Fleet.erase(Ship)
	#DissconnectSignals(Ship)
	if (Ship.GetDroneDock().DockedDrones.size() > 0):
		var NewCommander = Ship.GetDroneDock().DockedDrones[0] as HostileShip
		var BT = Ship.BTree
		if (BT != null):
			Ship.remove_child(BT)
			NewCommander.addchild(BT)
			NewCommander.BTree = BT
			NewCommander.Path = Ship.Path
			NewCommander.PathPart = Ship.PathPart
		var DockedDrones = []
		DockedDrones.append_array(Ship.GetDroneDock().DockedDrones)
		for g in DockedDrones:
			Ship.GetDroneDock().UndockShip(g)
			if (g != NewCommander):
				NewCommander.GetDroneDock().DockShip(g)
		
		
	var POrdersToErase : Array[PursuitOrder] = []
	#if (Ship.PursuingShips.size() > 0):
	for g in PursuitOrders:
		if (g.Receivers.has(Ship)):
			g.Receivers.erase(Ship)
			if (g.Receivers.size() == 0):
				POrdersToErase.append(g)
	var IOrdersToErase : Array[InvestigationOrder] = []
	#if (Ship.LastKnownPosition != Vector2.ZERO):
	for g in InvestigationOrders:
		if (g.Receivers.has(Ship)):
			g.Receivers.erase(Ship)
			if (g.Receivers.size() == 0):
				IOrdersToErase.append(g)
	for g in POrdersToErase:
		PursuitOrderCanceled(g.Target)
	for g in IOrdersToErase:
		InvestigationOrders.erase(g)
func OnEnemySeen(Ship : MapShip, SeenBy : HostileShip) -> void:
	#if an enemy that had its location investigated is seen 
	#make sure to call of all investigation on its previusly known location
	print(Ship.GetShipName() + " has been located.")
	if (EnemyPositionsToInvestigate.keys().has(Ship)):
		if (IsShipsPositionUnderInvestigation(Ship)):
			print(Ship.GetShipName() + "'s position was under investigation, investigation order has been canceled")
			InvestigationOrderComplete(EnemyPositionsToInvestigate[Ship].Position)
		EnemyPositionsToInvestigate.erase(Ship)
	if (SeenBy != null):
		if (SeenBy.Patrol):
			if (SeenBy.Command == null):
				OrderShipToPursue(SeenBy, Ship)
			else:
				OrderShipToPursue(SeenBy.Command, Ship)
	if (KnownEnemies.keys().has(Ship)):
		KnownEnemies[Ship] += 1
	else :
		KnownEnemies[Ship] = 1

func OnEnemyVisualLost(Ship : MapShip) -> void:
	if (KnownEnemies[Ship] > 1):
		KnownEnemies[Ship] -= 1
	else :
		KnownEnemies.erase(Ship)
		if (IsShipBeingPursued(Ship)):
			PursuitOrderCanceled(Ship)
		if (!Ship.IsDead()):
			var Info = VisualLostInfo.new()
			Info.Position = Ship.global_position
			Info.Speed = Ship.GetShipSpeed()
			Info.Direction = Ship.global_rotation
			EnemyPositionsToInvestigate[Ship] = Info
#func OnPositionInvestigated(Pos : Vector2) -> void:
	#for g in EnemyPositionsToInvestigate.size():
		#if (EnemyPositionsToInvestigate.values()[g] == Pos):
			#EnemyPositionsToInvestigate.erase(EnemyPositionsToInvestigate.keys()[g])
			#break
func AproximatePositionOnIntercept(HunterPos : Vector2, HunsterSpeed : float, Pos : Vector2, Speed : float) -> Vector2:

	var time_to_interception = (HunterPos.distance_to(Pos)) / HunsterSpeed

	# Calculate the predicted interception point
	return Pos + Speed * time_to_interception

func OnDestinationReached(Ship : HostileShip) -> void:
	var cities = get_tree().get_nodes_in_group("EnemyDestinations")
	var nextcity = cities.find(Ship.CurrentPort) + Ship.Direction
	if (nextcity < 0 or nextcity > cities.size() - 1):
		Ship.Direction *= -1
		nextcity = cities.find(Ship.CurrentPort) + Ship.Direction
	print(Ship.ShipName + " has reached " + Ship.CurrentPort.SpotInfo.SpotName + "|| Rerouting ship towards " + cities[nextcity].SpotInfo.SpotName)
	Ship.SetNewDestination(cities[nextcity].GetSpotName())
	#Ship.ShipLookAt(Ship.DestinationCity.global_position)

func OnElintHit(Ship : MapShip ,t : bool) -> void:
	if (t):
		if (KnownEnemies.keys().has(Ship) or Ship.IsDead()):
			return
		print(Ship.GetShipName() + " has triggered an Elint sensor")
		var Info = VisualLostInfo.new()
		Info.Position = Ship.global_position
		Info.Speed = Ship.GetShipSpeed()
		Info.Direction = Ship.global_rotation
		EnemyPositionsToInvestigate[Ship] = Info
		if (IsShipsPositionUnderInvestigation(Ship)):
			UpdateInvestigationPos(Ship.global_position, Ship)
#HELPER FUNCTIONS/////////////////////////////////////////////////
func IsShipsPositionUnderInvestigation(Ship : MapShip) -> bool:
	for g in InvestigationOrders:
		if (g.ShipTrigger == Ship):
			return true
	return false
func FindClosestFleetToPosition(Pos : Vector2, free : bool = false, patrol : bool = false) -> HostileShip:
	var closestdistance : float = 999999999999999
	var ClosestShip : HostileShip
	for g in Fleet:
		if (g.Docked or g.Command != null):
			continue
		if (free):
			if (g.PursuingShips.size() > 0 or g.LastKnownPosition != Vector2.ZERO or !g.CanReachPosition(Pos)):
				continue
		if (patrol):
			if (!g.Patrol):
				continue
		var dist = Pos.distance_to(g.global_position)
		if (dist < closestdistance):
			closestdistance = dist
			ClosestShip = g
	return ClosestShip
func FindMissileCarrierAbleToFireToPosition(Pos : Vector2) -> HostileShip:
	var Carrier : HostileShip
	for g in Fleet:
		#if g.Reloading > 0:
			#continue
		var dist = Pos.distance_to(g.global_position)
		var PossibleArmament = GetCheapestArmamentForDistance(dist)
		if (PossibleArmament == null):
			continue
		if (g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.MISSILE_SPACE) < Armaments[PossibleArmament]):
			continue
		
		Carrier = g
		break
	return Carrier

func FindMissileCarrierAbleToFireToShip(Ship : MapShip) -> HostileShip:
	var Carrier : HostileShip
	for g in Fleet:
		#if g.Reloading > 0:
			#continue
		var dist = Ship.global_position.distance_to(g.global_position)
		var PossibleArmament = GetCheapestArmamentForDistance(dist)
		if (PossibleArmament == null):
			continue
		if (g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.MISSILE_SPACE) < Armaments[PossibleArmament]):
			continue
		if (shapecast_2d(g, Ship)):
			continue
		Carrier = g
		break
	return Carrier

func shapecast_2d(from : MapShip, to: MapShip, margin: float = 1) -> bool:
	# Access the PhysicsDirectSpaceState2D from the World2D resource
	var world: World2D = get_world_2d()
	var space_state: PhysicsDirectSpaceState2D = world.direct_space_state
	
	var Shape = RectangleShape2D.new()
	Shape.size = Vector2(10,10)
	# Calculate the motion vector
	var motion: Vector2 = to.global_position - from.global_position
	
	# Prepare the shape cast query
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.transform = Transform2D(0, from.global_position)
	query.collide_with_areas = true
	query.collision_mask = layers_2d_physics
	query.shape_rid = Shape.get_rid()
	query.margin = margin
	query.motion = motion

	# Perform the shape cast
	var result = space_state.intersect_shape(query)
	
	for g in result:
		if (g["collider"].get_parent() == from or g["collider"].get_parent() == to):
			continue
		return true
	
	# Return true if the shape cast collides, false otherwise
	return false

func GetCheapestArmamentForDistance(Dist : float) -> MissileItem:
	var CheapestPrice = 10000
	var CheapestArmament
	for g in Armaments:
		if (Dist > g.Distance):
			continue
		if (Armaments[g] < CheapestPrice):
			CheapestArmament = g
			CheapestPrice = Armaments[g]
	return CheapestArmament
func IsShipBeingPursued(Ship : MapShip) -> bool:
	for g in PursuitOrders:
		if (g.Target == Ship):
			return true
	return false
#//////////////////////////////////////////////////////////////////
func _ready() -> void:
	Instance = self


static func GetInstance() -> Commander:
	return Instance

func RegisterSelf(Ship : HostileShip) -> void:
	Fleet.append(Ship)
	ConnectSignals(Ship)

func ConnectSignals(Ship : HostileShip) -> void:
	Ship.connect("OnShipDestroyed", OnShipDestroyed)
	Ship.connect("OnDestinationReached", OnDestinationReached)
	Ship.connect("OnEnemyVisualContact", OnEnemySeen)
	Ship.connect("OnEnemyVisualLost", OnEnemyVisualLost)
	Ship.connect("ElintContact", OnElintHit)
	

func GetSaveData() -> SaveData:
	var Save = SaveData.new()
	Save.DataName = "PositionsToInvestigate"
	var SavedData = SD_PositionsToInvestigate.new()
	var Poses : Dictionary
	for g in EnemyPositionsToInvestigate:
		Poses[g.GetShipName()] = EnemyPositionsToInvestigate[g]
	SavedData.Pos = Poses
	Save.Datas.append(SavedData)
	return Save
	
func LoadSaveData(Save : SaveData) -> void:
	var ships = get_tree().get_nodes_in_group("Ships")
	var Pos = (Save.Datas[0] as SD_PositionsToInvestigate).Pos
	for g in ships:
		var ShipName = g.GetShipName()
		if (Pos.has(ShipName)):
			EnemyPositionsToInvestigate[g] = Pos[ShipName]
