extends MapShip

class_name PlayerDrivenShip

@export var AccelerationAudio : AudioStreamPlayer2D

var CommingBack = false
var RegroupTarget : MapShip

func  _ready() -> void:
	super()
	Paused = SimulationManager.IsPaused()

func UpdateCameraZoom(NewZoom : float) -> void:
	CamZoom = NewZoom
	queue_redraw()

func updatedronecourse():
	var plship = RegroupTarget
	# Get the current position and velocity of the ship
	
	var ship_position = plship.position
	
	var Distance = global_position.distance_to(ship_position)
	
	if (Distance < 30):
		plship.GetDroneDock().DockDrone(self, true)
		var MyDroneDock = GetDroneDock()
		for g in MyDroneDock.DockedDrones:
			MyDroneDock.UndockDrone(g)
			plship.GetDroneDock().DockDrone(g, false)
		for g in MyDroneDock.Captives:
			MyDroneDock.UndockCaptive(g)
			plship.GetDroneDock().DockCaptive(g)
		#for g in MyDroneDock.FlyingDrones:
			#g.Command = plship
		
		CommingBack = false
		return
	
	var ship_velocity = plship.GetShipSpeedVec()

	# Predict where the ship will be in a future time `t`
	var time_to_interception = (position.distance_to(ship_position)) / (GetShipSpeed() / 360)

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception
	ShipLookAt(predicted_position)

func fuel_used_for_distance(dist: float, FuelNow: float, FuelEff: float, Weight: float) -> float:
	var eff_eff = FuelEff - (Weight / 40.0)
	var A = pow(FuelNow * eff_eff, 0.55)
	var arg = A - dist/50.0
	if arg <= 0:
		return FuelNow # not enough fuel: use what's left 
	var FuelAfter = pow(arg, 1.0/0.55) / eff_eff
	return FuelNow - FuelAfter

func _physics_process(delta: float) -> void:
	
	UpdateElint(delta)
	queue_redraw()
	
	for g in TrailLines:
		g.UpdateProjected(delta, Altitude / 10000.0)
	
	if (CurrentPort != null):
		_HandleRestock()
	
	if (Paused):
		return
	
	var SimulationSpeed = SimulationManager.SimSpeed()
	
	_HandleLanding(SimulationSpeed)
	
	#HandleAcceleration
	if (AccelChanged):
		_HandleAccelerationSound()

	if (Docked or GetShipSpeedVec() == Vector2.ZERO):
		return
	
	if (CommingBack):
		updatedronecourse()
		
	var ShipWeight = Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	var ShipEfficiency = Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
	var f = fuel_used_for_distance(Acceleration.position.x, Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK), ShipEfficiency, ShipWeight)
	var FuelConsumtion = f * SimulationSpeed
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

	
	
	for g in GetDroneDock().GetDockedShips():
		var Cap = g.Cpt as Captain
		
		var DroneWeight = Cap.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
		var DroneEfficiency = Cap.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) - DroneWeight / 40
		
		var DroneFuelConsumtion = pow(Acceleration.position.x / 50, 1 / 0.55) / (DroneEfficiency - (DroneWeight / 40)) * SimulationSpeed
		
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
	if (Altitude == 0 and inv != null and inv._ItemBeingUpgraded != null):
		ShipDockActions.emit("Upgrading", true, roundi(inv.GetUpgradeTimeLeft()))
	else:
		ShipDockActions.emit("Upgrading", false, 0)

func _HandleLanding(SimulationSpeed : float) -> void:
	if (Landing):
		UpdateAltitude(max(0, Altitude - (60 * SimulationSpeed)))
		if (Altitude <= 0):
			Altitude = 0
			LandingEnded.emit(self)
			Landing = false
	if (TakingOff):
		UpdateAltitude(min(10000, Altitude + (60 * SimulationSpeed)))
		if (Altitude >= 10000):
			Altitude = 10000
			TakeoffEnded.emit(self)
			TakingOff = false
	if (MatchingAltitude):
		UpdateAltitude(clamp(move_toward(Altitude, Command.Altitude, 60 * SimulationSpeed), 0, 10000))
		if (Altitude == Command.Altitude):
			MatchingAltitudeEnded.emit(self)
			MatchingAltitude = false

func _UpdateShipIcon(Tex : Texture2D) -> void:
	super(Tex)
	

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

func ToggleLight(t : bool) -> void:
	$PointLight2D.visible = t
