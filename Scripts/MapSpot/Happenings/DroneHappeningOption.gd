extends Happening_Option
class_name Drone_Happening_Option

var DroneScene : String = "res://Scenes/drone.tscn"
@export var Cpt : Captain

#func _init() -> void:
	#Dron = DroneScene.instantiate()

func OptionResault(EventOrigin : MapSpot) -> String:
	if (CheckResault):
		return "A new ship has joined your fleet."
	else:
		return "The captain has refused to join your fleet"
	
func OptionOutCome(Instigator : MapShip) -> bool:
	super(Instigator)
	if (CheckResault):
		Instigator.GetDroneDock().AddRecruit(Cpt)
	return CheckResault
