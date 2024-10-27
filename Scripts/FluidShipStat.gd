extends BaseShipStat
class_name FluidShipStat

@export var StatCurrentVal : float

func _setup_local_to_scene() -> void:
	StatCurrentVal = StatBuff
