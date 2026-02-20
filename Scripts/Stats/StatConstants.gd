@tool
extends Node

class_name STAT_CONST

const StatToolTips : Dictionary = {
	STATS.FUEL_TANK : "Indicates how much fuel a ship can carry. Combined with fuel efficiency, this determines the ship’s maximum travel distance without refueling.",
	STATS.FUEL_EFFICIENCY : "Determines how far a ship can travel per unit of fuel. Higher fuel efficiency means longer travel on less fuel. Heavier ships suffer from reduced fuel efficiency.",
	STATS.THRUST : "Represents the propulsion power of the ship. When combined with the ship's [color=#ffc315]WEIGHT[/color], it determines the ship’s top speed.",
	STATS.FIREPOWER : "Used during close-quarters combat encounters. Offensive actions scale with your [color=#ffc315]FIREPOWER[/color] stat. [color=#ffc315]FIREPOWER[/color] can also be temporarily increased during battle. Inspect each combat card to see how it scales with [color=#ffc315]FIREPOWER[/color].",
	STATS.HULL : "Represents the ship’s health. As long as [color=#ffc315]HULL[/color] is above 0, your ship remains operational. Ships can be repaired at ports, though repairs take time—larger [color=#ffc315]HULL[/color] values require longer to mend.",
	STATS.INVENTORY_SPACE : "Reflects how much cargo the ship can carry. Cargo, such as missiles or fire suppression units, can be purchased from ports and is typically single-use.",
	STATS.VISUAL_RANGE : "Determines how far your ship can visually detect enemies or objects in space.",
	STATS.ELINT : "Electronic Intelligence allows your ship to detect enemy radar signals at greater distances.",
	STATS.MISSILE_SPACE : "Ammount of fuel ship can carry.",
	STATS.WEIGHT : "Total mass of your ship and its equipment. [color=#ffc315]WEIGHT[/color] affects multiple aspects of performance, including [color=#ffc315]SPEED[/color] and [color=#ffc315]FUEL EFFICIENCY[/color]. Heavier ships are also affected less by wind",
	STATS.ENGINES_SLOTS : "Ammount of fuel ship can carry.",
	STATS.SENSOR_SLOTS : "Ammount of fuel ship can carry.",
	STATS.FUEL_TANK_SLOTS : "Ammount of fuel ship can carry.",
	STATS.SHIELD_SLOTS : "Ammount of fuel ship can carry.",
	STATS.WEAPON_SLOTS : "Ammount of fuel ship can carry.",
	STATS.MAX_SHIELD : "Ammount of fuel ship can carry.",
	STATS.REPAIR_PRICE : "The cost to repair one point of [color=#ffc315]HULL[/color] health. All ship parts contribute to this value—the lower it is, the cheaper your ship is to maintain.",
	STATS.AEROSONAR_RANGE : "Aerosonar allows you to detect ship noise signatures in greater distances.",
	STATS.SPEED : "Derived stat calculated from other attributes:[p][color=#ffc315]SPEED[/color] = ([color=#ffc315]THRUST[/color] × 1000) / [color=#ffc315]WEIGHT[/color]",
	STATS.RANGE : "Derived stat calculated from other attributes:[p][color=#ffc315]RANGE[/color] = [color=#ffc315]FUEL TANK[/color] * (([color=#ffc315]FUEL EFFICIENCY[/color] / pow([color=#ffc315]WEIGHT[/color], 0.5)) * 10)",
	STATS.VALUE : "Value of ship derived from original ship price and all items on it."
}

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
	STATS.WEIGHT : 1500,
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

static func GetTooltip(Stat : STATS) -> String:
	return StatToolTips[Stat]

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
	SPEED,
	RANGE,
	VALUE,
}
