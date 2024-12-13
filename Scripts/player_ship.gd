extends MapShip

class_name PlayerShip

static var Instance : PlayerShip

func _ready() -> void:
	super()
	Instance = self
	
func GetDroneDock() -> DroneDock:
	return $DroneDock
static func GetInstance() -> PlayerShip:
	return Instance
