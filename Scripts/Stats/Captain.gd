@tool
extends Resource
class_name Captain

@export var CaptainName : String
@export var CaptainBio : String
@export var CaptainPortrait : Texture
@export var ShipIcon : Texture
@export var CaptainStats : Array[ShipStat]

#var MappedStats : Array[STAT_CONST.STATS]
@export var ShipCallsign : String = "P"
@export var StartingItems : Array[Item]
@export var CurrentPort : String = ""
@export var CheckForErrors : bool = false
@export var ProvidingFunds : int = 0
@export var ProvidingCaptains : Array[Captain]
#Only used by enemies
@export var Cards : Dictionary[CardStats, int]

#used to signal ship so it can change size of colliders
signal ShipPartChanged(P : ShipPart)
signal StatChanged(NewVal : float)
var CaptainShip : MapShip
var _CharInv : CharacterInventory

func _init() -> void:
	#call_deferred("MapStats")
	if (OS.is_debug_build() and CheckForErrors):
		call_deferred("CheckForIssues")
	#call_deferred("SetUpStats")

func SetUpStats() -> void:
	for g in StartingItems:
		if (g is ShipPart):
			for st : ShipPartUpgrade in g.Upgrades:
				_GetStat(st.UpgradeName).AddShipPartBuff(st.UpgradeAmmount)
				_GetStat(st.UpgradeName).AddShipPartPenalty(st.PenaltyAmmount)
				FullyRefilStat(st.UpgradeName)

func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	var Hull = _GetStat(STAT_CONST.STATS.HULL).StatBase
	
	var Thrust = _GetStat(STAT_CONST.STATS.THRUST).StatBase
	var Weight = _GetStat(STAT_CONST.STATS.WEIGHT).StatBase
	var Fp = _GetStat(STAT_CONST.STATS.FIREPOWER).StatBase
	var MaxShield = _GetStat(STAT_CONST.STATS.MAX_SHIELD).StatBase
	
	stats.ShipIcon = ShipIcon
	stats.CaptainIcon = CaptainPortrait
	stats.Name = CaptainName
	var c : Array[CardStats]
	for g in StartingItems:
		if (g is ShipPart):
			for up : ShipPartUpgrade in g.Upgrades:
				if (up.UpgradeName == STAT_CONST.STATS.HULL):
					Hull += up.UpgradeAmmount
					Hull -= up.PenaltyAmmount
				if (up.UpgradeName == STAT_CONST.STATS.WEIGHT):
					Weight += up.UpgradeAmmount
					Weight -= up.PenaltyAmmount
				if (up.UpgradeName == STAT_CONST.STATS.THRUST):
					Thrust += up.UpgradeAmmount
					Thrust -= up.PenaltyAmmount
				if (up.UpgradeName == STAT_CONST.STATS.FIREPOWER):
					Fp += up.UpgradeAmmount
					Fp -= up.PenaltyAmmount
				if (up.UpgradeName == STAT_CONST.STATS.MAX_SHIELD):
					MaxShield += up.UpgradeAmmount
					MaxShield -= up.PenaltyAmmount
					
		if (g is AmmoItem and !HasWeapon(g.WType)):
			continue
			
		for z in g.CardProviding:
			var C = z.duplicate() as CardStats
			C.Tier = g.Tier
			c.append(C)
			
	for g in Cards:
		for z in Cards[g]:
			c.append(g)
		
	stats.Hull = Hull
	stats.CurrentHull = Hull
	stats.Speed = (Thrust * 1000) / Weight
	stats.FirePower = Fp
	stats.Weight = Weight
	stats.Cards = c
	stats.Convoy = false
	stats.MaxShield = MaxShield
	return stats

func GetFuelStats() -> Dictionary:
	var FuelStats = {
		"FUEL" : _GetStat(STAT_CONST.STATS.FUEL_TANK).StatBase,
		"F_EFF" : _GetStat(STAT_CONST.STATS.FUEL_EFFICIENCY).StatBase,
	}
	for g in StartingItems:
		if (g is ShipPart):
			for up : ShipPartUpgrade in g.Upgrades:
				if (up.UpgradeName == STAT_CONST.STATS.FUEL_TANK):
					FuelStats["FUEL"] += up.UpgradeAmmount
					FuelStats["FUEL"] -= up.PenaltyAmmount
				if (up.UpgradeName == STAT_CONST.STATS.FUEL_EFFICIENCY):
					FuelStats["F_EFF"] += up.UpgradeAmmount
					FuelStats["F_EFF"] -= up.PenaltyAmmount
					
	return FuelStats

