extends Resource

class_name BaseShip

@export var ShipName : String
@export var ShipDesc : String
@export var ShipScene : PackedScene

@export var Icon : Texture
@export var TopIcon : Texture
@export var Buffs : Array[BaseShipStat]

func GetStat(StatName : String) -> BaseShipStat:
	for g in Buffs.size():
		if (Buffs[g].StatName == StatName):
			return Buffs[g]
	return null
