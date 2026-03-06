extends Node2D
#/////////////////////////////////////////////////////////////
#███    ███  █████  ██████      ███████ ██   ██ ██ ██████  
#████  ████ ██   ██ ██   ██     ██      ██   ██ ██ ██   ██ 
#██ ████ ██ ███████ ██████      ███████ ███████ ██ ██████  
#██  ██  ██ ██   ██ ██               ██ ██   ██ ██ ██      
#██      ██ ██   ██ ██          ███████ ██   ██ ██ ██      
#/////////////////////////////////////////////////////////////
#Main class where both enemies in the map and player controlled ships inherit from.
#Base functionality exists here, access to radars/elint, captain of ship etc...
#Player controlled ships are controlled from Ship controller existing as child of WORLD, enemies are controlled from Commander
#/////////////////////////////////////////////////////////////
class_name MapShip

@export var LowStatsToNotifyAbout : Array[String]
@export var Cpt : Captain

@export var TrailLines : Array[TrailLine]
@export_group("Nodes")
@export var RadarShape : Radar
@export var ElintShape : Elint
@export var SonarShape : Sonar
@export var BodyShape : Area2D
@export var DroneDok : Node2D
@export var ShipSprite : Sprite2D
@export var Acceleration : Node2D	
#var SimulationSpeed : float = 1
var CurrentPort : MapSpot

var Altitude : float = 10000
var TargetAltitude : float = 10000

var CurrentLandAltitude : float = 0
var Command : MapShip

var ShowFuelRange = true
var Docked = false

signal ShipDeparted(DepartedFrom : MapSpot)
signal ShipDockActions(Stats : String, t : bool, timel : float)
signal StatLow(StatName : String)
signal OnShipDamaged(Amm : float, ShowVisuals : bool)
signal OnShipDestroyed(Sh : MapShip)

signal AltitudeChanged(NewAlt : float)
signal TargetAltitudeChanged(NewAlt : float)
signal AChanged(NewAccel : float)
signal AForced(NewAccel : float)
signal SteerChanged(NewSteer : float)
signal SteerForced(NewSteer : float)
signal Teleported

var LastRecordedOffset : Vector2

signal PortChanged()


var StormValue : float = 0
var WindVector : Vector2
var FuelWindEffect : float

func _ready() -> void:
	
	BodyShape.connect("area_entered", BodyEnteredBody)
	BodyShape.connect("area_exited", BodyLeftBody)
	Cpt.connect("ShipPartChanged", PartChanged)
	
	MapPointerManager.GetInstance().AddShip(self, true)

	#TODO probably a better way to do this
	Cpt.CaptainShip = self
	RadarShape.VisStat = Cpt._GetStat(STAT_CONST.STATS.VISUAL_RANGE)
	ElintShape.ElintStat = Cpt._GetStat(STAT_CONST.STATS.ELINT)
	if (SonarShape != null):
		SonarShape.SonarStat = Cpt._GetStat(STAT_CONST.STATS.AEROSONAR_RANGE)
	_UpdateShipIcon(Cpt.ShipIcon)
	for g in Cpt.CaptainStats:
		g.ForceMaxValue()

