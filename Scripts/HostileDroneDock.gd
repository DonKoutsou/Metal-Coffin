extends Node2D
class_name HostileDroneDock

var DockedDrones : Array[HostileShip]
var Captives : Array[HostileShip]
func GetCaptains() -> Array[Captain]:
	var cptns : Array[Captain]
	for g in DockedDrones:
		cptns.append(g.Cpt)
	return cptns
	
func DroneDisharged(Dr : Drone):
	if (DockedDrones.has(Dr)):
		DockedDrones.erase(Dr)
	Dr.queue_free()

func AddShip(Ship : HostileShip, _Notify : bool = true) -> void:
	AddShipToHierarchy(Ship)

func AddShipToHierarchy(Ship : HostileShip):
	get_parent().get_parent().add_child(Ship)
	DockShip(Ship)

func DockShip(Ship : HostileShip):
	DockedDrones.append(Ship)
	#Ship.DissableShip()
	
	Ship.Command = get_parent()
	var docks = $DroneSpots.get_children()
	
	var pos : Vector2
	var Offset = 2
	for g in docks.size() + 1:
		if (is_even(g)):
			pos = Vector2(-Offset, -Offset)
		else:
			pos = Vector2(-Offset, Offset)
			Offset += 2

	var trans = RemoteTransform2D.new()
	trans.update_rotation = false
	$DroneSpots.add_child(trans)
	trans.position = pos
	if (Ship.Spawned):
		Ship.global_position = trans.global_position
		trans.remote_path = Ship.get_path()
	else:
		call_deferred("TrySetDockPath", trans, Ship)
	Ship.ToggleDocked(true)

func is_even(number: int) -> bool:
	return number % 2 == 0

func TrySetDockPath(RemoteT : RemoteTransform2D, Ship : HostileShip):
	await  Ship.ShipSpawned
	Ship.global_position = RemoteT.global_position
	RemoteT.remote_path = Ship.get_path()

func GetDockedShips() -> Array[MapShip]:
	var Ships : Array[MapShip]
	Ships.append_array(DockedDrones)
	Ships.append_array(Captives)
	return Ships

func UndockShip(Ship : HostileShip):
	DockedDrones.erase(Ship)
	Ship.ToggleDocked(false)
	#Ship.Command = null
	var docks = $DroneSpots.get_children()
	for g in docks:
		var trans = g as RemoteTransform2D
		if (trans.remote_path == Ship.get_path()):
			#trans.remote_path = "."
			#trans.force_update_cache()
			trans.free()
			return
	RepositionDocks()
	
func RepositionDocks() -> void:
	
	for DockSpot in $DroneSpots.get_children().size():
		var pos : Vector2
		var Offset = 10
		for g in DockSpot + 1:
			if (is_even(g)):
				pos = Vector2(-Offset, -Offset)
			else:
				pos = Vector2(-Offset, Offset)
				Offset += 10
		
		$DroneSpots.get_child(DockSpot).position = pos

func DronesHaveFuel(f : float) -> bool:
	var fuelneeded = f
	for g in DockedDrones:
		fuelneeded -= g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		if (fuelneeded <= 0):
			return true
	return false

func SyphonFuelFromDrones(amm : float) -> void:
	for g in DockedDrones:
		var Cap = g.Cpt as Captain
		#var FuelTank = g.Cpt.GetStat(STAT_CONST.STATS.FUEL_TANK) as ShipStat
		if (Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > amm):
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK ,amm)
			return
		else:
			var FuelAmm = Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
			amm -= FuelAmm
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, FuelAmm)

func LaunchShip(Ship : HostileShip) -> void:
	UndockShip(Ship)
	Ship.global_position = global_position

func GetShipWithBiggerRange() -> HostileShip:
	var Ship : HostileShip
	var Rang = 0
	for g in DockedDrones:
		var R = g.GetFuelRange()
		if (R > Rang):
			Ship = g
			Rang = R
	return Ship
