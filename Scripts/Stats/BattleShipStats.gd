extends Resource

class_name BattleShipStats

@export var Name : String
@export var CurrentHull : float
@export var Hull : float
@export var Shield : float
@export var FirePower : float
@export var FirePowerBuff : float = 1
@export var FirePowerDeBuff : float = 0
@export var ShipIcon : Texture
@export var CaptainIcon : Texture
@export var Weight : float
@export var Speed : float
@export var SpeedBuff : float = 1
@export var SpeedDeBuff : float = 0
@export var Def : float = 0
@export var DefBuff : float = 0
@export var DefDebuff : float = 0
@export var Energy : int
@export var EnergyReserves : int
@export var Cards : Array[CardStats]
@export var FireTurns : int
#@export var Ammo : Dictionary
@export var Funds : int
@export var Convoy : bool

var FirePowerBuffTime : int = 0
var FirePowerDeBuffTime : int = 0
var SpeedBuffTime : int = 0
var SpeedDeBuffTime : int = 0
var DefBuffTime : int = 0
var DefDeBuffTime : int = 0

func UpdateBuffs() -> Array[String]:
	var ExpiredBuffs : Array[String]
	FirePowerBuffTime = max(0, FirePowerBuffTime - 1)
	FirePowerDeBuffTime = max(0, FirePowerDeBuffTime - 1)
	SpeedBuffTime = max(0, SpeedBuffTime - 1)
	SpeedDeBuffTime = max(0, SpeedDeBuffTime - 1)
	DefBuffTime = max(0, DefBuffTime - 1)
	DefDeBuffTime = max(0, DefDeBuffTime - 1)
	
	if (FirePowerBuffTime == 0 and FirePowerBuff > 1):
		FirePowerBuff = 1
		ExpiredBuffs.append("FirePower")
	if (SpeedBuffTime == 0 and SpeedBuff > 1):
		SpeedBuff = 1
		ExpiredBuffs.append("Speed")
	if (DefBuffTime == 0 and DefBuff > 0):
		DefBuff = 0
		ExpiredBuffs.append("Def")
	if (FirePowerDeBuffTime == 0 and FirePowerDeBuff > 0):
		FirePowerDeBuff = 0
		ExpiredBuffs.append("DeFirePower")
	if (SpeedDeBuffTime == 0 and SpeedDeBuff > 0):
		SpeedDeBuff = 0
		ExpiredBuffs.append("DeSpeed")
	if (DefDeBuffTime == 0 and DefDebuff > 0):
		DefDebuff = 0
		ExpiredBuffs.append("DeDef")
	return ExpiredBuffs

func GetFirePower() -> float:
	return FirePower * (FirePowerBuff - FirePowerDeBuff)

func GetSpeed() -> float:
	return Speed * (SpeedBuff - SpeedDeBuff)

func GetDef() -> float:
	return Def + (DefBuff - DefDebuff)

func GetWeight() -> float:
	return Weight