#Refuel logic
func Refuel() -> void:
	#Make sure that the ship is landed
	#Make sure that fuel tanks are not full
	#Make sure port has fuel
	#IsLanded = Altitude == 0
	var FuelIsFull = IsFuelFull()
	var TownHasFuel = CurrentPort.PlayerHasFuelReserves()

	if (!FuelIsFull and TownHasFuel):
		var SimulationSpeed = SimulationManager.SimSpeed()
		
		if (SimulationManager.IsPaused()):
			SimulationSpeed = 0

		var FuelPerTic = 0.05
		#Towns with fuel, refuel faster
		if (CurrentPort.HasFuel()):
			FuelPerTic = 0.1
		#Ammount to refill on the current tic
		var AmmountRefilled = FuelPerTic * SimulationSpeed
		
		var ShipsToRefuel : Array[MapShip] = [self]
		ShipsToRefuel.append_array(GetSquad())
		
		var BiggestTimeLeft : float
		
		for g in ShipsToRefuel:
			var Capt = g.Cpt
		
			var maxfuelcap = Capt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
			var currentfuel = Capt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
			var AmmountUntilFull = min(maxfuelcap, currentfuel + CurrentPort.PlayerFuelReserves) - currentfuel
			if (AmmountUntilFull == 0):
				continue
			var timeleft = AmmountUntilFull / FuelPerTic / 6
			if (timeleft > BiggestTimeLeft):
				BiggestTimeLeft = timeleft
			
			#Add fule to ship and remove from city
			Capt.RefillResource(STAT_CONST.STATS.FUEL_TANK, AmmountRefilled)
			CurrentPort.AddToFuelReserves(-AmmountRefilled)
		ShipDockActions.emit("Refueling", true, roundi(BiggestTimeLeft))
	else:
		
		ShipDockActions.emit("Refueling", false, 0)

func Repair() -> void:
	if (!Cpt.IsResourceFull(STAT_CONST.STATS.HULL) and Cpt.Repair_Parts > 0):
		var Simulationp = 0
		if (!SimulationManager.IsPaused()):
			Simulationp = 1
		var SimulationSpeed = SimulationManager.SimSpeed() * Simulationp
		var TimeMulti = 0.05
		
		if (CurrentPort.HasRepair()):
			TimeMulti = 0.25
		var timeleft = ((Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) - Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)) / TimeMulti / 6)
		ShipDockActions.emit("Repairing", true, roundi(timeleft))
		Cpt.RefillResource(STAT_CONST.STATS.HULL ,TimeMulti * SimulationSpeed)
		Cpt.Repair_Parts -= TimeMulti * SimulationSpeed
	else:
		ShipDockActions.emit("Repairing", false, 0)



#CALLED WHEN A SHIP PART IS REMOVED OR ADDED TO INVENTORY TO UPDATE VISUAL RANGE AND ELINT RANGE
func PartChanged(It : ShipPart) -> void:
	for g in It.Upgrades:
		if (g.UpgradeName == STAT_CONST.STATS.VISUAL_RANGE):
			RadarShape.UpdateVizRange()
		else : if (g.UpgradeName == STAT_CONST.STATS.ELINT):
			ElintShape.UpdateELINTTRange()
		#else : if (g.UpgradeName == STAT_CONST.STATS.AEROSONAR_RANGE):
			#UpdateELINTTRange(Cpt.GetStatFinalValue(STAT_CONST.STATS.ELINT))

func GetSonarTargets() -> Array[Node2D]:
	var Targets : Array[Node2D] = SonarShape.GetSonarTargets()
	for g : PlayerDrivenShip in GetSquad():
		Targets.append_array(g.SonarShape.GetSonarTargets())
	return Targets

func GetSonarTargetInfo() -> Array[SonarTargetInfo]:
	var Targets : Array[SonarTargetInfo] = SonarShape.GetSonarTargetInfo()
	for g : PlayerDrivenShip in GetSquad():
		Targets.append_array(g.SonarShape.GetSonarTargetInfo())
	return Targets

func GetClosestElint() -> Vector2:
	var closest : Vector2 = ElintShape.GetClosestElint()
	var closestdist = global_position.distance_squared_to(closest)
	for g:MapShip in GetSquad():
		var DroneClosest = g.ElintShape.GetClosestElint()
		var dist = global_position.distance_squared_to(DroneClosest)
		if(dist < closestdist):
			closest = DroneClosest
	return closest
	
func GetClosestElintLevel() -> int:
	var Newlvl = ElintShape.GetClosestElintLevel()
	for g:MapShip in GetSquad():
		Newlvl = max(Newlvl, g.ElintShape.GetClosestElintLevel())
	return Newlvl

func ToggleFuelRangeVisibility(t : bool) -> void:
	ShowFuelRange = t

