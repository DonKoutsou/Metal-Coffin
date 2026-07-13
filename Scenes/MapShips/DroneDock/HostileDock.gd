extends BaseDock
class_name HostileDroneDock

func DroneDisharged(Dr : PlayerDrivenShip):
	if (DockedShips.has(Dr)):
		DockedShips.erase(Dr)
	Dr.queue_free()

func DockShip(Ship : MapShip) -> void:
	super(Ship)
	Ship.ToggleDocked(true)

func TrySetDockPath(RemoteT : RemoteTransform2D, Ship : MapShip):
	if (!Ship.Spawned):
		await  Ship.ShipSpawned
	super(RemoteT, Ship)

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
