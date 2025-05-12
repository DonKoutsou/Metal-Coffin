extends CardModule

class_name OffensiveCardModule

@export var CounteredBy : CardStats
@export var Damage : float
@export var CauseFile : bool
@export var OnSuccesfullAtackModules : Array[CardModule]

func GetDesc() -> String:
	return "[color=#c19200]DMG = {0} * FPWR[/color]".format([var_to_str(snapped(Damage, 0.1)).replace(".0", "")])
