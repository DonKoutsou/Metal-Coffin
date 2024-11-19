extends Resource
class_name Captain

@export var CaptainName : String
@export var CaptainBio : String
@export var CaptainPortrait : Texture
@export var ShipIcon : Texture
@export var CaptainStats : Array[ShipStat]

func GetStat(StName : String):
	for g in CaptainStats:
		if (g.StatName == StName):
			return g
func GetStatValue(StName : String):
	for g in CaptainStats:
		if (g.StatName == StName):
			return g.StatBase
