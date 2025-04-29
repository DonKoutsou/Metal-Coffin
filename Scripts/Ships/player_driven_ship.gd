extends MapShip

class_name PlayerDrivenShip

@export var AccelerationAudio : AudioStreamPlayer2D

func  _ready() -> void:
	super()
	Paused = SimulationManager.IsPaused()

func UpdateCameraZoom(NewZoom : float) -> void:
	CamZoom = NewZoom
	queue_redraw()

func _physics_process(delta: float) -> void:
	
	UpdateElint(delta)
	queue_redraw()
	
	for g in TrailLines:
		g.Update(delta)
	
	if (Paused):
		return
	
	var SimulationSpeed = SimulationManager.SimSpeed()
	
	_HandleLanding(SimulationSpeed)
	
	#HandleAcceleration
	if (AccelChanged):
		_HandleAccelerationSound()

	if (CurrentPort != null):
		_HandleRestock()

	if (Docked or GetShipSpeedVec() == Vector2.ZERO):
		return

	var ShipWeight = Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	var ShipEfficiency = Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) - ShipWeight / 40
	var FuelConsumtion = Acceleration.position.x / ShipEfficiency * SimulationSpeed
	#Consume fuel on shif if enough
	if (Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) >= FuelConsumtion):
		Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, FuelConsumtion)
	# If not enough on ship syphoon some from drones in dock
	else: if (GetDroneDock().DronesHaveFuel(FuelConsumtion)):
		GetDroneDock().SyphonFuelFromDrones(FuelConsumtion)
		#SetFuelShaderRange(GetFuelRange())
	else:
		HaltShip()
		PopUpManager.GetInstance().DoFadeNotif("Your drone has run out of fuel.")
		return

	if (CommingBack):
		updatedronecourse()
	
	for g in GetDroneDock().GetDockedShips():
		var Cap = g.Cpt as Captain
		
		var DroneWeight = Cap.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
		var DroneEfficiency = Cap.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) - DroneWeight / 40
		
		var DroneFuelConsumtion = Acceleration.position.x / DroneEfficiency * SimulationSpeed
		
		if (Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > DroneFuelConsumtion):
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK,DroneFuelConsumtion)
		else : if (Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) >= DroneFuelConsumtion):
			Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, DroneFuelConsumtion)
		else: if (GetDroneDock().DronesHaveFuel(DroneFuelConsumtion)):
			GetDroneDock().SyphonFuelFromDrones(DroneFuelConsumtion)
		else:
			HaltShip()
			PopUpManager.GetInstance().DoFadeNotif("Your drones have run out of fuel.")

	var offset = GetShipSpeedVec()
	global_position += offset * SimulationSpeed

func _HandleAccelerationSound() -> void:
	var Audioween = create_tween()
	Audioween.tween_property(AccelerationAudio, "pitch_scale", lerp(0.1, 1.0, GetShipSpeed() / GetShipMaxSpeed()), 2)
	if (!AccelerationAudio.playing):
		AccelerationAudio.play()
	AccelChanged = false

func _HandleRestock() -> void:
	Refuel()
	Repair()
	
	var inv = Cpt.GetCharacterInventory()
	if (inv._ItemBeingUpgraded != null):
		ShipDockActions.emit("Upgrading", true, roundi(inv.GetUpgradeTimeLeft()))
	else:
		ShipDockActions.emit("Upgrading", false, 0)

func _HandleLanding(SimulationSpeed : float) -> void:
	if (Landing):
		UpdateAltitude(Altitude - (60 * SimulationSpeed))
		if (Altitude <= 0):
			Altitude = 0
			LandingEnded.emit(self)
			Landing = false
	if (TakingOff):
		UpdateAltitude(Altitude + (60 * SimulationSpeed))
		if (Altitude >= 10000):
			Altitude = 10000
			TakeoffEnded.emit(self)
			TakingOff = false

func BodyEnteredElint(Body: Area2D) -> void:
	if (Body.get_parent() is PlayerDrivenShip):
		return
	super(Body)
func BodyLeftElint(Body: Area2D) -> void:
	if (Body.get_parent() is PlayerShip):
		return
	super(Body)
func AccelerationChanged(value: float) -> void:
	super(value)
	
	for g in GetDroneDock().GetDockedShips():
		g.SetSpeed(max(0,min(value,1) * GetShipMaxSpeed()) )
		g.AccelChanged = true