func GetCards() -> Dictionary[CardStats, int]:
	var c : Dictionary[CardStats, int]
	for g in StartingItems:
		if (g is AmmoItem and !HasWeapon(g.WType)):
			continue
		for z in g.CardProviding:
			var C = z.duplicate() as CardStats
			C.Tier = g.Tier
			
			var Added = false
			
			for Ca : CardStats in c.keys():
				if (Ca.IsSame(C)):
					c[Ca] += 1
					Added = true
					break
			if (!Added):
				c[C] = 1
			
	for g in Cards:
		var Added = false
		for Ca : CardStats in c.keys():
			if (Ca.IsSame(g)):
				c[Ca] += 1
				Added = true
				break
		if (!Added):
			c[g] = 1

	return c
	
func GetCardList() -> Array[CardStats]:
	var c : Array[CardStats]
	for g in StartingItems:
		if (g is AmmoItem and !HasWeapon(g.WType)):
			continue
		for z in g.CardProviding:
			var C = z.duplicate() as CardStats
			C.Tier = g.Tier

			c.append(C)
			
	for g in Cards:
		c.append(g)

	return c

func HasWeapon(WType : CardStats.WeaponType) -> bool:
	for g : Item in StartingItems:
		if (g is WeaponShipPart):
			if (g.WType == WType):
				return true
	return false

func CheckForIssues() -> void:
	var Itms : Array[Item] = []
	for g in StartingItems:
		if (!Itms.has(g)):
			Itms.append(g)
	
	var Inv = _GetStat(STAT_CONST.STATS.INVENTORY_SPACE).GetStat()
	if (Itms.size() > Inv):
		printerr("Character {0} has more items configured than inventory space.".format([CaptainName]))

func _GetStat(StatN : STAT_CONST.STATS) -> ShipStat:
	for g in CaptainStats:
		if (g.StatName == StatN):
			return g
	return null

func GetStatBaseValue(StatN : STAT_CONST.STATS) -> float:
	return _GetStat(StatN).GetBaseValue()
			
func GetStatShipPartBuff(StatN : STAT_CONST.STATS) -> float:
	return _GetStat(StatN).GetShipPartBuff()

func GetStatShipPartPenalty(StatN : STAT_CONST.STATS) -> float:
	return _GetStat(StatN).GetShipPartPenalty()

func GetStatFinalValue(StatN : STAT_CONST.STATS) -> float:
	return _GetStat(StatN).GetFinalValue()
			
func GetStatCurrentValue(StatN : STAT_CONST.STATS) -> float:
	return _GetStat(StatN).GetCurrentValue()

func CopyStats(Cpt : Captain) -> void:
	CaptainName = Cpt.CaptainName
	CaptainBio = Cpt.CaptainBio
	CaptainPortrait = Cpt.CaptainPortrait
	ShipIcon = Cpt.ShipIcon
	ShipCallsign = Cpt.ShipCallsign
	Cards = Cpt.Cards
	ProvidingFunds = Cpt.ProvidingFunds
	StartingItems = Cpt.StartingItems
	for g in Cpt.CaptainStats:
		CaptainStats.append(g.duplicate(true))
	SetUpStats()
	
		
func IsResourceFull(StatN : STAT_CONST.STATS) -> bool:
	var stat = _GetStat(StatN)
	return stat.GetCurrentValue() == stat.GetFinalValue()

func RefillResource(StatN : STAT_CONST.STATS, RefillAmm : float) -> void:
	_GetStat(StatN).RefilCurrentValue(RefillAmm)
	StatChanged.emit(StatN)

func FullyRefilStat(StatN : STAT_CONST.STATS) -> void:
	_GetStat(StatN).ForceMaxValue()
	StatChanged.emit(StatN)
	
func ConsumeResource(StatN : STAT_CONST.STATS, Consumption : float) -> void:
	_GetStat(StatN).ConsumeResource(Consumption)
	StatChanged.emit(StatN)

func OnShipPartAddedToInventory(It : ShipPart) -> void:
	for Up in It.Upgrades:
		_GetStat(Up.UpgradeName).AddShipPartBuff(Up.UpgradeAmmount)
		_GetStat(Up.UpgradeName).AddShipPartPenalty(Up.PenaltyAmmount)
		RefillResource(Up.UpgradeName, Up.CurrentValue)
	ShipPartChanged.emit(It)

func OnShipPartRemovedFromInventory(It : ShipPart) -> void:
	for Up in It.Upgrades:
		_GetStat(Up.UpgradeName).RemoveShipPartBuff(Up.UpgradeAmmount)
		_GetStat(Up.UpgradeName).AddShipPartPenalty(-Up.PenaltyAmmount)
		if (GetStatCurrentValue(Up.UpgradeName) > GetStatFinalValue(Up.UpgradeName)):
			FullyRefilStat(Up.UpgradeName)
	ShipPartChanged.emit(It)

func GetCharacterInventory() -> CharacterInventory:
	return _CharInv

func LoadStats(Fuel : float, Hull : float) -> void:
	_GetStat(STAT_CONST.STATS.FUEL_TANK).CurrentValue = Fuel
	_GetStat(STAT_CONST.STATS.HULL).CurrentValue = Hull
