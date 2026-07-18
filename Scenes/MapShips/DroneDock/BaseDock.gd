@abstract
extends Area2D

class_name BaseDock

@export_file("*.tscn") var Ship_Scene : String

var DockedShips : Array[MapShip]
var Captives : Array[MapShip]

signal DroneAdded
signal DroneRemoved

#----------------------------------------
func AddCaptain(Cpt : Captain, _Notify : bool = true) -> MapShip:
	World.GetInstance().PlayerWallet.AddFunds(Cpt.ProvidingFunds)
	var ship = (load(Ship_Scene) as PackedScene).instantiate() as MapShip
	ship.Cpt = Cpt
	AddShip(ship, false)
	
	for Crew in Cpt.ProvidingCaptains:
		var NewShip = (load(Ship_Scene) as PackedScene).instantiate() as MapShip
		NewShip.Cpt = Crew
		AddShip(NewShip, false)
	return ship

#----------------------------------------
func AddShip(Ship : MapShip, _Notify : bool = true) -> void:
	AddShipToHierarchy(Ship)

#----------------------------------------
func AddShipToHierarchy(Ship : MapShip):
	get_parent().get_parent().add_child(Ship)
	DockShip(Ship)

#----------------------------------------
func AnyShipNeedsFuel() -> bool:
	for g in DockedShips:
		if (g.Fuel < 50):
			return true
	return false

#----------------------------------------
func ClearAllDrones() -> void:
	var Drones = DockedShips.duplicate()
	for g in Drones:
		DroneDischarged(g)
		g.Kill()

#----------------------------------------
func DroneDischarged(Dr : MapShip):
	DroneRemoved.emit()
	UndockShip(Dr)

#----------------------------------------
func DockShip(ship : MapShip):
	DockedShips.append(ship)

	var Command = get_parent() as MapShip
	ship.Command = Command

	var docks = $DroneSpots.get_children()

	var pos : Vector2
	var Offset = 2
	for g in docks.size() + 1:
		if (Helper.is_even(g)):
			pos = Vector2(-Offset, -Offset)
		else:
			pos = Vector2(-Offset, Offset)
			Offset += 2

	var trans = RemoteTransform2D.new()
	trans.update_rotation = false
	$DroneSpots.add_child(trans)
	trans.position = pos
	
	ship.ForceSteer(get_parent().rotation)
	
	if (ship.is_inside_tree()):
		ship.SetShipPosition(trans.global_position)
		trans.remote_path = ship.get_path()
	else:
		call_deferred("TrySetDockPath", trans, ship)

	ship.ToggleDocked(true)

	if (ship.Altitude != Command.Altitude):
		ship.TargetAltitude = Command.Altitude

	if (Command.GetShipSpeed() > 0):
		Command.AccelerationChanged(Command.GetShipSpeed() / Command.GetShipMaxSpeed())

	if (Command.CurrentPort != null and Command.CurrentPort != ship.CurrentPort):
		ship.SetCurrentPort(Command.CurrentPort)
		Command.CurrentPort.OnSpotAproached(ship)

#-----------------------------------------
func UndockShip(Ship : MapShip):
	DockedShips.erase(Ship)
	Ship.Command = null
	
	var docks = $DroneSpots.get_children()
	for g in docks:
		var trans = g as RemoteTransform2D
		if (trans.remote_path == Ship.get_path()):
			trans.free()
			Ship.ToggleDocked(false)
			return
	RepositionDocks()

#----------------------------------------
func RepositionDocks() -> void:
	for DockSpot in $DroneSpots.get_children().size():
		var pos : Vector2
		var Offset = 10
		for g in DockSpot + 1:
			if (Helper.is_even(g)):
				pos = Vector2(-Offset, -Offset)
			else:
				pos = Vector2(-Offset, Offset)
				Offset += 10

		$DroneSpots.get_child(DockSpot).position = pos

#----------------------------------------
func TrySetDockPath(RemoteT : RemoteTransform2D, ship : MapShip):
	ship.SetShipPosition(RemoteT.global_position)
	RemoteT.remote_path = ship.get_path()

#----------------------------------------
func SyphonFuelFromDrones(amm : float) -> void:
	for g in GetDockedShips():
		var Cap = g.Cpt as Captain
		#var FuelTank = g.Cpt.GetStat(STAT_CONST.STATS.FUEL_TANK) as ShipStat
		if (Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > amm):
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK ,amm)
			return
		else:
			var FuelAmm = Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
			amm -= FuelAmm
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, FuelAmm)

#----------------------------------------
func DronesHaveFuel(f : float) -> bool:
	var fuelneeded = f
	for g in GetDockedShips():
		fuelneeded -= g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		if (fuelneeded <= 0):
			return true
	return false

#----------------------------------------
func GetShipWithBiggerRange() -> MapShip:
	var Ship : MapShip
	var Rang = 0
	for g in DockedShips:
		var R = g.GetFuelRange()
		if (R > Rang):
			Ship = g
			Rang = R
	return Ship

#----------------------------------------
func GetDockedShips() -> Array[MapShip]:
	var Ships : Array[MapShip]
	Ships.append_array(DockedShips)
	Ships.append_array(Captives)
	return Ships

#----------------------------------------
func GetCaptains() -> Array[Captain]:
	var cptns : Array[Captain]
	for g in DockedShips:
		cptns.append(g.Cpt)
	return cptns

#-----------------------------------------
func GetDockedFuel() -> float:
	var fuel : float = 0
	for g in DockedShips:
		fuel += g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
	return fuel
