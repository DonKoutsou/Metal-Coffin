extends MapShip

class_name PlayerDrivenShip

@export var AccelerationAudio : AudioStreamPlayer2D
@export var L : PointLight2D

@export var MissileD : MissileDock
var CommingBack = false
var RegroupTarget : MapShip

var StoredSteer : float = 0.0

var TargetLocations : Array[Vector2]
var TargetShip : MapShip
var TargetShipPos : Vector2

func  _ready() -> void:
	super()
	WeatherManage.RegisterShip(self)

func _exit_tree() -> void:
	WeatherManage.UnregisterShip(self)

func Update(delta: float) -> void:
	ElintShape.UpdateElint(delta)
	RadarShape.EvaluateRadarrPoint(Altitude)
	
	for g in TrailLines:
		g.UpdateProjected(delta, Altitude / 10000.0)
	
	if (SimulationManager.IsPaused()):
		return

	RadarShape.EvaluateRadarTargets(Altitude)
	
	if (Docked):
		return
	
	UpdateShipWindManipulationModifier()
	_HandleLanding(delta)
	_HandleAutoPilot(delta)
		
	if (StoredSteer != 0):
		var SteertToAdd = min((delta), abs(StoredSteer)) * sign(StoredSteer)
		StoredSteer -= SteertToAdd
		ForceSteer(rotation + SteertToAdd)
	#HandleAcceleration
	if (AccelChanged):
		_HandleAccelerationSound()

	if (CurrentPort != null):
		_HandleRestock()
	
	if (Landed()):
		LastRecordedOffset = Vector2.ZERO
		return
	
	var CorrectionExtra : float = 0.0
	var offset : Vector2
	if (ShipContoller.AutoCorrectWind):
		offset = GetShipSpeedVec()
		
		var Windage = Cpt.GetStatFinalValue(STAT_CONST.STATS.WINDAGE) * 0.0001
		var SideWindage = Windage * 0.1
		
		if (offset.length() < WindVector.length() * Windage):
			CorrectionExtra = (WindVector.length() * Windage) - offset.length()
			
		var sidecorrection = abs(offset.rotated(PI/2).normalized().dot(WindVector.normalized())) * WindVector.length() * SideWindage
		
		var frontcorrection = offset.normalized().dot(WindVector.normalized()) * WindVector.length() * Windage
		
		offset -= (offset.normalized() * sidecorrection) - (offset.normalized() * frontcorrection)
		#print("Head wind penalty : {0} - Side wind penalty : {1}".format([snapped(frontcorrection * 10, 0.1), snapped(sidecorrection * 100, 0.1)]))
	else:
		offset = GetShipAffectedSpeedVec()
	
	var ShipWeight = Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	var ShipEfficiency = (Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) / pow(ShipWeight, 0.5)) * 10
	var FuelConsumtion = (Acceleration.position.x + CorrectionExtra) / ShipEfficiency

	FuelConsumtion *= SimulationManager.SimSpeed()
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
	
	for g : PlayerDrivenShip in GetSquad():
		var Cap = g.Cpt as Captain
		
		var droneWeight = Cap.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
		var droneEfficiency = (Cap.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) / pow(droneWeight, 0.5)) * 10
		var droneCorrectionExtra : float = 0.0
		if (CorrectionExtra > 0):
			var Windage = Cap.GetStatFinalValue(STAT_CONST.STATS.WINDAGE) * 0.0001
			droneCorrectionExtra = (g.WindVector.length() * Windage) - offset.length()
		
		var DroneFuelConsumtion = (Acceleration.position.x + droneCorrectionExtra) / droneEfficiency
		
		if (StormValue > 0.9):
			DroneFuelConsumtion *= 1.3

		DroneFuelConsumtion *= SimulationManager.SimSpeed()
		
		if (Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > DroneFuelConsumtion):
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK,DroneFuelConsumtion)
		else : if (Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) >= DroneFuelConsumtion):
			Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, DroneFuelConsumtion)
		else: if (GetDroneDock().DronesHaveFuel(DroneFuelConsumtion)):
			GetDroneDock().SyphonFuelFromDrones(DroneFuelConsumtion)
		else:
			HaltShip()
			PopUpManager.GetInstance().DoFadeNotif("Your ships have run out of fuel.")
	
	LastRecordedOffset = offset
	global_position += offset * SimulationManager.SimSpeed()

func PartChanged(It : ShipPart) -> void:
	for g in It.Upgrades:
		if (g.UpgradeName == STAT_CONST.STATS.VISUAL_RANGE):
			RadarShape.UpdateVizRange()
		else : if (g.UpgradeName == STAT_CONST.STATS.ELINT):
			ElintShape.UpdateELINTTRange()
		else : if (g.UpgradeName == STAT_CONST.STATS.AEROSONAR_RANGE):
			SonarShape.UpdateSonarRange()

func IntersectShip(Target : MapShip) -> Vector2:
	var plship = Target

	var ship_position = plship.position # Get the current position and velocity of the ship
	var ship_velocity = plship.LastRecordedOffset

	var time_to_interception = (position.distance_to(ship_position)) / (max(GetShipSpeed(), 0.001) / 360) # Predict where the ship will be in a future time `t`
	var predicted_position = ship_position + ship_velocity * time_to_interception # Calculate the predicted interception point

	return predicted_position

