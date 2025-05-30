extends DeffenceCardModule
class_name ResupplyModule

@export var ResupplyAmmount : int = 1

func GetDesc(Tier : int) -> String:
	return "Adds [color=#ffc315]{0}[/color] Energy".format([ResupplyAmmount * max((TierUpgrade * Tier), 1)])
