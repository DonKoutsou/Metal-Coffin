extends CardModule

class_name CounterCardModule

@export var CounterType : OffensiveCardModule.AtackTypes

func GetDesc() -> String:
	return "Avoid an incomming\n[color=#ffc315]{0}[/color]".format([OffensiveCardModule.AtackTypes.keys()[CounterType].replace("_", " ")])
