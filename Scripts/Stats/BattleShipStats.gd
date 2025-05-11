extends Resource

class_name BattleShipStats

@export var Name : String
@export var Hull : float
@export var Shield : float
@export var FirePower : float
@export var FirePowerBuff : float
@export var ShipIcon : Texture
@export var CaptainIcon : Texture
@export var Speed : float
@export var SpeedBuff : float
@export var EnergyReserves : int
@export var Cards : Dictionary
#@export var Ammo : Dictionary
@export var Funds : int
@export var Convoy : bool

var FirePowerBuffTime : int = 0
var SpeedBuffTime : int = 0

func UpdateBuffs() -> Array[String]:
	var ExpiredBuffs : Array[String]
	FirePowerBuffTime = max(0, FirePowerBuffTime - 1)
	SpeedBuffTime = max(0, SpeedBuffTime - 1)
	if (FirePowerBuffTime == 0 and FirePowerBuff > 0):
		FirePowerBuff = 0
		ExpiredBuffs.append("FirePower")
	if (SpeedBuffTime == 0 and SpeedBuff > 0):
		SpeedBuff = 0
		ExpiredBuffs.append("Speed")
	return ExpiredBuffs

func GetFirePower() -> float:
	return FirePower + FirePowerBuff

func GetSpeed() -> float:
	return Speed +  (Speed * SpeedBuff)
