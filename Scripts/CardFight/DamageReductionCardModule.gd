extends CardModule

class_name DamageReductionCardModule

@export var CounterType : OffensiveCardModule.AtackTypes
@export var ReductionPercent : float


func GetDesc(Tier : int) -> String:
	var Desc = "Reduce the damage of \n[color=#ffc315]{0}[/color] to {1}%".format([OffensiveCardModule.AtackTypes.keys()[CounterType].replace("_", " "), roundi(ReductionPercent * 100)])
	return Desc
