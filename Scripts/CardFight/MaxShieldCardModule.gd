extends DeffenceCardModule

class_name MaxShieldCardModule

@export var ShieldPerEnergy : int = 10

func GetDesc() -> String:
	if (AOE):
		return "[color=#ffc315]Remaining Energy[/color] * [color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for team".format([ShieldPerEnergy])
	return "[color=#ffc315]Remaining Energy[/color] * [color=#ffc315]{0}[/color] [color=#6be2e9]Shield[/color] for self".format([ShieldPerEnergy])
