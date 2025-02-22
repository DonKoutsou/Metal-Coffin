@tool
extends Resource
class_name ShipStat

@export var StatName : STAT_CONST.STATS
#@export var StatName : String
@export var StatBase : float
@export var StatShipPartBuff : float
@export var StatShipPartPenalty : float
@export var CurrentValue : float
	
func GetStatName() -> STAT_CONST.STATS:
	return StatName

func GetBaseValue()-> float:
	return StatBase
	
func GetShipPartBuff()-> float:
	return StatShipPartBuff
	
func GetShipPartPenalty() -> float:
	return StatShipPartPenalty

func AddShipPartBuff(Amm : float) -> void:
	StatShipPartBuff += Amm

func AddShipPartPenalty(Amm : float) -> void:
	StatShipPartPenalty += Amm
	
func GetFinalValue()-> float:
	return StatBase + StatShipPartBuff - StatShipPartPenalty
	
func GetCurrentValue()-> float:
	return CurrentValue
	
func RefilCurrentValue(RefAmmount : float) -> void:
	CurrentValue = clamp(CurrentValue + RefAmmount, 0, GetFinalValue())
	
func ConsumeResource(Consumtion : float) -> void:
	CurrentValue = clamp(CurrentValue - Consumtion, 0, GetFinalValue())

func ForceMaxValue() -> void:
	CurrentValue = GetFinalValue()
