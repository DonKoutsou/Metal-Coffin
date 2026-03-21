extends Resource

class_name BattleShipStats

var Name : String

var ShipIcon : Texture
var CaptainIcon : Texture

var Funds : int
var Convoy : bool

var Energy : int
var EnergyReserves : int

var deck : Deck
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
var FirePowerAttackBuff : float = 1
var FirePowerAttackDebuff : float = 0

var Speed : float
var SpeedBuff : float = 1
var SpeedDeBuff : float = 0

var Def : float = 0
var DefBuff : float = 0
var DefDebuff : float = 0

#FIRE
var IsOnFire : bool
var TurnsOnFire : int

var Friendly : bool

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
var FirePowerAttackBuffTime : int = 0
var FirePowerAttackDeBuffTime : int = 0
var SpeedBuffTime : int = 0
var SpeedDeBuffTime : int = 0
var DefBuffTime : int = 0
var DefDeBuffTime : int = 0

signal EnergyChanged(energyAdded : int)
signal ReservesChanged(reservesAdded : int)
signal StatsBuffed
signal CardsBuffed
signal ShipDamaged(amm : float)

func ShieldShip(Amm : float) -> void:
	Shield = min(Shield + Amm, MaxShield)
	ShipViz.Refresh()
	StatsBuffed.emit()

func StripBuff(Stat : CardModule.Stat) -> void:
	if (Stat == CardModule.Stat.FIREPOWER):
		FirePowerBuff = 1
		FirePowerBuffTime = 0
		FirePowerAttackBuff = 1
		FirePowerAttackBuffTime = 0
	if (Stat == CardModule.Stat.SPEED):
		SpeedBuff = 1
		SpeedBuffTime = 0
	if (Stat == CardModule.Stat.DEFENCE):
		DefBuff = 0
		DefBuffTime = 0
	ShipViz.Refresh()
	StatsBuffed.emit()

func CauseFire() -> void:
	if (IsOnFire):
		TurnsOnFire += 1
	else:
		IsOnFire = true
		TurnsOnFire = 0
	ShipViz.Refresh()
	StatsBuffed.emit()

func CombustFire() -> void:
	IsOnFire = false
	TurnsOnFire = 0
	ShipViz.Refresh()
	StatsBuffed.emit()

func SetEnergy(newEnergy : int) -> void:
	var dif = newEnergy - Energy
	Energy = newEnergy
	EnergyChanged.emit(self, dif)

func SetReserves(newReserves : int) -> void:
	var dif = newReserves - EnergyReserves
	EnergyReserves = newReserves
	ReservesChanged.emit(self, dif)

func BuffFirePower(Amm : float, Turns : int = 2) -> void:
	#buffs are usually 1.2 or 1.3 so we keep the 0.2 and add it
	FirePowerBuff += Amm - 1
	FirePowerBuffTime = Turns
	ShipViz.Refresh()
	StatsBuffed.emit()

func BuffNextAttack(Amm : float, AttackAmm : int = 1) -> void:
	FirePowerAttackBuff += Amm - 1
	FirePowerAttackBuffTime = AttackAmm
	ShipViz.Refresh()
	StatsBuffed.emit()

func DeBuffFirePower(Amm : float, Turns : int = 2) -> void:
	#buffs are usually 1.2 or 1.3 so we keep the 0.2 and add it
	FirePowerDeBuff += Amm - 1
	FirePowerDeBuffTime = Turns
	ShipViz.Refresh()
	StatsBuffed.emit()

func BuffSpeed(Amm : float, Turns : int = 2) -> void:
	SpeedBuff += Amm - 1
	SpeedBuffTime = Turns
	ShipViz.Refresh()
	StatsBuffed.emit()

func CleanseDebuffs() -> void:
	FirePowerDeBuff = 0
	SpeedDeBuff = 0
	DefDebuff = 0
	ShipViz.Refresh()
	StatsBuffed.emit()

func DeBuffSpeed(Amm : float, Turns : int = 2) -> void:
	#buffs are usually 1.2 or 1.3 so we keep the 0.2 and add it
	SpeedDeBuff += Amm
	SpeedDeBuffTime = Turns
	ShipViz.Refresh()
	StatsBuffed.emit()

func BuffDefence(Amm : float, Turns : int = 2) -> void:
	#buffs are usually 1.2 or 1.3 so we keep the 0.2 and add it
	DefBuff += Amm
	DefBuffTime = Turns
	ShipViz.Refresh()
	StatsBuffed.emit()

func DeBuffDefence(Amm : float, Turns : int = 2) -> void:
	#buffs are usually 1.2 or 1.3 so we keep the 0.2 and add it
	DefDebuff += Amm
	DefDeBuffTime = Turns
	ShipViz.Refresh()
	StatsBuffed.emit()

func DamageShip(Amm : float, ShouldCauseFire : bool = false, SkipShield : bool = false) -> void:
	var Dmg = Amm - min(1, (Amm * GetDef()))
	if (!SkipShield):
		if Shield > 0:
			var origshield = Shield
			Shield = max(0,origshield - Amm)
			Dmg -= origshield - Shield
	
	#only do fire roll when shield didt absorb all the damage
	if (Dmg > 0 and Helper.TrySetFire()):
		CauseFire()
	
	CurrentHull -= Dmg
	
	if (ShouldCauseFire):
		CauseFire()
	
	if (Friendly):
		if (CurrentHull < 40 and !ActionTracker.IsActionCompleted(ActionTracker.Action.CARD_FIGHT_SHIPLOSS)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.CARD_FIGHT_SHIPLOSS)
			ActionTracker.QueueTutorial("TUT_Cardfight_ShipLossTitle", "TUT_Cardfight_ShipLossText", [])
		
	ShipDamaged.emit(Dmg)
	
	ShipViz.Refresh()
	StatsBuffed.emit()

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
		
	ShipViz.Refresh()
	StatsBuffed.emit()
	return ExpiredBuffs

func UpdateAttackBuffs() -> Array[String]:
	var ExpiredBuffs : Array[String]
	FirePowerAttackBuffTime = max(0, FirePowerAttackBuffTime - 1)
	FirePowerAttackDeBuffTime = max(0, FirePowerAttackDeBuffTime - 1)
	if (FirePowerAttackBuffTime == 0 and FirePowerAttackBuff > 1):
		FirePowerAttackBuff = 1
		ExpiredBuffs.append("FirePower")
	if (FirePowerAttackDeBuffTime == 0 and FirePowerAttackDebuff > 1):
		FirePowerAttackDebuff = 1
		ExpiredBuffs.append("DeFirePower")
	ShipViz.Refresh()
	StatsBuffed.emit()
	return ExpiredBuffs

func GetFirePower() -> float:
	return FirePower * (FirePowerBuff - FirePowerDeBuff) * (FirePowerAttackBuff - FirePowerAttackDebuff)

func GetSpeed() -> float:
	return Speed * (SpeedBuff - SpeedDeBuff)

func GetDef() -> float:
	return Def + (DefBuff - DefDebuff)

func GetWeight() -> float:
	return Weight

func HasDebuff() -> bool:
	return DefDebuff > 0 or SpeedDeBuff > 0 or FirePowerDeBuff > 0
