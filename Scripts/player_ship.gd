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
	#if ($Aceleration.position.x == 0):
	if (CurrentPort != null):
		#CurrentPort.OnSpotVisited()
		if (CanRefuel):
			if (!ShipData.GetInstance().IsResourceFull("FUEL") and CurrentPort.PlayerFuelReserves > 0):
				var maxfuelcap = ShipData.GetInstance().GetStat("FUEL").GetStat()
				var currentfuel = ShipData.GetInstance().GetStat("FUEL").GetCurrentValue()
				var timeleft = (min(maxfuelcap, currentfuel + CurrentPort.PlayerFuelReserves) - currentfuel) / 0.05 / 6
				ShipDockActions.emit("Refueling", true, roundi(timeleft))
				ShipData.GetInstance().RefilResource("FUEL", 0.05 * SimulationSpeed)
				CurrentPort.PlayerFuelReserves -= 0.05 * SimulationSpeed
			else:
				ShipDockActions.emit("Refueling", false, 0)
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
	#if (TakingOff):
		#return
	var fuel = ($Aceleration.position.x / 10 / ShipData.GetInstance().GetStat("FUEL_EFFICIENCY").GetStat()) * SimulationSpeed
	var Dat = ShipData.GetInstance()
	
	if (Dat.GetStat("FUEL").GetCurrentValue() >= fuel):
		Dat.ConsumeResource("FUEL", fuel)
	else: if (GetDroneDock().DronesHaveFuel(fuel)):
		GetDroneDock().SyphonFuelFromDrones(fuel)
		UpdateFuelRange(Dat.GetStat("FUEL").GetCurrentValue(), Dat.GetStat("FUEL_EFFICIENCY").GetStat())
	else:
		HaltShip()
		PopUpManager.GetInstance().DoFadeNotif("You have run out of fuel.")
		#set_physics_process(false)
		return
	for g in GetDroneDock().DockedDrones:
		var dronefuel = ($Aceleration.position.x / 10 / g.Cpt.GetStat("FUEL_EFFICIENCY").GetStat()) * SimulationSpeed
		if (g.Cpt.GetStat("FUEL_TANK").CurrentVelue > dronefuel):
			g.Cpt.GetStat("FUEL_TANK").CurrentVelue -= dronefuel
		else : if (Dat.GetStat("FUEL").GetCurrentValue() >= dronefuel):
			Dat.ConsumeResource("FUEL", dronefuel)
		else:
			HaltShip()
			PopUpManager.GetInstance().DoFadeNotif("You have run out of fuel.")
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

func ToggleRadar():
	super()
	for g in GetDroneDock().DockedDrones:
		g.ToggleRadar()

func SetCurrentPort(Port : MapSpot):
	super(Port)
	var dr = GetDroneDock().DockedDrones
	for g in dr:
		g.SetCurrentPort(Port)
func RemovePort():
	super()
	var dr = GetDroneDock().DockedDrones
	for g in dr:
		g.RemovePort()
func Damage(amm : float) -> void:
	ShipData.GetInstance().GetStat("HULL").CurrentVelue -= amm
	if (IsDead()):
		MapPointerManager.GetInstance().RemoveShip(self)
		queue_free()
func IsDead() -> bool:
	return ShipData.GetInstance().GetStat("HULL").CurrentVelue <= 0
func UpdateAltitude(NewAlt : float) -> void:
	super(NewAlt)
	for g in GetDroneDock().DockedDrones:
		g.UpdateAltitude(NewAlt)
func Steer(Rotation : float) -> void:
	super(Rotation)
	for g in GetDroneDock().DockedDrones:
		g.Steer(Rotation)
func UpdateFuelRange(fuel : float, fuel_ef : float):
	var FuelRangeIndicator = $Fuel_Range
	var FuelMat = FuelRangeIndicator.material as ShaderMaterial
	# Base distance for the main ship
	var fleetsize = 1 + GetDroneDock().DockedDrones.size()
	var total_fuel = fuel
	var inverse_ef_sum = 1.0 / fuel_ef
	
	# Group ships fuel and efficiency calculations
	for g in GetDroneDock().DockedDrones:
		var ship_fuel = g.Cpt.GetStat("FUEL_TANK").CurrentVelue
		var ship_efficiency = g.Cpt.GetStat("FUEL_EFFICIENCY").GetStat()
		total_fuel += ship_fuel
		inverse_ef_sum += 1.0 / ship_efficiency
		#if (minfuelef > ship_efficiency):
			#minfuelef = ship_efficiency
	var effective_efficiency = fleetsize / inverse_ef_sum
	var total_distance = total_fuel * 10 * inverse_ef_sum
	# Calculate average efficiency for the group
	#var fleetsize = 1 + GetDroneDock().DockedDrones.size()
	var distall = (total_fuel * 10 * effective_efficiency) / fleetsize
	var tw = create_tween()

	tw.tween_method(SetFuelShaderRange, FuelMat.get_shader_parameter("scale_factor"), distall / 10000, 0.5)
func GetElintLevel(Dist : float) -> int:
	var Lvl = 1
	if (Dist < ShipData.GetInstance().GetStat("ELINT").GetStat() * 0.3):
		Lvl = 3
	else : if(Dist < ShipData.GetInstance().GetStat("ELINT").GetStat() * 0.6):
		Lvl = 2
	else :
		Lvl = 1
	return Lvl
func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = ShipType.GetStat("HULL").StatBuff
	stats.FirePower = 1
	stats.ShipIcon = ShipType.TopIcon
	stats.CaptainIcon = CaptainIcon
	stats.Name = "Player"
	return stats
func GetShipName() -> String:
	return "Player"
func _on_elint_area_entered(area: Area2D) -> void:
	if (area.get_parent() is Drone):
		return
	super(area)
func _on_elint_area_exited(area: Area2D) -> void:
	if (area.get_parent() is Drone):
		return
	super(area)
