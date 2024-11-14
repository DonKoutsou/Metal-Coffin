extends Happening_Option
class_name Drone_Happening_Option

@export var DroneScene : PackedScene
@export var Cpt : Captain

#func _init() -> void:
	#Dron = DroneScene.instantiate()

func OptionResault() -> String:
	PlayerShip.GetInstance().GetDroneDock().AddDrone(DroneScene.instantiate())
	return "A new ship has joined your fleet."
