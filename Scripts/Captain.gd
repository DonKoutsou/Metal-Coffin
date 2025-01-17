extends Resource
class_name Captain

@export var CaptainName : String
@export var CaptainBio : String
@export var CaptainPortrait : Texture
@export var ShipIcon : Texture
@export var CaptainStats : Array[ShipStat]
@export var ShipCallsign : String = "P"
@export var StartingItems : Array[Item]
@export var CurrentPort : String
@export var CheckForErrors : bool = false
#used to signal ship so it can change size of colliders
signal ShipPartChanged(P : ShipPart)

func _init() -> void:
	if (OS.is_debug_build() and CheckForErrors):
		call_deferred("CheckForIssues")
		
func CheckForIssues() -> void:
	var Itms : Array[Item] = []
	for g in StartingItems:
		if (!Itms.has(g)):
			Itms.append(g)
	
	var Inv = GetStat("INVENTORY_CAPACITY").GetStat()
	if (Itms.size() > Inv):
		printerr("Character {0} has more items configured than inventory space.".format([CaptainName]))

func GetStat(StName : String) -> ShipStat:
	for g in CaptainStats:
		if (g.StatName == StName):
			return g
	return null
func GetStatValue(StName : String):
	for g in CaptainStats:
		if (g.StatName == StName):
			return g.StatBase
func GetStatFinalValue(StName : String):
	for g in CaptainStats:
		if (g.StatName == StName):
			return g.GetStat()
func GetStatCurrentValue(StName : String):
	for g in CaptainStats:
		if (g.StatName == StName):
			return g.CurrentVelue

func CopyStats(Cpt : Captain) -> void:
	CaptainName = Cpt.CaptainName
	CaptainBio = Cpt.CaptainBio
	CaptainPortrait = Cpt.CaptainPortrait
	ShipIcon = Cpt.ShipIcon
	ShipCallsign = Cpt.ShipCallsign
	for g in Cpt.CaptainStats:
		CaptainStats.append(g.duplicate(true))
		
func IsResourceFull(StatN : String) -> bool:
	var stat = GetStat(StatN)
	return stat.CurrentVelue == stat.GetStat()
	
func OnShipPartAddedToInventory(It : ShipPart) -> void:
	for Up in It.Upgrades:
		GetStat(Up.UpgradeName).SetItemBuff(Up.UpgradeAmmount)
		GetStat(Up.UpgradeName).RefilCurrentVelue(Up.CurrentValue)
	#GetStat(It.UpgradeName).SetItemBuff(It.UpgradeAmm)
	#GetStat(It.UpgradeName).RefilCurrentVelue(It.CurrentVal)
	ShipPartChanged.emit(It)

func OnShipPartRemovedFromInventory(It : ShipPart) -> void:
	for Up in It.Upgrades:
		GetStat(Up.UpgradeName).SetItemBuff(-Up.UpgradeAmmount)
		if (GetStatCurrentValue(Up.UpgradeName) > GetStatFinalValue(Up.UpgradeName)):
			GetStat(Up.UpgradeName).CurrentVelue = GetStatFinalValue(Up.UpgradeName)
		#GetStat(It.UpgradeNames[g]).RefilCurrentVelue(It.UpCurrentVal[g])
	#GetStat(It.UpgradeName).SetItemBuff(-It.UpgradeAmm)
	#if (GetStatCurrentValue(It.UpgradeName) > GetStatFinalValue(It.UpgradeName)):
		#GetStat(It.UpgradeName).CurrentVelue = GetStatFinalValue(It.UpgradeName)
	ShipPartChanged.emit(It)
