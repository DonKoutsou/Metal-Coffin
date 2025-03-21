@tool
extends Node

class_name STAT_CONST

const StatMaxValues : Dictionary = {
	STATS.FUEL_TANK : 1000,
	STATS.FUEL_EFFICIENCY : 50,
	STATS.SPEED : 3,
	STATS.FIREPOWER : 20,
	STATS.HULL : 1000,
	STATS.INVENTORY_SPACE : 12,
	STATS.VISUAL_RANGE : 1500,
	STATS.ELINT : 3000,
	STATS.MISSILE_SPACE : 20
}
const StatShouldStack : Dictionary = {
	STATS.FUEL_TANK : true,
	STATS.FUEL_EFFICIENCY : true,
	STATS.SPEED : true,
	STATS.FIREPOWER : true,
	STATS.HULL : true,
	STATS.INVENTORY_SPACE : true,
	STATS.VISUAL_RANGE : false,
	STATS.ELINT : false,
	STATS.MISSILE_SPACE : true
}

static func StringToEnum(Stat : String) -> STATS:
	for g in STATS.keys():
		if (g.to_lower() == Stat):
			return STATS[g]
	return STATS.FUEL_TANK

static func GetStatMetric(Stat : STATS) -> String:
	var Metric : String
	match Stat:
		STATS.FUEL_TANK :
			Metric = "Cubic Tons"
		STATS.FUEL_EFFICIENCY:
			Metric = "km/Lt"
		STATS.SPEED:
			Metric = "km/h"
		STATS.VISUAL_RANGE:
			Metric = "km"
		STATS.ELINT:
			Metric = "km"
	return Metric

static func GetStatItemBuff(Stat : STATS, Buffs : Array[float]) -> float:
	var Buff : float
	if (ShouldStatStack(Stat)):
		for g in Buffs:
			Buff += g
	else:
		for g in Buffs:
			if (g > Buff):
				Buff = g
	return Buff

static func ShouldStatStack(Stat : STATS) -> bool:
	return StatShouldStack[Stat]

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
