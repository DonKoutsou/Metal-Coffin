extends MapShip

class_name PlayerShip

func BodyEnteredElint(Body: Area2D) -> void:
	if (Body.get_parent() is Drone):
		return
	super(Body)
func BodyLeftElint(Body: Area2D) -> void:
	if (Body.get_parent() is Drone):
		return
	super(Body)
