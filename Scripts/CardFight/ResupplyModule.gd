extends DeffenceCardModule
class_name ResupplyModule

@export var ResupplyAmmount : int = 1

func GetDesc() -> String:
	return "Adds [color=#c19200]{0}[/color] Energy".format([ResupplyAmmount])
