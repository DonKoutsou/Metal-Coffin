extends Happening_Option
class_name Ship_Happening_Option

@export var ShipScene : BaseShip

#func _init() -> void:
	#Dron = DroneScene.instantiate()

func OptionResault() -> String:
	World.GetInstance().StartShipTrade(ShipScene)
	return "A new ship has joined your fleet."
