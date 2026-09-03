@tool
extends VBoxContainer
class_name InventoryShipStats
@export var ShipStatScene : PackedScene
@export var StatsShown : Array[STAT_CONST.STATS]
#@export var ShipIcon : TextureRect
var CurrentShownCaptain : Captain

var Stats : Array[ShipStatContainer]
var SpeedStat : ShipStatContainer
var Rangestat : ShipStatContainer
var ValueStat : ShipStatContainer
var NoiseStat : ShipStatContainer

func _ready() -> void:
	for g in StatsShown.size():

		var statscene = ShipStatScene.instantiate() as ShipStatContainer
		statscene.SetData(StatsShown[g])
		$GridContainer.add_child(statscene)
		Stats.append(statscene)
	
	SpeedStat = ShipStatScene.instantiate() as ShipStatContainer
	SpeedStat.SetDataCustom(1000, "km/h", "SPEED", STAT_CONST.STATS.SPEED)
	SpeedStat.STName = STAT_CONST.STATS.SPEED
	$GridContainer.add_child(SpeedStat)
	
	Rangestat = ShipStatScene.instantiate() as ShipStatContainer
	Rangestat.SetDataCustom(10000, "km", "RANGE", STAT_CONST.STATS.RANGE)
	Rangestat.STName = STAT_CONST.STATS.RANGE
	$GridContainer.add_child(Rangestat)
	
	ValueStat = ShipStatScene.instantiate() as ShipStatContainer
	ValueStat.SetDataCustom(1000000, "₯", "VALUE", STAT_CONST.STATS.VALUE)
	ValueStat.STName = STAT_CONST.STATS.VALUE
	$GridContainer.add_child(ValueStat)
	
	NoiseStat = ShipStatScene.instantiate() as ShipStatContainer
	NoiseStat.SetDataCustom(STAT_CONST.GetStatMaxValue(STAT_CONST.STATS.SOUND_SIGNATURE), STAT_CONST.GetStatMetric(STAT_CONST.STATS.SOUND_SIGNATURE), "SOUND SIGNATURE", STAT_CONST.STATS.SOUND_SIGNATURE)
	NoiseStat.STName = STAT_CONST.STATS.SOUND_SIGNATURE
	$GridContainer.add_child(NoiseStat)

func Toggle(t) -> void:
	if (t):
		visible = true
	for g in Stats:
		g.visible = t
		await Helper.wait(0.02)
	visible = t

func ShowStats(stats : Array[STAT_CONST.STATS]) -> void:
	for g in Stats:
		g.visible = g.STName in stats
	SpeedStat.visible = SpeedStat.STName in stats
	Rangestat.visible = Rangestat.STName in stats
	ValueStat.visible = ValueStat.STName in stats
	NoiseStat.visible = NoiseStat.STName in stats

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
	
	var ChValue = CurrentShownCaptain.ProvidingFunds
	var Itvalue = CurrentShownCaptain.GetValue() - ChValue
	ValueStat.UpdateStatCustom(ChValue, Itvalue, 0)
	
	var NormalisedThrust = Helper.normalize_value(CurrentShownCaptain.GetShipThrust(), 0, STAT_CONST.GetStatMaxValue(STAT_CONST.STATS.THRUST))
	
	NoiseStat.UpdateStatCustom(0, roundi(Helper.mapvalue(NormalisedThrust, 50, STAT_CONST.GetStatMaxValue(STAT_CONST.STATS.SOUND_SIGNATURE))), 0)

func UpdateEditorValues(ShowItemStats : bool) -> void:
	var stats : Dictionary[STAT_CONST.STATS, Dictionary] = {}
	for g in STAT_CONST.STATS.values():
		stats[g] = {"Base" : CurrentShownCaptain.GetStatBaseValue(g), "ShipPartBuff" : 0.0, "ShipPartPenalty" : 0.0}
	
	if (ShowItemStats):
		for g in CurrentShownCaptain.StartingItems:
			if (g is ShipPart):
				for up : ShipPartUpgrade in g.Upgrades:
					stats[up.UpgradeName]["ShipPartBuff"] += up.UpgradeAmmount
					stats[up.UpgradeName]["ShipPartPenalty"] += up.PenaltyAmmount
				stats[STAT_CONST.STATS.VALUE]["ShipPartBuff"] += g.Cost
	
	for g in Stats.size():
		var st = stats[Stats[g].STName]
		Stats[g].UpdateStatValue(st["Base"] , st["ShipPartBuff"], st["ShipPartPenalty"])
	
	var thrust = stats[STAT_CONST.STATS.THRUST]["Base"] + stats[STAT_CONST.STATS.THRUST]["ShipPartBuff"] + stats[STAT_CONST.STATS.THRUST]["ShipPartPenalty"]
	var weight = stats[STAT_CONST.STATS.WEIGHT]["Base"] + stats[STAT_CONST.STATS.WEIGHT]["ShipPartBuff"] + stats[STAT_CONST.STATS.WEIGHT]["ShipPartPenalty"]
	
	var Speed = roundi((thrust * 1000) / weight)
	SpeedStat.UpdateStatCustom(0, Speed, 0)
	
	var FuelEf = stats[STAT_CONST.STATS.FUEL_EFFICIENCY]["Base"] + stats[STAT_CONST.STATS.FUEL_EFFICIENCY]["ShipPartBuff"] + stats[STAT_CONST.STATS.FUEL_EFFICIENCY]["ShipPartPenalty"]
	var FuelCap = stats[STAT_CONST.STATS.FUEL_TANK]["Base"] + stats[STAT_CONST.STATS.FUEL_TANK]["ShipPartBuff"] + stats[STAT_CONST.STATS.FUEL_TANK]["ShipPartPenalty"]
	
	var eff_eff = (FuelEf / pow(weight, 0.5)) * 10
	var ShipRange = roundi(FuelCap * eff_eff)
	Rangestat.UpdateStatCustom(0, ShipRange, 0)
	
	var NormalisedThrust = Helper.normalize_value(thrust, 0, STAT_CONST.GetStatMaxValue(STAT_CONST.STATS.THRUST))
	NoiseStat.UpdateStatCustom(0, roundi(Helper.mapvalue(NormalisedThrust, 50, STAT_CONST.GetStatMaxValue(STAT_CONST.STATS.THRUST))), 0)
	
	var ChValue = CurrentShownCaptain.ProvidingFunds
	var Itvalue = stats[STAT_CONST.STATS.VALUE]["Base"] + stats[STAT_CONST.STATS.VALUE]["ShipPartBuff"] + stats[STAT_CONST.STATS.VALUE]["ShipPartPenalty"]
	ValueStat.UpdateStatCustom(ChValue, Itvalue, 0)

func SetCaptain(Cpt : Captain) -> void:
	CurrentShownCaptain = Cpt
	call_deferred("UpdateValues")

func SetCaptainEditor(Cpt : Captain, ShowItemStats : bool) -> void:
	CurrentShownCaptain = Cpt
	call_deferred("UpdateEditorValues", ShowItemStats)
