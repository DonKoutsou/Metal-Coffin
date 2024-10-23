extends Resource
class_name ShipStat

@export var StatName : String
@export var StatMax : float
@export var StatBase : float
var StatShipBuff : float
var StatItemBuff : float
var CurrentVelue : float

func _init() -> void:
	CurrentVelue = StatBase
func GetBaseStat()-> float:
	return StatBase
func GetShipBuff()-> float:
	return StatShipBuff
func GetItemBuff()-> float:
	return StatItemBuff
func GetStat()-> float:
	return StatBase + StatShipBuff + StatItemBuff
func GetCurrentValue()-> float:
	return CurrentVelue
func RefilCurrentVelue(RefAmmount : float) -> void:
	CurrentVelue = clamp(CurrentVelue + RefAmmount, 0, GetStat())
func SetShipBuff(value : float) -> void:
	StatShipBuff = value;
	CurrentVelue += value
