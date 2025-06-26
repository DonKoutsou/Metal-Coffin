extends Resource

class_name BattleShipStats

var Name : String

var ShipIcon : Texture
var CaptainIcon : Texture

var Funds : int
var Convoy : bool

var Energy : int
var EnergyReserves : int
var Cards : Array[CardStats]

var ShipViz : CardFightShipViz2

#STATS
var Weight : float

var CurrentHull : float
var Hull : float

var Shield : float
var MaxShield : float

var FirePower : float
var FirePowerBuff : float = 1
var FirePowerDeBuff : float = 0

var Speed : float
var SpeedBuff : float = 1
var SpeedDeBuff : float = 0

var Def : float = 0
var DefBuff : float = 0
var DefDebuff : float = 0

#FIRE
var IsOnFire : bool
var TurnsOnFire : int

func IsSeverelyBurnt() -> bool:
	return TurnsOnFire > 3

func GetFireDamage() -> float:
	var Dmg = 0
	if (IsOnFire):
		Dmg += 10
		if (IsSeverelyBurnt()):
			Dmg += 20
	return Dmg

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

func HasDebuff() -> bool:
	return DefDebuff > 0 or SpeedDeBuff > 0 or FirePowerDeBuff > 0
