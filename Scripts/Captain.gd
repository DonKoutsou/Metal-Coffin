extends Resource
class_name Captain

@export var CaptainName : String
@export var CaptainBio : String
@export var CaptainPortrait : Texture
@export var ShipIcon : Texture
@export var CaptainStats : Array[ShipStat]
@export var ShipCallsign : String = "P"

func GetStat(StName : String) -> ShipStat:
	for g in CaptainStats:
		if (g.StatName == StName):
			return g
	return null
func GetStatValue(StName : String):
	for g in CaptainStats:
		if (g.StatName == StName):
			return g.StatBase
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