func SetCurrentPort(Port : MapSpot):
	CurrentPort = Port
	Cpt.CurrentPort = Port.GetSpotName()
	for g in GetSquad():
		g.SetCurrentPort(Port)
	PortChanged.emit(0)
		
func SetSpeed(Spd : float) -> void:
	GetShipAcelerationNode().position.x = Spd / 360

func _HandleLanding(delta : float) -> void:
	if (GetShipSpeed() == 0):
		CurrentLandAltitude = TopographyMap.GetAltitudeAtGlobalPosition(global_position)
	else:
		CurrentLandAltitude = TopographyMap.GetAltitudeAtGlobalPosition(global_position) + 200
		
	var NewAltitude = clamp(TargetAltitude, CurrentLandAltitude, 10000)

	if (Altitude != NewAltitude):
		UpdateAltitude(move_toward(Altitude, NewAltitude, delta * 1000))

func RemovePort():
	ShipDeparted.emit(CurrentPort)
	CurrentPort = null
	InventoryManager.GetInstance().CancelUpgrades(Cpt)
	Cpt.CurrentPort = ""

	for g in GetSquad():
		g.RemovePort()
	PortChanged.emit(0)

func OnStatLow(StatName : String) -> void:
	if (!LowStatsToNotifyAbout.has(StatName)):
		return
	StatLow.emit(StatName)

var ParalaxMulti : float

func _UpdateShipIcon(Tex : Texture2D) -> void:
	ParalaxMulti = 2000 / Tex.get_size().x
	ShipSprite.texture = Tex
	UpdateAltitude(Altitude)
#///////////////////////////////////////////////
#███████ ██   ██ ██ ██████       ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ██ ███    ██  ██████  
#██      ██   ██ ██ ██   ██     ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██ ████   ██ ██       
#███████ ███████ ██ ██████      ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      ██ ██ ██  ██ ██   ███ 
#     ██ ██   ██ ██ ██          ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██ ██  ██ ██ ██    ██ 
#███████ ██   ██ ██ ██           ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ██ ██   ████  ██████ 

func HaltShip():
	AccelerationChanged(0, true)
	#AccelerationChanged(0)

var AccelChanged = false

func AccelerationChanged(value: float, forced : bool = false) -> void:
	if (value > 0):
		if (GetFuelRange() <= 0):
			HaltShip()
			PopUpManager.GetInstance().DoFadeNotif("You have run out of fuel.")
			return

	AccelChanged = true
	
	var NewSpeed = max(0,min(value,1) * GetShipMaxSpeed())
	
	SetSpeed(NewSpeed)
	if (forced):
		AForced.emit(NewSpeed)
	else:
		AChanged.emit(NewSpeed)
	
	for g in GetSquad():
		g.SetSpeed(max(0,min(value,1) * GetShipMaxSpeed()) )
		g.AccelChanged = true
	
func Steer(Rotation : float) -> void:
	rotation = wrap(rotation + (Rotation / 50), -PI, PI)
	
	var Mat = ShipSprite.material as ShaderMaterial
	Mat.set_shader_parameter("sprite_rotation", ShipSprite.global_rotation)

	for g in GetSquad():
		g.ForceSteer(rotation)

func ForceSteer(Rotation : float) -> void:
	rotation = wrap(Rotation, -PI, PI)

	#print("{0}'s new rotation is {1}".format([Cpt.GetCaptainName(), rotation]))
	var Mat = ShipSprite.material as ShaderMaterial
	Mat.set_shader_parameter("sprite_rotation", ShipSprite.global_rotation)
	for g in GetSquad():
		g.ForceSteer(rotation)
		
func ShipLookAt(pos : Vector2) -> void:
	if (is_equal_approx(global_position.angle_to_point(pos), global_rotation)):
		return
	look_at(pos)
	var Mat = ShipSprite.material as ShaderMaterial
	Mat.set_shader_parameter("sprite_rotation", ShipSprite.global_rotation)

	for g in GetSquad():
		g.ForceSteer(rotation)

