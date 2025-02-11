extends Resource
class_name Captain

@export var CaptainName : String
@export var CaptainBio : String
@export var CaptainPortrait : Texture
@export var ShipIcon : Texture
@export var CaptainStats : Array[ShipStat]
var MappedStats : Array[STAT_CONST.STATS]
@export var ShipCallsign : String = "P"
@export var StartingItems : Array[Item]
@export var CurrentPort : String
@export var CheckForErrors : bool = false
@export var ProvidingFunds : int = 0
#used to signal ship so it can change size of colliders
signal ShipPartChanged(P : ShipPart)
signal StatChanged(NewVal : float)

var _CharInv : CharacterInventory

func _init() -> void:
	call_deferred("MapStats")
	if (OS.is_debug_build() and CheckForErrors):
		call_deferred("CheckForIssues")

func MapStats() -> void:
	MappedStats.clear()
	for g in CaptainStats:
		MappedStats.push_back(g.GetStatName())

func CheckForIssues() -> void:
	var Itms : Array[Item] = []
	for g in StartingItems:
		if (!Itms.has(g)):
			Itms.append(g)
	
	var Inv = _GetStat(STAT_CONST.STATS.INVENTORY_SPACE).GetStat()
	if (Itms.size() > Inv):
		printerr("Character {0} has more items configured than inventory space.".format([CaptainName]))

func _GetStat(StatN : STAT_CONST.STATS) -> ShipStat:
	return CaptainStats[MappedStats.find(StatN)]

func GetStatBaseValue(StatN : STAT_CONST.STATS) -> float:
	return _GetStat(StatN).GetBaseValue()
			
func GetStatShipPartBuff(StatN : STAT_CONST.STATS) -> float:
	return _GetStat(StatN).GetShipPartBuff()

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
	MappedStats = Cpt.MappedStats
	for g in Cpt.CaptainStats:
		CaptainStats.append(g.duplicate(true))
		
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
		RefillResource(Up.UpgradeName, Up.CurrentValue)
	ShipPartChanged.emit(It)

func OnShipPartRemovedFromInventory(It : ShipPart) -> void:
	for Up in It.Upgrades:
		_GetStat(Up.UpgradeName).AddShipPartBuff(-Up.UpgradeAmmount)
		if (GetStatCurrentValue(Up.UpgradeName) > GetStatFinalValue(Up.UpgradeName)):
			FullyRefilStat(Up.UpgradeName)
	ShipPartChanged.emit(It)

func GetCharacterInventory() -> CharacterInventory:
	return _CharInv

func LoadStats(Fuel : float, Hull : float) -> void:
	_GetStat(STAT_CONST.STATS.FUEL_TANK).CurrentValue = Fuel
	_GetStat(STAT_CONST.STATS.HULL).CurrentValue = Hull
