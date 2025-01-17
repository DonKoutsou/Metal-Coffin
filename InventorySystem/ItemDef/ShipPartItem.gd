extends Item
class_name ShipPart

@export var Upgrades : Array[ShipPartUpgrade]
@export var UpgradeVersion : ShipPart
@export var UpgradeTime : float
@export var IsDamaged : bool = false
@export var RepairItems : Array[Item]
func _setup_local_to_scene() -> void:
	for Up in Upgrades:
		Up.CurrentValue = Up.UpgradeAmmount

func GetItemDesc() -> String:
	var UpNames = ""
	for g in Upgrades.size():
		UpNames += "\n[color=#c19200]{0}[/color] : + {1} {2}".format([Upgrades[g].UpgradeName.replace("_", " "), Upgrades[g].UpgradeAmmount, Upgrades[g].UpAmmSymbol])
	return "{0} {1}".format([ItemDesc, UpNames])
