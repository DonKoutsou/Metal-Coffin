extends VBoxContainer
class_name InventoryShipStats
@export var CharPortrait : TextureRect
@export var ShipStatScene : PackedScene
@export var StatsToShow : Array[ShipStat]
@export var ShipIcon : TextureRect
var CurrentShownCaptain : Captain

var Stats : Array[ShipStatContainer]

func _ready() -> void:
	for g in StatsToShow.size():
		var statscene = ShipStatScene.instantiate() as ShipStatContainer
		statscene.SetData(StatsToShow[g])
		add_child(statscene)
		Stats.append(statscene)
		
func UpdateValues() -> void:
	for g in Stats.size():
		var value = CurrentShownCaptain.GetStat(Stats[g].STName).GetBaseStat()
		var ItemBuff = CurrentShownCaptain.GetStat(Stats[g].STName).GetItemBuff()
		var ShipValue = CurrentShownCaptain.GetStat(Stats[g].STName).GetShipBuff()
		Stats[g].UpdateStatValue(value, ItemBuff, ShipValue)

func SetCaptain(Cpt : Captain) -> void:
	CharPortrait.texture = Cpt.CaptainPortrait
	CurrentShownCaptain = Cpt
	UpdateValues()
	ShipIcon.texture = Cpt.ShipIcon
