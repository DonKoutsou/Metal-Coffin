extends MapShip

class_name PlayerShip

@export var CaptainIcon : Texture

static var Instance : PlayerShip

func _ready() -> void:
	super()
	Instance = self
	
func GetDroneDock() -> DroneDock:
	return $DroneDock
static func GetInstance() -> PlayerShip:
	return Instance
func _physics_process(_delta: float) -> void:
	if (Paused):
		return
	super(_delta)
	if ($Aceleration.position.x == 0):
		if (CurrentPort != null):
			#CurrentPort.OnSpotVisited()
			if (CanRefuel):
				if (!ShipData.GetInstance().IsResourceFull("FUEL") and CurrentPort.PlayerFuelReserves > 0):
					var maxfuelcap = ShipData.GetInstance().GetStat("FUEL").GetStat()
					var currentfuel = ShipData.GetInstance().GetStat("FUEL").GetCurrentValue()
					var timeleft = (min(maxfuelcap, currentfuel + CurrentPort.PlayerFuelReserves) - currentfuel) / 0.05 / 6
					ShipDockActions.emit("Refueling", true, roundi(timeleft))
					#ToggleShowRefuel("Refueling", true, roundi(timeleft))
					ShipData.GetInstance().RefilResource("FUEL", 0.05 * SimulationSpeed)
					CurrentPort.PlayerFuelReserves -= 0.05 * SimulationSpeed
				else:
					ShipDockActions.emit("Refueling", false, 0)
				if (CurrentPort.PlayerFuelReserves > 0):
					var dr = GetDroneDock().DockedDrones
					for g in dr:
						if (g.Fuel < g.Cpt.GetStatValue("FUEL_TANK")):
							g.Fuel += 0.05 * SimulationSpeed
							var timeleft = (min(g.Cpt.GetStatValue("FUEL_TANK"), g.Fuel + CurrentPort.PlayerFuelReserves) - g.Fuel) / 0.05 / 6
							g.ShipDockActions.emit("Refueling", true, roundi(timeleft))
							CurrentPort.PlayerFuelReserves -= 0.05 * SimulationSpeed
						else:
							g.ShipDockActions.emit("Refueling", false, 0)
				
					#ToggleShowRefuel("Refueling", false)
			if (CanRepair):
				if (!ShipData.GetInstance().IsResourceFull("HULL") and CurrentPort.PlayerRepairReserves):
					var timeleft = ((ShipData.GetInstance().GetStat("HULL").GetStat() - ShipData.GetInstance().GetStat("HULL").GetCurrentValue()) / 0.05 / 6)
					ShipDockActions.emit("Repairing", true, roundi(timeleft))
					#ToggleShowRefuel("Repairing", true, roundi(timeleft))
					ShipData.GetInstance().RefilResource("HULL", 0.05 * SimulationSpeed)
				else:
					ShipDockActions.emit("Repairing", false, 0)
					#ToggleShowRefuel("Repairing", false)
			if (CanUpgrade):
				var inv = Inventory.GetInstance()
				if (inv.UpgradedItem != null):
					#ToggleShowRefuel("Upgrading", true, roundi(inv.GetUpgradeTimeLeft()))
					ShipDockActions.emit("Upgrading", true, roundi(inv.GetUpgradeTimeLeft()))
				else:
					ShipDockActions.emit("Upgrading", false, 0)
					#ToggleShowRefuel("Upgrading", false)
		return
	var fuel = ($Aceleration.position.x / 10 / ShipData.GetInstance().GetStat("FUEL_EFFICIENCY").GetStat()) * SimulationSpeed
	var Dat = ShipData.GetInstance()
	if (Dat.GetStat("FUEL").GetCurrentValue() < fuel):
		if (GetDroneDock().DronesHaveFuel(fuel)):
			GetDroneDock().SyphonFuelFromDrones(fuel)
		else:
			HaltShip()
			PopUpManager.GetInstance().DoFadeNotif("You have run out of fuel.")
			#set_physics_process(false)
			return
	else:
		Dat.ConsumeResource("FUEL", fuel)
	#if (Dat.GetStat("CRYO").GetStat() == 0):
		#var oxy = $Node2D.position.x / 100
		#if (Dat.GetStat("OXYGEN").GetCurrentValue() < oxy):
			#HaltShip()
			#PopUpManager.GetInstance().DoPopUp("You have run out of oxygen.")
			##set_physics_process(false)
			#return
		#Dat.RefilResource("OXYGEN", -oxy)
	for g in SimulationSpeed:
		global_position = $Aceleration.global_position
		
func UpdateFuelRange(fuel : float, fuel_ef : float):
	var FuelRangeIndicator = $Fuel_Range
	#var FuelRangeIndicatorDescriptor = $Fuel_Range/Label
	var FuelMat = FuelRangeIndicator.material as ShaderMaterial
	#calculate the range taking fuel efficiency in mind
	var distall = (fuel * 10 * fuel_ef) * 2
	distall += (GetDroneDock().GetDroneFuel() * 10 * 2) * 2
	#scalling of collor rect
	var tw = create_tween()

	tw.tween_method(SetFuelShaderRange, FuelMat.get_shader_parameter("scale_factor"), (distall/2) / 10000, 0.5)

func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = ShipType.GetStat("HULL").StatBuff
	stats.FirePower = 1
	stats.ShipIcon = ShipType.TopIcon
	stats.CaptainIcon = CaptainIcon
	stats.Name = "Player"
	return stats