func SetShipPosition(pos : Vector2) -> void:
	global_position = pos
	for g in TrailLines:
		g.Init()
	Teleported.emit()
#///////////////////////////////////////////////////
#██████   █████  ███    ███  █████   ██████  ██ ███    ██  ██████  
#██   ██ ██   ██ ████  ████ ██   ██ ██       ██ ████   ██ ██       
#██   ██ ███████ ██ ████ ██ ███████ ██   ███ ██ ██ ██  ██ ██   ███ 
#██   ██ ██   ██ ██  ██  ██ ██   ██ ██    ██ ██ ██  ██ ██ ██    ██ 
#██████  ██   ██ ██      ██ ██   ██  ██████  ██ ██   ████  ██████  

func Damage(amm : float, ShowVisuals : bool = true) -> void:
	OnShipDamaged.emit(amm, ShowVisuals)
	Cpt.ConsumeResource(STAT_CONST.STATS.HULL, amm)
	if (IsDead()):
		Kill()

func Kill() -> void:
	InventoryManager.GetInstance().OnCharacterRemoved(Cpt)
	MapPointerManager.GetInstance().RemoveShip(self)
	OnShipDestroyed.emit(self)
	queue_free()
	get_parent().remove_child(self)
	if (CurrentPort != null):
		CurrentPort.OnSpotDeparture(self)

func IsDead() -> bool:
	return Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL) <= 0

#///////////////////////////////////////////
#██       █████  ███    ██ ██████  ██ ███    ██  ██████  
#██      ██   ██ ████   ██ ██   ██ ██ ████   ██ ██       
#██      ███████ ██ ██  ██ ██   ██ ██ ██ ██  ██ ██   ███ 
#██      ██   ██ ██  ██ ██ ██   ██ ██ ██  ██ ██ ██    ██ 
#███████ ██   ██ ██   ████ ██████  ██ ██   ████  ██████  
#Only used by player controlled ships

#func StartLanding() -> void:
	#if (TakingOff):
		#TakeoffEnded.emit(null)
		#TakingOff = false
	#LandingStarted.emit()
	#Landing = true
	

func UpdateTargetAltitude(NewTarget : float) -> void:
	TargetAltitude = clamp(NewTarget, CurrentLandAltitude, 10000)
	TargetAltitudeChanged.emit(TargetAltitude)

func SetTargetAltitude(NewTarget : float) -> void:
	TargetAltitude = NewTarget

func Landed() -> bool:
	return Altitude == CurrentLandAltitude and !Moving()

func Moving() -> bool:
	return Acceleration.position.x > 0

func UpdateAltitude(NewAlt : float) -> void:
	Altitude = NewAlt
	AltitudeChanged.emit(NewAlt)
	#var S = lerp(0.05, 0.1, Altitude / 10000.0)
	#ShipSprite.scale = Vector2(lerp(0.05, 0.1, Altitude / 10000.0), lerp(0.05, 0.1, Altitude / 10000.0))
	
	var Mat = ShipSprite.material as ShaderMaterial
	Mat.set_shader_parameter("shadow_parallax_amount", lerp(0.0, ParalaxMulti, Altitude / 10000.0))
	Mat.set_shader_parameter("ShipSize", lerp(0.001, 0.008, Altitude / 10000.0))

	for g in GetSquad():
		g.TargetAltitude = TargetAltitude
		g.UpdateAltitude(NewAlt)

func GetShipParalaxPosition(CamPos : Vector2, Zoom : float) -> Vector2:
	var offset = (CamPos - global_position) * Zoom * lerp(0.0, 0.88, Altitude / 10000.0) * 0.05
	offset.x /= 1.65
	return global_position - offset





