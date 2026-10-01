extends Resource

class_name MapSpotEventManager

signal EnemyVisualLost(ship : MapShip)
signal EnemySeen(ship : MapShip)

func OnEnemyVisualLost(ship : MapShip) -> void:
	EnemyVisualLost.emit(ship)
	
func OnEnemySeen(ship : MapShip) -> void:
	EnemySeen.emit(ship)
