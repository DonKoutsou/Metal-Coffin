extends MapShip

class_name PlayerShip

#static var Instance : PlayerShip

func _ready() -> void:
	super()
	#Instance = self

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
	Cpt.GetStat("HULL").CurrentVelue -= amm
	super(amm)
		
func IsDead() -> bool:
	return Cpt.GetStat("HULL").CurrentVelue <= 0
	
func UpdateAltitude(NewAlt : float) -> void:
	super(NewAlt)
	for g in GetDroneDock().DockedDrones:
		g.UpdateAltitude(NewAlt)
		
func Steer(Rotation : float) -> void:
	super(Rotation)
	for g in GetDroneDock().DockedDrones:
		g.Steer(Rotation)

func GetFuelRange() -> float:
	var fuel = Cpt.GetStat("FUEL_TANK").GetCurrentValue()
	var fuel_ef = Cpt.GetStat("FUEL_EFFICIENCY").GetStat()
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
	if (Dist < Cpt.GetStat("ELINT").GetStat() * 0.3):
		Lvl = 3
	else : if(Dist < Cpt.GetStat("ELINT").GetStat() * 0.6):
		Lvl = 2
	else : if(Dist < Cpt.GetStat("ELINT").GetStat()):
		Lvl = 1
	else :
		Lvl = 0
	return Lvl
func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = Cpt.GetStat("HULL").GetCurrentValue()
	stats.Speed = GetShipMaxSpeed()
	stats.FirePower = Cpt.GetStat("FIREPOWER").GetStat()
	stats.ShipIcon = ShipType.TopIcon
	stats.CaptainIcon = Cpt.CaptainPortrait
	stats.Name = GetShipName()
	return stats
func GetShipName() -> String:
	return "Flagship"
func _on_elint_area_entered(area: Area2D) -> void:
	if (area.get_parent() is Drone):
		return
	super(area)
func _on_elint_area_exited(area: Area2D) -> void:
	if (area.get_parent() is Drone):
		return
	super(area)
