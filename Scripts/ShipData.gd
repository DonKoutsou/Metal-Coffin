extends Resource
class_name ShipData

@export var Stats : Array[ShipStat]
static var Instance

signal StatsUpdated(StName : String)

func _init() -> void:
	Instance = self
	
static func GetInstance() -> ShipData:
	return Instance
	
func UpdateStatCurrentValue(StatN : String, StatVal : float):
	GetStat(StatN).CurrentVelue = StatVal
	StatsUpdated.emit(StatN)
func AddToStatCurrentValue(StatN : String, StatVal : float):
	var stat = GetStat(StatN)
	stat.CurrentVelue = min(stat.CurrentVelue + StatVal, stat.GetStat())
	StatsUpdated.emit(StatN)
func UpdateStatShipBuff(StatN : String, StatVal : float):
	GetStat(StatN).StatShipBuff = StatVal
	StatsUpdated.emit(StatN)
func AddToStatShipBuff(StatN : String, StatVal : float):
	GetStat(StatN).StatShipBuff += StatVal
	StatsUpdated.emit(StatN)
func UpdateStatItemBuff(StatN : String, StatVal : float):
	GetStat(StatN).StatItemBuff = StatVal
	StatsUpdated.emit(StatN)
func AddToStatItemBuff(StatN : String, StatVal : float):
	GetStat(StatN).StatItemBuff += StatVal
	StatsUpdated.emit(StatN)
	
func ApplyShipStats(ShipStats : Array[BaseShipStat]) -> void:
		for g in ShipStats.size():
			var shipst = ShipStats[g] as BaseShipStat
			AddToStatShipBuff(shipst.StatName ,shipst.StatBuff)
			if (shipst is FluidShipStat):
				AddToStatCurrentValue(shipst.StatName, shipst.StatCurrentVal)
func RemoveShipStats(ShipStats : Array[BaseShipStat]) -> void:
		for g in ShipStats.size():
			var shipst = ShipStats[g] as BaseShipStat
			AddToStatShipBuff(shipst.StatName, -shipst.StatBuff)
			#if (shipst is FluidShipStat):
				#var st = GetStat(shipst.StatName)
				#var newstat = st.GetStat()
				#f (st.CurrentVelue > newstat):
				#var dif = st.CurrentVelue - newstat
				#UpdateStatCurrentValue(st.StatName, newstat)
				#shipst.StatCurrentVal = dif
					
func ApplyShipPartStat(Part : ShipPart) -> void:
	var st = GetStat(Part.UpgradeName)
	AddToStatItemBuff(Part.UpgradeName ,Part.UpgradeAmm)
	AddToStatCurrentValue(st.StatName, Part.CurrentVal)
func RemoveShipPartStat(Part : ShipPart) -> void:
	var st = GetStat(Part.UpgradeName)
	AddToStatItemBuff(Part.UpgradeName ,-Part.UpgradeAmm)
	var newstat = st.GetStat()
	if (st.CurrentVelue > newstat):
		var dif = st.CurrentVelue - newstat
		UpdateStatCurrentValue(st.StatName, newstat)
		Part.CurrentVal = dif
	else:
		Part.CurrentVal = 0
				
			
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
	CurrentStats.append(GetStat("OXYGEN").CurrentVelue)
	CurrentStats.append(GetStat("FUEL").CurrentVelue)
	var save = StatSave.new()
	save.Value = CurrentStats
	return save
