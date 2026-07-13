extends BaseDock
class_name HostileDroneDock

func DroneDisharged(Dr : PlayerDrivenShip):
	if (DockedShips.has(Dr)):
		DockedShips.erase(Dr)
	Dr.queue_free()

func AddShip(Ship : HostileShip, _Notify : bool = true) -> void:
	AddShipToHierarchy(Ship)

func AddShipToHierarchy(Ship : HostileShip):
	get_parent().get_parent().add_child(Ship)
	DockShip(Ship)

func DockShip(Ship : HostileShip):
	DockedShips.append(Ship)
	#Ship.DissableShip()
	
	Ship.Command = get_parent()
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
	if (Ship.Spawned):
		Ship.global_position = trans.global_position
		trans.remote_path = Ship.get_path()
	else:
		call_deferred("TrySetDockPath", trans, Ship)
	Ship.ToggleDocked(true)

func TrySetDockPath(RemoteT : RemoteTransform2D, Ship : HostileShip):
	if (!Ship.Spawned):
		await  Ship.ShipSpawned
	Ship.global_position = RemoteT.global_position
	RemoteT.remote_path = Ship.get_path()

func UndockShip(Ship : HostileShip):
	DockedShips.erase(Ship)
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
			if (Helper.is_even(g)):
				pos = Vector2(-Offset, -Offset)
			else:
				pos = Vector2(-Offset, Offset)
				Offset += 10
		
		$DroneSpots.get_child(DockSpot).position = pos

func LaunchShip(Ship : HostileShip) -> void:
	UndockShip(Ship)
	Ship.global_position = global_position

func GetShipWithBiggerRange() -> HostileShip:
	var Ship : HostileShip
	var Rang = 0
	for g in DockedShips:
		var R = g.GetFuelRange()
		if (R > Rang):
			Ship = g
			Rang = R
	return Ship
