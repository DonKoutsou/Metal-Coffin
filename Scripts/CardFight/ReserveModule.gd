extends DeffenceCardModule
class_name ReserveModule

@export var ReserveAmmount : int = 5

func GetDesc() -> String:
	if (AOE):
		return "Adds [color=#c19200]{0}[/color] Energy Reserve to team".format([ReserveAmmount])
	return "Adds [color=#c19200]{0}[/color] Energy Reserve to self".format([ReserveAmmount])
