extends Resource
class_name ShipData

@export var Stats : Array[ShipStat]
static var Instance

signal SD_StatsUpdated(StName : String)

func _init() -> void:
	Instance = self
	
static func GetInstance() -> ShipData:
	return Instance
	
func _UpdateStatCurrentValue(StatN : String, StatVal : float):
	GetStat(StatN).CurrentVelue = StatVal

func _AddToStatCurrentValue(StatN : String, StatVal : float):
	var stat = GetStat(StatN)
	stat.CurrentVelue = min(stat.CurrentVelue + StatVal, stat.GetStat())

func IsResourceFull(StatN : String) -> bool:
	var stat = GetStat(StatN)
	return stat.CurrentVelue == stat.GetStat()

func _UpdateStatShipBuff(StatN : String, StatVal : float):
	GetStat(StatN).StatShipBuff = StatVal

func _AddToStatShipBuff(StatN : String, StatVal : float):
	GetStat(StatN).StatShipBuff += StatVal

func _UpdateStatItemBuff(StatN : String, StatVal : float):
	GetStat(StatN).StatItemBuff = StatVal

func _AddToStatItemBuff(StatN : String, StatVal : float):
	GetStat(StatN).StatItemBuff += StatVal

	
func ConsumeResource(StatN : String, Amm : float) -> void:
	_AddToStatCurrentValue(StatN, -Amm)
	SD_StatsUpdated.emit(StatN)
func RefilResource(StatN : String, Amm : float) -> void:
	_AddToStatCurrentValue(StatN, Amm)
	SD_StatsUpdated.emit(StatN)
func SetStatValue(StatN : String, Amm : float) -> void:
	_UpdateStatCurrentValue(StatN, Amm)
	SD_StatsUpdated.emit(StatN)
func ApplyCaptainStats(CptStats : Array[ShipStat]) -> void:
	for g in CptStats:
			_AddToStatShipBuff(g.StatName ,g.StatBase)
			#if (g is FluidShipStat):
				#_AddToStatCurrentValue(g.StatName, g.StatCurrentVal)
			SD_StatsUpdated.emit(g.StatName)
func RemoveCaptainStats(CptStats : Array[ShipStat]) -> void:
	for g in CptStats:
			_AddToStatShipBuff(g.StatName , - g.StatBase)
			#if (g is FluidShipStat):
				#_AddToStatCurrentValue(g.StatName, g.StatCurrentVal)
			SD_StatsUpdated.emit(g.StatName)
func ApplyShipStats(ShipStats : Array[BaseShipStat]) -> void:
		for g in ShipStats.size():
			var shipst = ShipStats[g] as BaseShipStat
			_AddToStatShipBuff(shipst.StatName ,shipst.StatBuff)
			if (shipst is FluidShipStat):
				_AddToStatCurrentValue(shipst.StatName, shipst.StatCurrentVal)
			SD_StatsUpdated.emit(shipst.StatName)
func RemoveShipStats(ShipStats : Array[BaseShipStat]) -> void:
		for g in ShipStats.size():
			var shipst = ShipStats[g] as BaseShipStat
			_AddToStatShipBuff(shipst.StatName, -shipst.StatBuff)
			#if (shipst is FluidShipStat):
				#var st = GetStat(shipst.StatName)
				#var newstat = st.GetStat()
				#f (st.CurrentVelue > newstat):
				#var dif = st.CurrentVelue - newstat
				#UpdateStatCurrentValue(st.StatName, newstat)
				#shipst.StatCurrentVal = dif
			SD_StatsUpdated.emit(shipst.StatName)
func ApplyShipPartStat(Part : ShipPart) -> void:
	var st = GetStat(Part.UpgradeName)
	_AddToStatItemBuff(Part.UpgradeName ,Part.UpgradeAmm)
	_AddToStatCurrentValue(st.StatName, Part.CurrentVal)
	SD_StatsUpdated.emit(st.StatName)
func RemoveShipPartStat(Part : ShipPart) -> void:
	var st = GetStat(Part.UpgradeName)
	_AddToStatItemBuff(Part.UpgradeName ,-Part.UpgradeAmm)
	var newstat = st.GetStat()
	if (st.CurrentVelue > newstat):
		var dif = st.CurrentVelue - newstat
		_UpdateStatCurrentValue(st.StatName, newstat)
		Part.CurrentVal = dif
	else:
		Part.CurrentVal = 0
		
	SD_StatsUpdated.emit(st.StatName)
				
			
func GetStat(Name : String) -> ShipStat:
	var stat : ShipStat
	for g in Stats.size():
		if (Stats[g].StatName == Name):
			stat = Stats[g]
	return stat
func GetSaveData() -> Resource:
	var CurrentStats : Array[float] = []
	CurrentStats.append(GetStat("HP").CurrentVelue)
	CurrentStats.append(GetStat("HULL").CurrentVelue)
	#CurrentStats.append(GetStat("OXYGEN").CurrentVelue)
	CurrentStats.append(GetStat("FUEL").CurrentVelue)
	var save = StatSave.new()
	save.Value = CurrentStats
	return save
