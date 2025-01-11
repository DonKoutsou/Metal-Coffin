extends Item
class_name ShipPart

@export var UpgradeName : String
@export var UpgradeAmm : float
@export var CurrentVal : float
@export var UpgradeVersion : ShipPart
@export var UpgradeTime : float
@export var IsDamaged : bool = false
@export var RepairItems : Array[Item]
func _setup_local_to_scene() -> void:
	CurrentVal = UpgradeAmm

func GetItemDesc() -> String:
	return "{0} \n[color=#c19200]{1}[/color] : + {2}".format([ItemDesc, UpgradeName.replace("_", " "), UpgradeAmm])