#//////////////////////////////////////////////////////////
#██████   █████  ██████   █████  ██████      ██ ███████ ██      ██ ███    ██ ████████ 
#██   ██ ██   ██ ██   ██ ██   ██ ██   ██    ██  ██      ██      ██ ████   ██    ██    
#██████  ███████ ██   ██ ███████ ██████    ██   █████   ██      ██ ██ ██  ██    ██    
#██   ██ ██   ██ ██   ██ ██   ██ ██   ██  ██    ██      ██      ██ ██  ██ ██    ██    
#██   ██ ██   ██ ██████  ██   ██ ██   ██ ██     ███████ ███████ ██ ██   ████    ██    

func ToggleRadar(t : bool):
	RadarShape.ToggleRadar(t)
	for g in GetSquad():
		g.ToggleRadar(t)
		
func ToggleElint(t : bool):
	ElintShape.ToggleElint(t)
	for g in GetSquad():
		g.ToggleElint(t)
	
#/////////////////////////////////////////////////////
#██████  ██   ██ ██    ██ ███████ ██  ██████ ███████     ███████ ██    ██ ███████ ███    ██ ████████ ███████ 
#██   ██ ██   ██  ██  ██  ██      ██ ██      ██          ██      ██    ██ ██      ████   ██    ██    ██      
#██████  ███████   ████   ███████ ██ ██      ███████     █████   ██    ██ █████   ██ ██  ██    ██    ███████ 
#██      ██   ██    ██         ██ ██ ██           ██     ██       ██  ██  ██      ██  ██ ██    ██         ██ 
#██      ██   ██    ██    ███████ ██  ██████ ███████     ███████   ████   ███████ ██   ████    ██    ███████ 


			
func BodyEnteredBody(Body : Area2D) -> void:
	if (Docked):
		return
	var Parent = Body.get_parent()
	if (Parent is MapSpot):
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.LANDING)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.LANDING)
			ActionTracker.QueueTutorial("Landing", "You have entrered the perimiter of a [color=#ffc315]Town[/color].\nTo visit the [color=#ffc315]town[/color]'s verdors and resuply you'll need to land your fleet.\nTo do so click the [color=#ffc315]Land Button[/color] to initiate the landing procedure or lower the [color=#ffc315]Altitude Lever[/color] all the way to the bottom. Once the landing is complete press the [color=#ffc315]Open Hatch[/color] button bellow the land button to visit the town.", [Map.UI_ELEMENT.LAND_BUTTON, Map.UI_ELEMENT.ELEVATION])
		SetCurrentPort(Parent)
		Parent.OnSpotAproached(self)
		for g in GetSquad():
			g.SetCurrentPort(Parent)
			Parent.OnSpotAproached(g)
	
func BodyLeftBody(Body : Area2D) -> void:
	if (Docked):
		return
	var Parent = Body.get_parent()
	if (Parent is MapSpot):
		RemovePort()
		Parent.OnSpotDeparture(self)
		for g in GetSquad():
			g.RemovePort()
			Parent.OnSpotDeparture(g)

#//////////////////////////////////////////////////////
 #██████  ███████ ████████ ████████ ███████ ██████  ███████ 
#██       ██         ██       ██    ██      ██   ██ ██      
#██   ███ █████      ██       ██    █████   ██████  ███████ 
#██    ██ ██         ██       ██    ██      ██   ██      ██ 
 #██████  ███████    ██       ██    ███████ ██   ██ ███████ 

func GetShipBodyArea() -> Area2D:
	return BodyShape
	
func GetShipRadarArea() -> Area2D:
	return RadarShape

func GetShipAcelerationNode() -> Node2D:
	return Acceleration
	
func GetShipIcon() -> Node2D:
	return ShipSprite

