extends VBoxContainer
class_name InventoryShipStats

@export var ShipStatScene : PackedScene
@export var StatsToShow : Array[ShipStat]

var Stats : Array[ShipStatContainer]

func _ready() -> void:
	for g in StatsToShow.size():
		var statscene = ShipStatScene.instantiate() as ShipStatContainer
		statscene.SetData(StatsToShow[g])
		add_child(statscene)
		Stats.append(statscene)
		
func UpdateValues() -> void:
	for g in Stats.size():
		var value = ShipData.GetInstance().GetStat(Stats[g].STName).GetBaseStat()
		var ItemBuff = ShipData.GetInstance().GetStat(Stats[g].STName).GetItemBuff()
		var ShipValue = ShipData.GetInstance().GetStat(Stats[g].STName).GetShipBuff()
		Stats[g].UpdateStatValue(value, ItemBuff, ShipValue)
