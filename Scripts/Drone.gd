extends MapShip

class_name Drone

@export var Cpt : Captain

var CommingBack = false
var Docked = true
var Fuel = 0

signal DroneReturning

func  _ready() -> void:
	super()
	#Set range of radar and alanyzer
	UpdateVizRange(Cpt.GetStatValue("RADAR_RANGE"))
	UpdateAnalyzerRange(Cpt.GetStatValue("ANALYZE_RANGE"))
	#MapPointerManager.GetInstance().AddShip(self, true)

func GetSaveData() -> DroneSaveData:
	var dat = DroneSaveData.new()
	dat.CommingBack = CommingBack
	dat.Cpt = Cpt
	dat.Fuel = Fuel
	dat.Docked = Docked
	dat.Pos = global_position
	dat.Rot = global_rotation
	return dat

func _exit_tree() -> void:
	MapPointerManager.GetInstance().RemoveShip(self)

func TogglePause(t : bool):
	Paused = t
	$AudioStreamPlayer2D.stream_paused = t
func ChangeSimulationSpeed(i : int):
	SimulationSpeed = i

func GetShipMaxSpeed() -> float:
	return Cpt.GetStatValue("SPEED")

func Steer(Rotation : float) -> void:
	if (CommingBack):
		return
	super(Rotation)

func AccelerationChanged(value: float) -> void:
	if (CommingBack):
		return
	super(value)

func EnableDrone():
	set_physics_process(true)
	$AudioStreamPlayer2D.play()
	GetShipAcelerationNode().position.x = Cpt.GetStatValue("SPEED")
	ToggleRadar()
	$ShipBody/CollisionShape2D.disabled = false
func DissableDrone():
	GetShipIconPivot().rotation = 0.0
	$AudioStreamPlayer2D.stop()
	set_physics_process(false)
	ToggleRadar()
	$ShipBody/CollisionShape2D.disabled = true
func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = Cpt.GetStatValue("HULL")
	stats.FirePower = Cpt.GetStatValue("FIREPOWER")
	stats.ShipIcon = Cpt.ShipIcon
	stats.CaptainIcon = Cpt.CaptainPortrait
	stats.Name = Cpt.CaptainName
	return stats

func _physics_process(_delta: float) -> void:
	if (Paused):
		return
	super(_delta)
	if ($Aceleration.position.x == 0):
		if (CurrentPort != null):
			#CurrentPort.OnSpotVisited()
			if (CanRefuel):
				if (Fuel < Cpt.GetStatValue("FUEL_TANK") and CurrentPort.PlayerFuelReserves > 0):
					var maxfuelcap = Cpt.GetStatValue("FUEL_TANK")
					var currentfuel = Fuel
					var timeleft = (min(maxfuelcap, currentfuel + CurrentPort.PlayerFuelReserves) - currentfuel) / 0.05 / 6
					ShipDockActions.emit("Refueling", true, roundi(timeleft))
					#ToggleShowRefuel("Refueling", true, roundi(timeleft))
					Fuel +=  0.05 * SimulationSpeed
					CurrentPort.PlayerFuelReserves -= 0.05 * SimulationSpeed
				else:
					ShipDockActions.emit("Refueling", false, 0)
					#ToggleShowRefuel("Refueling", false)
			if (CanRepair):
				if (Cpt.GetStat("HULL").GetBaseStat() < Cpt.GetStat("HULL").GetStat() and CurrentPort.PlayerRepairReserves):
					var timeleft = ((Cpt.GetStat("HULL").GetStat() - Cpt.GetStat("HULL").GetCurrentValue()) / 0.05 / 6)
					ShipDockActions.emit("Repairing", true, roundi(timeleft))
					#ToggleShowRefuel("Repairing", true, roundi(timeleft))
					Cpt.GetStat("HULL").RefilCurrentVelue(0.05 * SimulationSpeed)
				else:
					ShipDockActions.emit("Repairing", false, 0)
					#ToggleShowRefuel("Repairing", false)
			#if (CanUpgrade):
				#var inv = Inventory.GetInstance()
				#if (inv.UpgradedItem != null):
					##ToggleShowRefuel("Upgrading", true, roundi(inv.GetUpgradeTimeLeft()))
					#ShipDockActions.emit("Upgrading", true, roundi(inv.GetUpgradeTimeLeft()))
				#else:
					#ShipDockActions.emit("Upgrading", false, 0)
					##ToggleShowRefuel("Upgrading", false)
	if (Fuel <= 0):
		return
	if (CommingBack):
		updatedronecourse()
		
	for g in SimulationSpeed:
		var ftoconsume = $Aceleration.position.x / 10 / Cpt.GetStatValue("FUEL_EFFICIENCY")
		Fuel -= ftoconsume
		global_position = GetShipAcelerationNode().global_position
	UpdateFuelRange(Fuel, Cpt.GetStatValue("FUEL_EFFICIENCY"))
	#GetShipTrajecoryLine().set_point_position(1, Vector2(Fuel, 0))
	#if (Fuel <= global_position.distance_to(PlayerShip.GetInstance().global_position) / 10 / 2):
		#ReturnToBase()
		#$Line2D.visible = true

func ReturnToBase():
	$Aceleration.position.x = GetShipMaxSpeed()
	#rotation = 0.0
	CommingBack = true
	DroneReturning.emit()
	#Docked = false

func updatedronecourse():
	var plship = PlayerShip.GetInstance()
	# Get the current position and velocity of the ship
	
	var ship_position = plship.position
	var ship_velocity = plship.GetShipSpeedVec()

	# Predict where the ship will be in a future time `t`
	var time_to_interception = (position.distance_to(ship_position)) / GetShipSpeed()

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception
	look_at(predicted_position)
	
func GetShipSpeed() -> float:
	if (Docked):
		return PlayerShip.GetInstance().GetShipSpeed()
	return super()

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
	else : if (area.get_parent() is PlayerShip and CommingBack):
		var plship = area.get_parent() as PlayerShip
		plship.GetDroneDock().DockDrone(self, true)
		CommingBack = false
		
func GetShipBodyArea() -> Area2D:
	return $ShipBody
func GetShipRadarArea() -> Area2D:
	return $Radar
func GetShipAnalayzerArea() -> Area2D:
	return $Analyzer
func GetShipAcelerationNode() -> Node2D:
	return $Aceleration
func GetShipIconPivot() -> Node2D:
	return $ShipIconPivot
