@tool
extends Node

class_name STAT_CONST

const StatMaxValues : Dictionary = {
	STATS.FUEL_TANK : 1000,
	STATS.FUEL_EFFICIENCY : 50,
	STATS.THRUST : 100,
	STATS.FIREPOWER : 20,
	STATS.HULL : 1000,
	STATS.INVENTORY_SPACE : 10,
	STATS.VISUAL_RANGE : 1500,
	STATS.ELINT : 3000,
	STATS.MISSILE_SPACE : 20,
	STATS.WEIGHT : 500,
	STATS.ENGINES_SLOTS : 4,
	STATS.SENSOR_SLOTS : 4,
	STATS.FUEL_TANK_SLOTS : 4,
	STATS.SHIELD_SLOTS : 4,
	STATS.WEAPON_SLOTS : 10,
	STATS.MAX_SHIELD : 1000,
	STATS.REPAIR_PRICE : 1000,
	STATS.AEROSONAR_RANGE : 3000
}
const StatShouldStack : Dictionary = {
	STATS.FUEL_TANK : true,
	STATS.FUEL_EFFICIENCY : true,
	STATS.THRUST : true,
	STATS.FIREPOWER : true,
	STATS.HULL : true,
	STATS.INVENTORY_SPACE : true,
	STATS.VISUAL_RANGE : false,
	STATS.ELINT : false,
	STATS.MISSILE_SPACE : true,
	STATS.WEIGHT : true,
	STATS.ENGINES_SLOTS : false,
	STATS.SENSOR_SLOTS : false,
	STATS.FUEL_TANK_SLOTS : false,
	STATS.SHIELD_SLOTS : false,
	STATS.WEAPON_SLOTS : false,
	STATS.MAX_SHIELD : true,
	STATS.REPAIR_PRICE : true,
	STATS.AEROSONAR_RANGE : false
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
			Metric = "m³"
		STATS.FUEL_EFFICIENCY:
			Metric = "km/m³"
		STATS.THRUST:
			Metric = "MN"
		STATS.VISUAL_RANGE:
			Metric = "km"
		STATS.ELINT:
			Metric = "km"
		STATS.WEIGHT:
			Metric = "tons"
		STATS.REPAIR_PRICE:
			Metric = "Drahma"
		STATS.AEROSONAR_RANGE:
			Metric = "km"
	return Metric

static func GetStatItemBuff(Stat : STATS, Buffs : Array[float]) -> float:
	var BuffAmm : float = 0
	if (ShouldStatStack(Stat)):
		for g in Buffs:
			BuffAmm += g
	else:
		for g in Buffs:
			if (g > BuffAmm):
				BuffAmm = g
	return BuffAmm

static func ShouldStatStack(Stat : STATS) -> bool:
	return StatShouldStack[Stat]

static func GetStatMaxValue(Stat : STATS) -> int:
	return StatMaxValues[Stat]

enum STATS{
	FUEL_TANK,
	FUEL_EFFICIENCY,
	THRUST,
	FIREPOWER,
	HULL,
	INVENTORY_SPACE,
	VISUAL_RANGE,
	ELINT,
	MISSILE_SPACE,
	WEIGHT,
	ENGINES_SLOTS,
	SENSOR_SLOTS,
	FUEL_TANK_SLOTS,
	SHIELD_SLOTS,
	WEAPON_SLOTS,
	MAX_SHIELD,
	REPAIR_PRICE,
	AEROSONAR_RANGE,
}
