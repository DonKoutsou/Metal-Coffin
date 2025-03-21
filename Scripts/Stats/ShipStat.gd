@tool
extends Resource
class_name ShipStat

@export var StatName : STAT_CONST.STATS
#@export var StatName : String
@export var StatBase : float
@export var StatShipPartBuff : Array[float]
@export var StatShipPartPenalty : float
@export var CurrentValue : float
	
func GetStatName() -> STAT_CONST.STATS:
	return StatName

func GetBaseValue()-> float:
	return StatBase
	
func GetShipPartBuff()-> float:
	return STAT_CONST.GetStatItemBuff(StatName, StatShipPartBuff)
	
func GetShipPartPenalty() -> float:
	return StatShipPartPenalty

func AddShipPartBuff(Amm : float) -> void:
	StatShipPartBuff.append(Amm)

func RemoveShipPartBuff(Amm : float) -> void:
	StatShipPartBuff.erase(Amm)

func AddShipPartPenalty(Amm : float) -> void:
	StatShipPartPenalty += Amm
	
func GetFinalValue()-> float:
	return StatBase + STAT_CONST.GetStatItemBuff(StatName, StatShipPartBuff) - StatShipPartPenalty
	
func GetCurrentValue()-> float:
	return CurrentValue
	
func RefilCurrentValue(RefAmmount : float) -> void:
	CurrentValue = clamp(CurrentValue + RefAmmount, 0, GetFinalValue())
	
func ConsumeResource(Consumtion : float) -> void:
	CurrentValue = clamp(CurrentValue - Consumtion, 0, GetFinalValue())

func ForceMaxValue() -> void:
	CurrentValue = GetFinalValue()