func GetFuelStats() -> Dictionary[String, float]:
	var Stats : Dictionary[String, float]
	
	var Fleet = GetSquad()
	var fuel_ef = Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
	var Weight =  Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	
	var fleetsize = 1 + Fleet.size()
	var total_fuel = Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
	var total_maxfuel = Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
	var inverse_ef_sum = 1.0 / ((fuel_ef / pow(Weight, 0.5)) * 10)
	
	# Group ships fuel and efficiency calculations
	for g in Fleet:
		var ship_fuel = g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var ship_maxfuel = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
		var ship_efficiency = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
		var ship_weight = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
		
		total_fuel += ship_fuel
		total_maxfuel += ship_maxfuel
		inverse_ef_sum += 1.0 / ((ship_efficiency / pow(ship_weight, 0.5)) * 10)

	var effective_efficiency = fleetsize / inverse_ef_sum
	# Calculate average efficiency for the group
	Stats["CurrentFuel"] = total_fuel
	Stats["MaxFuel"] = total_maxfuel
	Stats["FleetRange"] = total_fuel * effective_efficiency / fleetsize
	return Stats

func GetFleet() -> Array[MapShip]:
	var Fleet : Array[MapShip]
	
	if (Command != null):
		Fleet.append(Command)
		Fleet.append_array(Command.GetSquad())
	else:
		Fleet.append_array(GetSquad())
	
	return Fleet

func GetFuelRange() -> float:
	if (Command != null):
		return Command.GetFuelRange()
	var Fleet = GetSquad()
	
	var Weight = Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	var fuel = Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
	var fuel_ef = Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
	var fleetsize = 1 + Fleet.size()
	var total_fuel = fuel
	var inverse_ef_sum = 1.0 / ((fuel_ef / pow(Weight, 0.5)) * 10)
	
	# Group ships fuel and efficiency calculations
	for g in Fleet:
		var ship_fuel = g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var ship_efficiency = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
		var ship_weight = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
		total_fuel += ship_fuel
		inverse_ef_sum += 1.0 / ((ship_efficiency / pow(ship_weight, 0.5)) * 10)
		

	var effective_efficiency = fleetsize / inverse_ef_sum
	# Calculate average efficiency for the group
	return total_fuel * effective_efficiency / fleetsize

func GetFuelRangeWithExtraFuel(ExtraFuel : float) -> float:
	if (Command != null):
		return Command.GetFuelRange()
	var Fleet = GetSquad()
	
	var Weight = Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	var fuel = Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
	var fuel_ef = Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
	var fleetsize = 1 + Fleet.size()
	var total_fuel = fuel + ExtraFuel
	var inverse_ef_sum = 1.0 / ((fuel_ef / pow(Weight, 0.5)) * 10)
	
	# Group ships fuel and efficiency calculations
	for g in Fleet:
		var ship_fuel = g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var ship_efficiency = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
		var ship_weight = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
		total_fuel += ship_fuel
		inverse_ef_sum += 1.0 / ((ship_efficiency / pow(ship_weight, 0.5)) * 10)
		

	var effective_efficiency = fleetsize / inverse_ef_sum
	# Calculate average efficiency for the group
	return total_fuel * effective_efficiency / fleetsize

func GetBattleStats() -> BattleShipStats:
	
	var stats = BattleShipStats.new()
	stats.Hull = Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL)
	stats.CurrentHull = Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)
	stats.Speed = (Cpt.GetStatFinalValue(STAT_CONST.STATS.THRUST) * 1000) / Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	stats.FirePower = Cpt.GetStatFinalValue(STAT_CONST.STATS.FIREPOWER)
	stats.ShipIcon = Cpt.ShipIcon
	stats.CaptainIcon = Cpt.CaptainPortrait
	stats.Name = GetShipName()
	stats.Cards = Cpt.GetCharacterInventory().GetCards()
	stats.Weight = Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	stats.MaxShield =  Cpt.GetStatFinalValue(STAT_CONST.STATS.MAX_SHIELD)
	#stats.Ammo = Cpt.GetCharacterInventory().GetCardAmmo()
	stats.Funds = Cpt.ProvidingFunds
	stats.Convoy = false
	return stats
	
func GetShipMaxSpeed() -> float:
	var Spd
	if (Docked):
		Spd = Command.GetShipMaxSpeed()
	else:
		Spd = (Cpt.GetStatFinalValue(STAT_CONST.STATS.THRUST) * 1000) / Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
		for g in GetSquad():
			var DroneSpd = (g.Cpt.GetStatFinalValue(STAT_CONST.STATS.THRUST) * 1000) / g.Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
			if (DroneSpd < Spd):
				Spd = DroneSpd

	return Spd
	