func GetBiggestRadarCicle() -> PackedVector2Array:
	var Biggest : float = RadarShape.CurrentVisualRange
	var Circle : PackedVector2Array = RadarShape.GetShipRadarLine()
	for g : PlayerDrivenShip in GetSquad():
		if g.RadarShape.CurrentVisualRange > Biggest:
			Biggest = g.RadarShape.CurrentVisualRange
			Circle = g.RadarShape.GetShipRadarLine()
	return Circle

func GetBiggestVisRange() -> float:
	var Biggest : float = RadarShape.CurrentVisualRange
	for g : PlayerDrivenShip in GetSquad():
		if g.RadarShape.CurrentVisualRange > Biggest:
			Biggest = g.RadarShape.CurrentVisualRange
	return Biggest
#------------------------------------------------------------
#Autopilot stuff

func _HandleAutoPilot(delta : float) -> void:
	if (TargetShip != null):
		TargetShipPos = IntersectShip(TargetShip)
		if (TargetShipPos.distance_to(global_position) < 5):
			ClearTargetShip()
			HaltShip()
		var directiontoDestination = (TargetShipPos - global_position).normalized().angle()
		if (rotation != directiontoDestination):
			var newrot = lerp_angle(rotation, directiontoDestination, delta)
			ForceSteer(newrot)
			SteerForced.emit(newrot)
			
	else: if (TargetLocations.size() > 0):
		var NextLoc = TargetLocations[0]
		if (NextLoc.distance_to(global_position) < 5):
			TargetLocations.remove_at(0)
			if (TargetLocations.size() == 0):
				HaltShip()
		
		var directiontoDestination = (NextLoc - global_position).normalized().angle()
		if (rotation != directiontoDestination):
			var newrot = lerp_angle(rotation, directiontoDestination, delta)
			ForceSteer(newrot)
			SteerForced.emit(newrot)
	if (CommingBack):
		updatedronecourse()

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
	var time_to_interception = (position.distance_to(ship_position)) / (GetShipSpeed() / 360)

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception
	ShipLookAt(predicted_position)

func SetTargetLocation(pos : Vector2) -> void:
	if (CommingBack):
		return
	ClearTargetShip()
	AccelerationChanged(GetShipMaxSpeed(), true)
	TargetLocations.clear()
	TargetLocations.append(pos)

func AddTargetLocation(pos : Vector2) -> void:
	if (CommingBack):
		return
	AccelerationChanged(GetShipMaxSpeed(), true)
	TargetLocations.append(pos)

func AddTargetShip(Target : MapShip) -> void:
	if (CommingBack):
		return
	AccelerationChanged(GetShipMaxSpeed(), true)
	TargetLocations.clear()
	TargetShip = Target
	Target.OnShipDestroyed.connect(TargetShipDestroyed)

func ClearTargetShip() -> void:
	if (TargetShip != null):
		TargetShip.OnShipDestroyed.disconnect(TargetShipDestroyed)
	TargetShip = null
	TargetShipPos = Vector2.ZERO

func TargetShipDestroyed(Sh : MapShip) -> void:
	TargetLocations.append(TargetShip.global_position)
	ClearTargetShip()

#------------------------------------------------------------

func Steer(Rotation : float) -> void:
	StoredSteer = wrap(StoredSteer + (Rotation / 50), -PI, PI)
	#StoredSteer = wrap(StoredSteer, -PI, PI)
	var Mat = ShipSprite.material as ShaderMaterial
	Mat.set_shader_parameter("sprite_rotation", ShipSprite.global_rotation)

	SteerForced.emit(rotation + StoredSteer)

	for g in GetSquad():
		g.ForceSteer(rotation)
	if (TargetLocations.size() > 0):
		TargetLocations.clear()
		PopUpManager.GetInstance().DoFadeNotif("Planned Course Aborted\nManual Control Engaged")
	if (TargetShip != null):
		ClearTargetShip()
		PopUpManager.GetInstance().DoFadeNotif("Planned Course Aborted\nManual Control Engaged")

func _HandleAccelerationSound() -> void:
	var Audioween = create_tween()
	Audioween.tween_property(AccelerationAudio, "pitch_scale", lerp(0.1, 1.0, GetShipSpeed() / GetShipMaxSpeed()), 2)
	if (!AccelerationAudio.playing):
		AccelerationAudio.play()
	AccelChanged = false

func _HandleRestock() -> void:
	if(!Landed()):
		ShipDockActions.emit("Refueling", false, 0)
		ShipDockActions.emit("Repairing", false, 0)
		ShipDockActions.emit("Upgrading", false, 0)
		return
	Refuel()
	Repair()
	
	var inv = Cpt.GetCharacterInventory()
	if (inv != null and inv._ItemBeingUpgraded != null):
		ShipDockActions.emit("Upgrading", true, roundi(inv.GetUpgradeTimeLeft()))
	else:
		ShipDockActions.emit("Upgrading", false, 0)

#--------------------------------------------------------------

func UpdateLight(LightAmm : float, Viz : float) -> void:
	L.color = Color(1,1,1) * LightAmm
	L.texture_scale = Viz

func ToggleLight(t : bool) -> void:
	$PointLight2D.visible = t
