extends DeffenceCardModule
class_name ReserveConversionModule

@export var ConversionMultiplication : int = 2

func GetDesc() -> String:
	#if (AOE):
		#return "Coverst remaining Energy Reserve to double the Energy to team"
	return "Coverst remaining [color=#ffc315]Reserve[/color] to double the [color=#ffc315]Energy[/color]"
