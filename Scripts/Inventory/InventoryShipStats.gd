extends VBoxContainer
class_name InventoryShipStats
@export var ShipStatScene : PackedScene
@export var StatsShown : Array[STAT_CONST.STATS]
@export var ShipIcon : TextureRect
var CurrentShownCaptain : Captain

var Stats : Array[ShipStatContainer]

func _ready() -> void:
	for g in StatsShown.size():
		var statscene = ShipStatScene.instantiate() as ShipStatContainer
		statscene.SetData(StatsShown[g])
		add_child(statscene)
		Stats.append(statscene)

func UpdateValues() -> void:
	
	for g in Stats.size():
		var value = CurrentShownCaptain.GetStatBaseValue(Stats[g].STName)
		var ItemBuff = CurrentShownCaptain.GetStatShipPartBuff(Stats[g].STName)
		var ItemPenalty = CurrentShownCaptain.GetStatShipPartPenalty(Stats[g].STName)
		Stats[g].UpdateStatValue(value , ItemBuff, ItemPenalty)

func SetCaptain(Cpt : Captain) -> void:
	CurrentShownCaptain = Cpt
	call_deferred("UpdateValues")
	#UpdateValues()
	ShipIcon.texture = Cpt.ShipIcon
