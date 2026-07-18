extends BaseDock
class_name HostileDroneDock

func DroneDischarged(Dr : MapShip):
	if (DockedShips.has(Dr)):
		DockedShips.erase(Dr)
	Dr.queue_free()

func TrySetDockPath(RemoteT : RemoteTransform2D, Ship : MapShip):
	if (!Ship.Spawned):
		await  Ship.ShipSpawned
	super(RemoteT, Ship)

func LaunchShip(Ship : HostileShip) -> void:
	UndockShip(Ship)
	Ship.global_position = global_position
