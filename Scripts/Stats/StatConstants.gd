@tool
extends Node

class_name STAT_CONST

const StatMaxValues : Dictionary = {
	STATS.FUEL_TANK : 1000,
	STATS.FUEL_EFFICIENCY : 5,
	STATS.SPEED : 3,
	STATS.FIREPOWER : 20,
	STATS.HULL : 1000,
	STATS.INVENTORY_SPACE : 12,
	STATS.VISUAL_RANGE : 1500,
	STATS.ELINT : 3000,
	STATS.MISSILE_SPACE : 20
}

static func StringToEnum(Stat : String) -> STATS:
	for g in STATS.keys():
		if (g.to_lower() == Stat):
			return STATS[g]
	return STATS.FUEL_TANK
	
static func GetStatMaxValue(Stat : STATS) -> int:
	return StatMaxValues[Stat]

enum STATS{
	FUEL_TANK,
	FUEL_EFFICIENCY,
	SPEED,
	FIREPOWER,
	HULL,
	INVENTORY_SPACE,
	VISUAL_RANGE,
	ELINT,
	MISSILE_SPACE
}
