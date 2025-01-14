extends Node2D
class_name HostileDroneDock

var DockedDrones : Array[HostileShip]
	
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
	
	var docks = $DroneSpots.get_children()
	for g in docks.size():
		if (docks[g].get_child_count() > 0):
			continue
		var dock = docks[g]
		var trans = RemoteTransform2D.new()
		trans.update_rotation = false
		dock.add_child(trans)
		trans.remote_path = Ship.get_path()
		Ship.ToggleDocked(true)
		Ship.Command = get_parent()
		return

func UndockShip(Ship : HostileShip):
	DockedDrones.erase(Ship)
	Ship.ToggleDocked(false)
	#Ship.Command = null
	var docks = $DroneSpots.get_children()
	for g in docks.size():
		if (docks[g].get_child_count() > 0):
			var trans = docks[g].get_child(0) as RemoteTransform2D
			if (trans.remote_path == Ship.get_path()):
				trans.free()
				return

func DronesHaveFuel(f : float) -> bool:
	var fuelneeded = f
	for g in DockedDrones:
		fuelneeded -= g.Cpt.GetStat("FUEL_TANK").CurrentVelue
		if (fuelneeded <= 0):
			return true
	return false

func SyphonFuelFromDrones(amm : float) -> void:
	for g in DockedDrones:
		var FuelTank = g.Cpt.GetStat("FUEL_TANK") as ShipStat
		if (FuelTank.GetCurrentValue() > amm):
			FuelTank.ConsumeResource(amm)
			return
		else:
			amm -= FuelTank.GetCurrentValue()
			FuelTank.CurrentVelue = 0

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
