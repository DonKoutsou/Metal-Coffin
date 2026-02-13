@tool
extends Item
class_name ShipPart

@export var Upgrades : Array[ShipPartUpgrade]
@export var UpgradeVersion : ShipPart
@export var UpgradeTime : float
@export var IsDamaged : bool = false
@export var PartType : ShipPartType


func _setup_local_to_scene() -> void:
	for Up in Upgrades:
		Up.CurrentValue = Up.UpgradeAmmount

func GetItemDesc() -> String:
	var UpNames = "\n[color=#ffc315]-------------[/color]\nPROVIDING STATS"
	for g in Upgrades.size():
		#var Multiplier = 1
		#if (Upgrades[g].UpgradeName == STAT_CONST.STATS.THRUST):
			#Multiplier = 360
		var UpName = STAT_CONST.STATS.keys()[Upgrades[g].UpgradeName].replace("_", " ")
		var UpAmm
		var UpSymbol
		var Col
		if (Upgrades[g].UpgradeAmmount > 0):
			UpAmm = Upgrades[g].UpgradeAmmount
			UpSymbol = "+"
			Col = "ffc315"
		else : if (Upgrades[g].PenaltyAmmount > 0):
			UpAmm = Upgrades[g].PenaltyAmmount
			UpSymbol = "-"
			Col = "db2c36"
		UpNames += "\n[color=#{4}]{0}[/color] : {3} {1} {2}".format([UpName, UpAmm, STAT_CONST.GetStatMetric(Upgrades[g].UpgradeName), UpSymbol, Col])
	var PartTypeString : String = ShipPartType.keys()[PartType]
	PartTypeString = PartTypeString.replace("_", " ")
	return "[color=#ffc315]Ship Part Type[/color] : {2}\n[color=#ffc315]-------------[/color]\n{0} {1}".format([ItemDesc, UpNames, PartTypeString])


func GetWorkshopItemDesc() -> String:
	var UpNames = "PROVIDING STATS"
	for g in Upgrades.size():
		#var Multiplier = 1
		#if (Upgrades[g].UpgradeName == STAT_CONST.STATS.THRUST):
			#Multiplier = 360
		var UpName = STAT_CONST.STATS.keys()[Upgrades[g].UpgradeName].replace("_", " ")
		var UpAmm
		var UpSymbol
		var Col
		if (Upgrades[g].UpgradeAmmount > 0):
			UpAmm = Upgrades[g].UpgradeAmmount
			UpSymbol = "+"
			Col = "ffc315"
		else : if (Upgrades[g].PenaltyAmmount > 0):
			UpAmm = Upgrades[g].PenaltyAmmount
			UpSymbol = "-"
			Col = "db2c36"
		UpNames += "\n[color=#{4}]{0}[/color] : {3} {1} {2}".format([UpName, UpAmm, STAT_CONST.GetStatMetric(Upgrades[g].UpgradeName), UpSymbol, Col])
	return UpNames



enum ShipPartType{
	INVENTORY,
	ENGINE,
	SENSOR,
	FUEL_TANK,
	WEAPON,
	SHIELD
}
