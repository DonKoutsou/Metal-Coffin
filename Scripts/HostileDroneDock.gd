extends Node2D
class_name HostileDroneDock

var DockedDrones : Array[HostileShip]

func HasSpace() -> bool:
	return DockedDrones.size() < 6
	
func GetCaptains() -> Array[Captain]:
	var cptns : Array[Captain]
	for g in DockedDrones:
		cptns.append(g.Cpt)
	return cptns
	
func DroneDisharged(Dr : Drone):
	if (DockedDrones.has(Dr)):
		DockedDrones.erase(Dr)
	ShipData.GetInstance().RemoveCaptainStats([Dr.Cpt.GetStat("INVENTORY_CAPACITY")])
	Inventory.GetInstance().UpdateSize()
	MapPointerManager.GetInstance().RemoveShip(Dr)
	Dr.queue_free()

func AddShip(Ship : HostileShip, Notify : bool = true) -> void:
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
		Ship.Docked = true
		Ship.Command = get_parent()
		return

func UndockDrone(drone : Drone):
	DockedDrones.erase(drone)
	var docks = $DroneSpots.get_children()
	for g in docks.size():
		if (docks[g].get_child_count() > 0):
			var trans = docks[g].get_child(0) as RemoteTransform2D
			if (trans.remote_path == drone.get_path()):
				trans.free()
				drone.Docked = false
				drone.Command = null
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
		if (g.Cpt.GetStat("FUEL_TANK").CurrentVelue > amm):
			g.Cpt.GetStat("FUEL_TANK").CurrentVelue -= amm
			return
		else:
			amm -= g.Cpt.GetStat("FUEL_TANK").CurrentVelue
			g.Cpt.GetStat("FUEL_TANK").CurrentVelue = 0
