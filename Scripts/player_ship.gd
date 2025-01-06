extends MapShip

class_name PlayerShip

@export var CaptainIcon : Texture

#static var Instance : PlayerShip

func _ready() -> void:
	super()
	#Instance = self

func _physics_process(_delta: float) -> void:
	super(_delta)
	if (Paused):
		return
	
	var Dat = ShipData.GetInstance()
	#if ($Aceleration.position.x == 0):
	if (CurrentPort != null):
		#CurrentPort.OnSpotVisited()
		#if (CanRefuel):
		if (!Dat.IsResourceFull("FUEL") and CurrentPort.PlayerFuelReserves > 0):
			var maxfuelcap = Dat.GetStat("FUEL").GetStat()
			var currentfuel = Dat.GetStat("FUEL").GetCurrentValue()
			var timeleft = (min(maxfuelcap, currentfuel + CurrentPort.PlayerFuelReserves) - currentfuel) / 0.05 / 6
			ShipDockActions.emit("Refueling", true, roundi(timeleft))
			Dat.RefilResource("FUEL", 0.05 * SimulationSpeed)
			CurrentPort.PlayerFuelReserves -= 0.05 * SimulationSpeed
		else:
			ShipDockActions.emit("Refueling", false, 0)
		#if (CanRepair):
		if (!Dat.IsResourceFull("HULL") and CurrentPort.PlayerRepairReserves):
			var timeleft = ((Dat.GetStat("HULL").GetStat() - Dat.GetStat("HULL").GetCurrentValue()) / 0.05 / 6)
			ShipDockActions.emit("Repairing", true, roundi(timeleft))
			Dat.RefilResource("HULL", 0.05 * SimulationSpeed)
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

	var FuelConsumtion = ($Aceleration.position.x / 10 / ShipData.GetInstance().GetStat("FUEL_EFFICIENCY").GetStat()) * SimulationSpeed
	
	#Consume fuel on shif if enough
	if (Dat.GetStat("FUEL").GetCurrentValue() >= FuelConsumtion):
		Dat.ConsumeResource("FUEL", FuelConsumtion)
	# If not enough on ship syphoon some from drones in dock
	else: if (GetDroneDock().DronesHaveFuel(FuelConsumtion)):
		GetDroneDock().SyphonFuelFromDrones(FuelConsumtion)
		#SetFuelShaderRange(GetFuelRange())
	else:
		HaltShip()
		PopUpManager.GetInstance().DoFadeNotif("You have run out of fuel.")
		return
	#TODO fix drones not being able to syphon gas, once at 0 all fleet is not able to move
	for g in GetDroneDock().DockedDrones:
		var dronefuel = ($Aceleration.position.x / 10 / g.Cpt.GetStat("FUEL_EFFICIENCY").GetStat()) * SimulationSpeed
		if (g.Cpt.GetStat("FUEL_TANK").CurrentVelue > dronefuel):
			g.Cpt.GetStat("FUEL_TANK").CurrentVelue -= dronefuel
		else : if (Dat.GetStat("FUEL").GetCurrentValue() >= dronefuel):
			Dat.ConsumeResource("FUEL", dronefuel)
		else:
			HaltShip()
			PopUpManager.GetInstance().DoFadeNotif("You have run out of fuel.")
	
	var offset = GetShipSpeedVec()
	global_position += offset * SimulationSpeed
	#for g in SimulationSpeed:
		#global_position = $Aceleration.global_position

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
	super(amm)
		
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

func GetFuelRange() -> float:
	var fuel = ShipData.GetInstance().GetStat("FUEL").GetCurrentValue()
	var fuel_ef = ShipData.GetInstance().GetStat("FUEL_EFFICIENCY").GetStat()
	var fleetsize = 1 + GetDroneDock().DockedDrones.size()
	var total_fuel = fuel
	var inverse_ef_sum = 1.0 / fuel_ef
	
	# Group ships fuel and efficiency calculations
	for g in GetDroneDock().DockedDrones:
		var ship_fuel = g.Cpt.GetStat("FUEL_TANK").CurrentVelue
		var ship_efficiency = g.Cpt.GetStat("FUEL_EFFICIENCY").GetStat()
		total_fuel += ship_fuel
		inverse_ef_sum += 1.0 / ship_efficiency

	var effective_efficiency = fleetsize / inverse_ef_sum
	# Calculate average efficiency for the group
	return (total_fuel * 10 * effective_efficiency) / fleetsize
func GetElintLevel(Dist : float) -> int:
	var Lvl = 1
	if (Dist < ShipData.GetInstance().GetStat("ELINT").GetStat() * 0.3):
		Lvl = 3
	else : if(Dist < ShipData.GetInstance().GetStat("ELINT").GetStat() * 0.6):
		Lvl = 2
	else : if(Dist < ShipData.GetInstance().GetStat("ELINT").GetStat()):
		Lvl = 1
	else :
		Lvl = 0
	return Lvl
func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = ShipData.GetInstance().GetStat("HULL").GetCurrentValue()
	stats.Speed = GetShipMaxSpeed()
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
