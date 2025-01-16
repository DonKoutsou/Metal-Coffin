extends MapShip

class_name Drone





signal DroneReturning

func  _ready() -> void:
	super()
	
	UpdateVizRange(Cpt.GetStatFinalValue("VIZ_RANGE"))
	UpdateELINTTRange(Cpt.GetStatFinalValue("ELINT"))
	Paused = SimulationManager.IsPaused()


func _exit_tree() -> void:
	MapPointerManager.GetInstance().RemoveShip(self)

func Steer(Rotation : float) -> void:
	if (CommingBack):
		return
	super(Rotation)
	for g in GetDroneDock().DockedDrones:
		g.Steer(Rotation)

func AccelerationChanged(value: float) -> void:
	if (CommingBack):
		return
	super(value)

func Damage(amm : float) -> void:
	Cpt.GetStat("HULL").CurrentVelue -= amm
	super(amm)
func IsDead() -> bool:
	return Cpt.GetStat("HULL").CurrentVelue <= 0
	
func EnableDrone():
	#set_physics_process(true)
	if (Altitude != 10000):
		if (Landing):
			LandingCanceled.emit()
			Landing = false
		TakeoffStarted.emit()
		TakingOff = true
	$AudioStreamPlayer2D.play()
	GetShipAcelerationNode().position.x = Cpt.GetStatFinalValue("SPEED")
	#ToggleRadar()
	#$ShipBody/CollisionShape2D.set_deferred("disabled", false)
func DissableDrone():
	#GetShipIcon().rotation = 0.0
	rotation = 0
	$AudioStreamPlayer2D.stop()
	#set_physics_process(false)
	#ToggleRadar()
	#$ShipBody/CollisionShape2D.set_deferred("disabled", true)
func ReturnToBase():
	SetSpeed(GetShipMaxSpeed())
	#rotation = 0.0
	CommingBack = true
	DroneReturning.emit()
	#Docked = false


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
func _on_return_sound_trigger_area_entered(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip and CommingBack):
		var plship = area.get_parent() as PlayerShip
		plship.GetDroneDock().PlayReturnSound()
func _on_ship_body_area_entered(area: Area2D) -> void:
	if (Docked):
		return
	if (area.get_parent() is MapSpot and !CommingBack):
		var spot = area.get_parent() as MapSpot
		if (spot.CurrentlyVisiting):
			return
		if (!spot.Seen):
			spot.OnSpotSeenByDrone()
		spot.OnSpotVisitedByDrone()
	else : if (area.get_parent() == Command and CommingBack):
		var plship = area.get_parent() as MapShip
		plship.GetDroneDock().DockDrone(self, true)
		var MyDroneDock = GetDroneDock()
		for g in MyDroneDock.DockedDrones:
			MyDroneDock.UndockDrone(g, false)
			plship.GetDroneDock().DockDrone(g, false)
		for g in MyDroneDock.FlyingDrones:
			g.Command = plship
		CommingBack = false
func _on_elint_area_entered(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		return
	super(area)
func _on_elint_area_exited(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		return
	super(area)
func GetShipName() -> String:
	return Cpt.CaptainName
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
func GetShipSpeed() -> float:
	if (Docked):
		return Command.GetShipSpeed()
	return super()
func GetSaveData() -> DroneSaveData:
	var dat = DroneSaveData.new()
	dat.CommingBack = CommingBack
	dat.Cpt = Cpt
	dat.Docked = Docked
	dat.Pos = global_position
	dat.Rot = global_rotation
	dat.Fuel = Cpt.GetStat("FUEL_TANK").CurrentVelue
	for g in GetDroneDock().DockedDrones:
		dat.DockedDrones.append(g.GetSaveData())
	for g in GetDroneDock().FlyingDrones:
		dat.DockedDrones.append(g.GetSaveData())
	return dat
func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = Cpt.GetStat("HULL").CurrentVelue
	stats.FirePower = Cpt.GetStatFinalValue("FIREPOWER")
	stats.Speed = Cpt.GetStatFinalValue("SPEED")
	stats.ShipIcon = Cpt.ShipIcon
	stats.CaptainIcon = Cpt.CaptainPortrait
	stats.Name = Cpt.CaptainName
	return stats
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
func GetShipMaxSpeed() -> float:
	return Cpt.GetStatFinalValue("SPEED")
func IsFuelFull() -> bool:
	for g in GetDroneDock().DockedDrones:
		if (!g.IsFuelFull()):
			return false
	return Cpt.GetStat("FUEL_TANK").CurrentVelue == Cpt.GetStat("FUEL_TANK").GetStat()
