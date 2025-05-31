extends Resource

class_name CardModule


@export var AOE : bool = false
@export var TierUpgrade : float = 1
@export var TierUpgradeMethod : DamageInfo.CalcuationMethod

func GetDesc(Tier : int) -> String:
	return ""

func GetBattleDesc(User : BattleShipStats, Tier : int) -> String:
	return GetDesc(Tier)

func GetStatShortName(St : Stat) -> String:
	var StatName : String
	if (St == Stat.FIREPOWER):
		return "FRPW"
	if (St == Stat.SPEED):
		return "SPD"
	if (St == Stat.DEFENCE):
		return "DEF"
	
	return StatName
enum Stat{
	FIREPOWER,
	SPEED,
	DEFENCE,
	WEIGHT,
	ENERGY
}
