extends VBoxContainer
class_name InventoryShipStats
@export var CharPortrait : TextureRect
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
		var Multiplier = 1
		#if (Stats[g].STName == STAT_CONST.STATS.SPEED):
			#Multiplier = 360
		var value = CurrentShownCaptain.GetStatBaseValue(Stats[g].STName)
		var ItemBuff = CurrentShownCaptain.GetStatShipPartBuff(Stats[g].STName)
		#var ShipValue = CurrentShownCaptain.GetStatShipBuff(Stats[g].STName)
		Stats[g].UpdateStatValue(value * Multiplier, ItemBuff * Multiplier)

func SetCaptain(Cpt : Captain) -> void:
	CharPortrait.texture = Cpt.CaptainPortrait
	CurrentShownCaptain = Cpt
	UpdateValues()
	ShipIcon.texture = Cpt.ShipIcon
