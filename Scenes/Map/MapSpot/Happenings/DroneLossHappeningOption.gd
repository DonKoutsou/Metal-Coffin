extends String_Happening_Option
class_name DroneLossHappening_Option

@export var Cpt : Captain

#func _init() -> void:
	#Dron = DroneScene.instantiate()

func OptionResault(_EventOrigin : MapSpot) -> String:
	return StringReply
	
func OptionOutCome(Instigator : MapShip) -> bool:
	super(Instigator)
	if (!CheckResault):
		Instigator.GetDroneDock().RemoveCaptain(Cpt)
	return CheckResault
