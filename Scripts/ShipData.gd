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
			var shipst = ShipStats[g]
			if (st.StatName == shipst.StatName):
				st.SetShipBuff(shipst.StatBuff)
func GetStat(Name : String) -> ShipStat:
	var stat : ShipStat
	for g in Stats.size():
		if (Stats[g].StatName == Name):
			stat = Stats[g]
	return stat
