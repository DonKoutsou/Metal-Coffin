extends DeffenceCardModule
class_name ReserveModule

@export var ReserveAmmount : int = 5

func GetDesc(Tier : int) -> String:
	if (AOE):
		return "Adds [color=#ffc315]{0}[/color] Energy Reserve to team".format([ReserveAmmount])
	return "Adds [color=#ffc315]{0}[/color] Energy Reserve to self".format([ReserveAmmount])
