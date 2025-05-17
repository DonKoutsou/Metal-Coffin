extends Resource

class_name CardModule

@export var AOE : bool = false

func GetDesc() -> String:
	return ""

func GetStatShortName(St : Stat) -> String:
	var StatName : String
	if (St == Stat.FIREPOWER):
		return "FRPW"
	if (St == Stat.SPEED):
		return "SPD"
	
	return StatName
enum Stat{
	FIREPOWER,
	SPEED
}