func GetShipName() -> String:
	return Cpt.GetCaptainName()

func GetCurrentAcceleration() -> float:
	return Acceleration.position.x

func GetShipSpeed() -> float:
	if (Command != null):
		return Command.GetShipSpeed()
	return LastRecordedOffset.length() * 360

func GetShipSpeedVec() -> Vector2:
	return Acceleration.global_position - global_position

func GetShipAffectedSpeedVec() -> Vector2:
	var Spd = Acceleration.global_position - global_position
	var Windage = Cpt.GetStatFinalValue(STAT_CONST.STATS.WINDAGE) * 0.0001
	var AffectedSpeed = Spd + (WindVector * Windage)
	return AffectedSpeed

func UpdateShipWindManipulationModifier() -> void:
	var StormAffectedWind = WeatherManage.WindDirection + (WeatherManage.WindDirection * StormValue)
	var WeightModifier = 1 - Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT) / STAT_CONST.GetStatMaxValue(STAT_CONST.STATS.WEIGHT)
	var Height = 0.3 + 0.7 * (Altitude / 10000)
	var WindProt = TopographyMap.GetWindProtection(global_position ,Altitude)
	WindVector = (StormAffectedWind * WeightModifier * Height) * WindProt

func GetShipThrust() -> float:
	var Thrust = Cpt.GetStatFinalValue(STAT_CONST.STATS.THRUST)
	return Thrust

func GetSquaddB() -> float:
	var sounds : Array[float]
	sounds.append(GetdB())
	for g:MapShip in GetSquad():
		sounds.append(g.GetdB())
	var finaldB = Helper.CombineNoiseAmplitude(sounds)
	return finaldB

func GetSquad() -> Array[MapShip]:
	var squad : Array[MapShip]
	#squad.append(self)
	squad.append_array(GetDroneDock().GetDockedShips())
	return squad

func GetSquadCaptains() -> Array[Captain]:
	var squad : Array[Captain]
	for g : MapShip in GetSquad():
		squad.append(g.Cpt)
	return squad

func GetdB() -> float:
	if (Landed()):
		return 0
	var MaxdB = GetMaxdB()
	var CurrentdB = (max(GetCurrentAcceleration() / GetShipMaxSpeed(), 0.1)) * MaxdB
	return CurrentdB

func GetMaxdB() -> float:
	return GetShipThrust() / 30
	
func GetDroneDock():
	return DroneDok
	
func IsFuelFull() -> bool:
	for g in GetSquad():
		if (!g.IsFuelFull()):
			return false
	return Cpt.IsResourceFull(STAT_CONST.STATS.FUEL_TANK)

func GetValue() -> int:
	var Value : int = Cpt.ProvidingFunds / 2.0
	var InvContents : Dictionary[Item, int] = Cpt.GetCharacterInventory().GetInventoryContents()
	for g : Item in InvContents.keys():
		for z in InvContents[g]:
			Value += g.Cost
	return Value

#//////////////////////////////////////
#███████ ██ ███    ███ ██    ██ ██       █████  ████████ ██  ██████  ███    ██ 
#██      ██ ████  ████ ██    ██ ██      ██   ██    ██    ██ ██    ██ ████   ██ 
#███████ ██ ██ ████ ██ ██    ██ ██      ███████    ██    ██ ██    ██ ██ ██  ██ 
#     ██ ██ ██  ██  ██ ██    ██ ██      ██   ██    ██    ██ ██    ██ ██  ██ ██ 
#███████ ██ ██      ██  ██████  ███████ ██   ██    ██    ██  ██████  ██   ████ 


func TogglePause(t : bool):
	$AudioStreamPlayer2D.playing = !t
#/////////////////////////////////////

#func UpdateCameraZoom(NewZoom : float) -> void:
	#visible = NewZoom > 1.5
