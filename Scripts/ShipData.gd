extends Resource
class_name ShipData

@export var Stats : Array[ShipStat]

static var Instance

func _init() -> void:
	Instance = self
	
static func GetInstance() -> ShipData:
	return Instance

func ApplyShipStats(ShipStats : Array[BaseShipStat]) -> void:
	for j in Stats.size():
		var st = Stats[j]
		for g in ShipStats.size():
			var shipst = ShipStats[g] as BaseShipStat
			if (st.StatName == shipst.StatName):
				st.StatShipBuff = shipst.StatBuff
				if (shipst is FluidShipStat):
					st.CurrentVelue = min(st.CurrentVelue + shipst.StatCurrentVal, st.GetStat())
func RemoveShipStats(ShipStats : Array[BaseShipStat]) -> void:
	for j in Stats.size():
		var st = Stats[j]
		for g in ShipStats.size():
			var shipst = ShipStats[g] as BaseShipStat
			if (st.StatName == shipst.StatName):
				st.StatShipBuff = 0
				if (shipst is FluidShipStat):
					var newstat = st.GetStat()
					if (st.CurrentVelue > newstat):
						var dif = st.CurrentVelue - newstat
						st.CurrentVelue = newstat
						shipst.StatCurrentVal = dif
					else:
						shipst.StatCurrentVal = 0
func ApplyShipPartStat(Part : ShipPart) -> void:
	for j in Stats.size():
		var st = Stats[j]
		if (st.StatName == Part.UpgradeName):
			st.StatItemBuff += Part.UpgradeAmm
			st.CurrentVelue = min(st.CurrentVelue + Part.CurrentVal, st.GetStat())
func RemoveShipPartStat(Part : ShipPart) -> void:
	for j in Stats.size():
		var st = Stats[j]
		if (st.StatName == Part.UpgradeName):
			st.StatItemBuff -= Part.UpgradeAmm
			var newstat = st.GetStat()
			if (st.CurrentVelue > newstat):
				var dif = st.CurrentVelue - newstat
				st.CurrentVelue = newstat
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
