extends Node

class_name Commander

static var Instance : Commander

var Fleet : Array[HostileShip] = []

var PursuitOrders : Array[PursuitOrder]
var InvestigationOrders : Array[InvestigationOrder]

var EnemyPositionsToInvestigate : Dictionary
var KnownEnemies : Dictionary

# Called when the node enters the scene tree for the first time.

func _physics_process(_delta: float) -> void:
	# check for known enemies and see if an order can be created
	for g in KnownEnemies:
		if (!IsShipBeingPursued(g)):
			var closestship = FindClosestFleetToPosition(g.global_position, true, true)
			OrderShipToPursue(closestship, g)
	for g in EnemyPositionsToInvestigate.size():
		var investigatedship = EnemyPositionsToInvestigate.keys()[g]
		var investigatedpos = EnemyPositionsToInvestigate.values()[g]
		if (!IsShipsPositionUnderInvestigation(investigatedship)):
			OrderShipToInvestigate(FindClosestFleetToPosition(investigatedpos, true, true) ,investigatedpos, investigatedship)

#ORDER MANAGEMENT////////////////////////////////////////////////////////////////
func OrderShipToAtack(Ship : HostileShip, Target : MapShip) -> void:
	pass
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
			for z in PursuitOrders[g].Receivers:
				z.PursuingShips.clear()
			PursuitOrders.erase(g)
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
	var POrdersToErase : Array[PursuitOrder] = []
	if (Ship.PursuingShips.size() > 0):
		for g in PursuitOrders:
			if (g.Receivers.has(Ship)):
				g.Receivers.erase(Ship)
				if (g.Receivers.size() == 0):
					POrdersToErase.append(g)
	var IOrdersToErase : Array[PursuitOrder] = []
	if (Ship.LastKnownPosition != Vector2.ZERO):
		for g in InvestigationOrders:
			if (g.Receivers.has(Ship)):
				g.Receivers.erase(Ship)
				if (g.Receivers.size() == 0):
					IOrdersToErase.append(g)
	for g in POrdersToErase:
		PursuitOrderCanceled(g.Target)
	for g in IOrdersToErase:
		InvestigationOrders.erase(g)
func OnEnemySeen(Ship : MapShip) -> void:
	#if an enemy that had its location investigated is seen 
	#make sure to call of all investigation on its previusly known location
	print(Ship.GetShipName() + " has been located.")
	if (EnemyPositionsToInvestigate.has(Ship)):
		if (IsShipsPositionUnderInvestigation(Ship)):
			print(Ship.GetShipName() + "'s position was under investigation, investigation order has been canceled")
			InvestigationOrderComplete(EnemyPositionsToInvestigate[Ship])
		EnemyPositionsToInvestigate.erase(Ship)
	
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
		EnemyPositionsToInvestigate[Ship] = Ship.global_position

#func OnPositionInvestigated(Pos : Vector2) -> void:
	#for g in EnemyPositionsToInvestigate.size():
		#if (EnemyPositionsToInvestigate.values()[g] == Pos):
			#EnemyPositionsToInvestigate.erase(EnemyPositionsToInvestigate.keys()[g])
			#break

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
		print(Ship.GetShipName() + " has triggered an Elint sensor")
		EnemyPositionsToInvestigate[Ship] = Ship.global_position
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
		if (g.Docked):
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

func FindClosestMissileCarrierToPosition(Pos : Vector2) -> HostileShip:
	var closestdistance : float = 999999999999999
	var ClosestShip : HostileShip
	for g in Fleet:
		if (g.WeaponInventory == 0):
			continue
		var dist = Pos.distance_to(g.global_position)
		if (dist < closestdistance):
			closestdistance = dist
			ClosestShip = g
	return ClosestShip

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
