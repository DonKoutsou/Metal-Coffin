extends VBoxContainer
class_name InventoryShipStats
@export var ShipStatScene : PackedScene
@export var StatsShown : Array[STAT_CONST.STATS]
#@export var ShipIcon : TextureRect
var CurrentShownCaptain : Captain

var Stats : Array[ShipStatContainer]
var SpeedStat : ShipStatContainer
var Rangestat : ShipStatContainer

func _ready() -> void:
	for g in StatsShown.size():

		var statscene = ShipStatScene.instantiate() as ShipStatContainer
		statscene.SetData(StatsShown[g])
		add_child(statscene)
		Stats.append(statscene)
	
	SpeedStat = ShipStatScene.instantiate() as ShipStatContainer
	SpeedStat.SetDataCustom(1000, "km/h", "SPEED", STAT_CONST.STATS.SPEED)
	add_child(SpeedStat)
	
	Rangestat = ShipStatScene.instantiate() as ShipStatContainer
	Rangestat.SetDataCustom(10000, "km", "RANGE", STAT_CONST.STATS.RANGE)
	add_child(Rangestat)

func UpdateValues() -> void:
	var FuelCap
	var FuelEf
	var W
	
	for g in Stats.size():
		
		var value = CurrentShownCaptain.GetStatBaseValue(Stats[g].STName)
		var ItemBuff = CurrentShownCaptain.GetStatShipPartBuff(Stats[g].STName)
		var ItemPenalty = CurrentShownCaptain.GetStatShipPartPenalty(Stats[g].STName)
		Stats[g].UpdateStatValue(value , ItemBuff, ItemPenalty)
		if (Stats[g].STName == STAT_CONST.STATS.FUEL_TANK):
			FuelCap = value + ItemBuff + ItemPenalty
		if (Stats[g].STName == STAT_CONST.STATS.FUEL_EFFICIENCY):
			FuelEf = value + ItemBuff + ItemPenalty
		if (Stats[g].STName == STAT_CONST.STATS.WEIGHT):
			W = value + ItemBuff + ItemPenalty
	
	var Speed = roundi((CurrentShownCaptain.GetStatFinalValue(STAT_CONST.STATS.THRUST) * 1000) / CurrentShownCaptain.GetStatFinalValue(STAT_CONST.STATS.WEIGHT))
	SpeedStat.UpdateStatCustom(0, Speed, 0)

	var eff_eff = (FuelEf / pow(W, 0.5)) * 10
	var ShipRange = roundi(FuelCap * eff_eff)
	Rangestat.UpdateStatCustom(0, ShipRange, 0)

func SetCaptain(Cpt : Captain) -> void:
	CurrentShownCaptain = Cpt
	call_deferred("UpdateValues")
	#UpdateValues()
	#ShipIcon.texture = Cpt.ShipIcon
