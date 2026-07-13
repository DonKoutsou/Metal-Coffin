extends Area2D

class_name BaseDock

var DockedShips : Array[MapShip]
var Captives : Array[MapShip]

#----------------------------------------
func GetDockedShips() -> Array[MapShip]:
	var Ships : Array[MapShip]
	Ships.append_array(DockedShips)
	Ships.append_array(Captives)
	return Ships

#----------------------------------------
func GetCaptains() -> Array[Captain]:
	var cptns : Array[Captain]
	for g in DockedShips:
		cptns.append(g.Cpt)
	return cptns

#----------------------------------------
func DronesHaveFuel(f : float) -> bool:
	var fuelneeded = f
	for g in GetDockedShips():
		fuelneeded -= g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		if (fuelneeded <= 0):
			return true
	return false

#----------------------------------------
func SyphonFuelFromDrones(amm : float) -> void:
	for g in GetDockedShips():
		var Cap = g.Cpt as Captain
		#var FuelTank = g.Cpt.GetStat(STAT_CONST.STATS.FUEL_TANK) as ShipStat
		if (Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > amm):
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK ,amm)
			return
		else:
			var FuelAmm = Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
			amm -= FuelAmm
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, FuelAmm)

#-----------------------------------------
func GetDockedFuel() -> float:
	var fuel : float = 0
	for g in DockedShips:
		fuel += g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
	return fuel
