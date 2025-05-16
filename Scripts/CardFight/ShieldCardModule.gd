extends DeffenceCardModule

class_name ShieldCardModule

@export var ShieldAmm : int = 10

func GetDesc() -> String:
	if (AOE):
		return "[color=#6be2e9]+{0} Shield[/color] for team".format([ShieldAmm])
	return "[color=#6be2e9]+{0} Shield[/color] for self".format([ShieldAmm])
