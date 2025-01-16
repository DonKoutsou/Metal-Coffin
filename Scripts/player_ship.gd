extends MapShip

class_name PlayerShip

func _on_elint_area_entered(area: Area2D) -> void:
	if (area.get_parent() is Drone):
		return
	super(area)
func _on_elint_area_exited(area: Area2D) -> void:
	if (area.get_parent() is Drone):
		return
	super(area)
