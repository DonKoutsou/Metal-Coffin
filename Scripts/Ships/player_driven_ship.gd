extends MapShip

class_name PlayerDrivenShip

@export var AccelerationAudio : AudioStreamPlayer2D
@export var L : PointLight2D
@export var SonalVisual : ColorRect
@export var SonarShape : Area2D

var CommingBack = false
var RegroupTarget : MapShip

var StoredSteer : float = 0.0

var TargetLocations : Array[Vector2]

var SonarTargets : Array[Node2D]

func  _ready() -> void:
	super()
	SonarShape.connect("area_entered", BodyEnteredSonar)
	SonarShape.connect("area_exited", BodyLeftSonar)
	
	Paused = SimulationManager.IsPaused()
	WeatherManage.RegisterShip(self)
	#call_deferred("_postready")

func PartChanged(It : ShipPart) -> void:
	for g in It.Upgrades:
		if (g.UpgradeName == STAT_CONST.STATS.VISUAL_RANGE):
			UpdateVizRange(Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE))
		else : if (g.UpgradeName == STAT_CONST.STATS.ELINT):
			UpdateELINTTRange(Cpt.GetStatFinalValue(STAT_CONST.STATS.ELINT))
		else : if (g.UpgradeName == STAT_CONST.STATS.AEROSONAR_RANGE):
			UpdateELINTTRange(Cpt.GetStatFinalValue(STAT_CONST.STATS.AEROSONAR_RANGE))
			
func UpdateELINTTRange(rang : float):
	var SonarCollisionShape = SonarShape.get_node("CollisionShape2D")
	#scalling collision
	(SonarCollisionShape.shape as CircleShape2D).radius = rang

func ToggleSonarVisual(t : bool) -> void:
	SonalVisual.visible = t

func SetSonarDirection(Dir : float) -> void:
	SonalVisual.rotation = Dir - global_rotation

func BodyEnteredSonar(Body : Area2D) -> void:
	var Parent = Body.get_parent()
	if (Parent is MapShip or Parent is Missile):
		#ShipEnteredSonar.emit(Body.get_parent())
		SonarTargets.append(Parent)

func BodyLeftSonar(Body : Area2D) -> void:
	var Parent = Body.get_parent()
	if (Parent is MapShip or Parent is Missile):
		#ShipLeftSonar.emit(Body.get_parent())
		SonarTargets.erase(Parent)

func _exit_tree() -> void:
	WeatherManage.UnregisterShip(self)

#func _postready() -> void:
	#InventoryManager.GetInstance().AddCharacter(Cpt)

func _draw() -> void:
	super()
	
	#for g in TargetLocations.size():
		#var pos = to_local(TargetLocations[g])
		#if (g > 0):
			#draw_line(to_local(TargetLocations[g - 1]), pos, Color("ffc315"), 1 / CamZoom)
		#else:
			#draw_line(Vector2.ZERO, pos, Color("ffc315"), 1 / CamZoom)
		

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
	
	#NEEDS WIND
	var ship_velocity = plship.GetShipSpeedVec()

	# Predict where the ship will be in a future time `t`
	var time_to_interception = (position.distance_to(ship_position)) / (GetAffectedShipSpeed() / 360)

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

func GetAffectedShipSpeed() -> float:
	if (Command != null):
		return Command.GetAffectedShipSpeed()
	var WindVel = Vector2.RIGHT.rotated(rotation).dot(WeatherManage.WindDirection) * 0.1
	return (Acceleration.position.x * 360) * (1 + WindVel)

func GetShipSpeedVec() -> Vector2:
	var WindVel = Vector2.RIGHT.rotated(rotation).dot(WeatherManage.WindDirection) * 0.1
	return (Acceleration.global_position - global_position) * (1 + WindVel)

func SetTargetLocation(pos : Vector2) -> void:
	if (CommingBack):
		return
	AccelerationChanged(GetShipMaxSpeed())
	TargetLocations.clear()
	TargetLocations.append(pos)

func AddTargetLocation(pos : Vector2) -> void:
	if (CommingBack):
		return
	AccelerationChanged(GetShipMaxSpeed())
	TargetLocations.append(pos)

func Steer(Rotation : float) -> void:
	StoredSteer += Rotation / 50
	StoredSteer = wrap(StoredSteer, -PI, PI)
	var Mat = ShipSprite.material as ShaderMaterial
	Mat.set_shader_parameter("sprite_rotation", ShipSprite.global_rotation)

	for g in GetDroneDock().GetDockedShips():
		g.ForceSteer(rotation)
	if (TargetLocations.size() > 0):
		TargetLocations.clear()
		PopUpManager.GetInstance().DoFadeNotif("Planned Course Aborted\nManual Control Engaged")

func _physics_process(delta: float) -> void:
	
	UpdateElint(delta)
	queue_redraw()
	
	var SimulationSpeed = SimulationManager.SimSpeed()
	
	var traildelta = delta
	if (Paused): 
		traildelta = 0
	
	for g in TrailLines:
		g.UpdateProjected(traildelta * SimulationSpeed, Altitude / 10000.0)
	
	if (CurrentPort != null):
		_HandleRestock()
	
	if (Paused):
		return

	_HandleLanding(SimulationSpeed)
	
	if (TargetLocations.size() > 0):
		var NextLoc = TargetLocations[0]
		if (NextLoc.distance_to(global_position) < 5):
			TargetLocations.remove_at(0)
			if (TargetLocations.size() == 0):
				AccelerationChanged(0)
		
		var directiontoDestination = (NextLoc - global_position).normalized().angle()
		if (rotation != directiontoDestination):
			ForceSteer(lerp_angle(rotation, directiontoDestination, delta * SimulationSpeed))
	
	if (StoredSteer != 0):
		var SteertToAdd = min((delta * SimulationSpeed), abs(StoredSteer)) * sign(StoredSteer)
		StoredSteer -= SteertToAdd
		ForceSteer(rotation + SteertToAdd)
	#HandleAcceleration
	if (AccelChanged):
		_HandleAccelerationSound()

	if (Docked):
		return

	if (GetShipSpeedVec() == Vector2.ZERO):
		return
	
	if (CommingBack):
		updatedronecourse()
		
	var ShipWeight = Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	var ShipEfficiency = (Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) / pow(ShipWeight, 0.5)) * 10
	#var f = Acceleration.position.x / ShipEfficiency * SimulationSpeed
	var FuelConsumtion = Acceleration.position.x / ShipEfficiency
	
	#Apply a small penalty durring storms
	if (StormValue > 0.9):
		FuelConsumtion *= 1.3
	#Apply wind buff debuff
	var WindVel = Vector2.RIGHT.rotated(rotation).dot(WeatherManage.WindDirection)
	FuelConsumtion *= 1 - WindVel * 0.3
	
	FuelConsumtion *= SimulationSpeed
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
		var DroneEfficiency = (Cap.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) / pow(DroneWeight, 0.5)) * 10
		
		var DroneFuelConsumtion = Acceleration.position.x / DroneEfficiency * SimulationSpeed
		if (StormValue > 0.9):
			DroneFuelConsumtion *= 1.05
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

func UpdateLight(LightAmm : float, Viz : float) -> void:
	L.color = Color(1,1,1) * LightAmm
	L.texture_scale = Viz

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
