extends VBoxContainer
class_name TradeShipStats

@export var ShipStatScene : PackedScene
@export var StatsToShow : Array[ShipStat]

var Stats : Array[ShipStatContainer]

func _ready() -> void:
	for g in StatsToShow.size():
		var statscene = ShipStatScene.instantiate() as ShipStatContainer
		statscene.SetData(StatsToShow[g])
		add_child(statscene)
		Stats.append(statscene)
		
func UpdateValues(Ship : BaseShip) -> void:
	for g in Stats.size():
		var value = Ship.GetStat(Stats[g].STName)
		Stats[g].SetTradeData(value)
