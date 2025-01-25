extends Item
class_name ShipPart

@export var Upgrades : Array[ShipPartUpgrade]
@export var UpgradeVersion : ShipPart
@export var UpgradeTime : float
@export var IsDamaged : bool = false

func _setup_local_to_scene() -> void:
	for Up in Upgrades:
		Up.CurrentValue = Up.UpgradeAmmount

func GetItemDesc() -> String:
	var UpNames = ""
	for g in Upgrades.size():
		var Multiplier = 1
		if (Upgrades[g].UpgradeName == STAT_CONST.STATS.SPEED):
			Multiplier = 360
		var UpName = STAT_CONST.STATS.keys()[Upgrades[g].UpgradeName].replace("_", " ")
		var UpAmm = Upgrades[g].UpgradeAmmount * Multiplier
		UpNames += "\n[color=#c19200]{0}[/color] : + {1} {2}".format([UpName, UpAmm, Upgrades[g].UpAmmSymbol])
	return "{0} {1}".format([ItemDesc, UpNames])
