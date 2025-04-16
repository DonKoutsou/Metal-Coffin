extends String_Happening_Option
class_name Drone_Happening_Option

var DroneScene : String = "res://Scenes/drone.tscn"
@export var Cpt : Captain

#func _init() -> void:
	#Dron = DroneScene.instantiate()

func OptionResault(EventOrigin : MapSpot) -> String:
	return StringReply
	
func OptionOutCome(Instigator : MapShip) -> bool:
	super(Instigator)
	if (CheckResault):
		Instigator.GetDroneDock().AddRecruit(Cpt)
	return CheckResault
