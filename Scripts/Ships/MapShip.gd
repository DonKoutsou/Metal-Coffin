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
@export var RadarShape : Area2D
@export var ElintShape : Area2D
@export var BodyShape : Area2D
@export var DroneDok : Node2D
@export var ShipSprite : Sprite2D
@export var Acceleration : Node2D


var Paused = true
#var SimulationSpeed : float = 1
var CurrentPort : MapSpot

var RadarWorking = true
var Altitude = 10000
var Command : MapShip

var ShowFuelRange = true
var Docked = false
var CamZoom = 1


signal ShipDeparted(DepartedFrom : MapSpot)
signal ShipDockActions(Stats : String, t : bool, timel : float)
signal StatLow(StatName : String)
signal OnShipDamaged(Amm : float, ShowVisuals : bool)
signal OnShipDestroyed(Sh : MapShip)


signal AChanged(NewAccel : float)
signal AForced(NewAccel : float)
var Landing : bool = false
signal LandingStarted
signal LandingCanceled(Ship : MapShip)
signal LandingEnded(Ship : MapShip)
signal LandingEnded2
var TakingOff : bool = false
signal TakeoffStarted
signal TakeoffEnded(Ship : MapShip)
var MatchingAltitude : bool = false
signal MatchingAltitudeStarted
signal MatchingAltitudeEnded(Ship : MapShip)

signal PortChanged()

signal Elint(T : bool, Lvl : int, Dir : String)
var ElintContacts : Dictionary

var Detectable = true

var VisibilityValue : float = 0
var StormValue : float = 0

func _ready() -> void:
	ElintShape.connect("area_entered", BodyEnteredElint)
	ElintShape.connect("area_exited", BodyLeftElint)
	RadarShape.connect("area_entered", BodyEnteredRadar)
	RadarShape.connect("area_exited", BodyLeftRadar)
	BodyShape.connect("area_entered", BodyEnteredBody)
	BodyShape.connect("area_exited", BodyLeftBody)
	Cpt.connect("ShipPartChanged", PartChanged)
	
	MapPointerManager.GetInstance().AddShip(self, true)

	#TODO probably a better way to do this
	Cpt.CaptainShip = self
	_UpdateShipIcon(Cpt.ShipIcon)
	for g in Cpt.CaptainStats:
		g.ForceMaxValue()
		

#Refuel logic
func Refuel() -> void:
	#Make sure that the ship is landed
	#Make sure that fuel tanks are not full
	#Make sure port has fuel
	var IsLanded = Altitude == 0
	var FuelIsFull = IsFuelFull()
	var TownHasFuel = CurrentPort.PlayerHasFuelReserves()

	if (IsLanded and !FuelIsFull and TownHasFuel):
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
		ShipsToRefuel.append_array(GetDroneDock().GetDockedShips())
		
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
	if (Altitude == 0 and !Cpt.IsResourceFull(STAT_CONST.STATS.HULL) and Cpt.Repair_Parts > 0):
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
			UpdateVizRange(Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE))
		else : if (g.UpgradeName == STAT_CONST.STATS.ELINT):
			UpdateELINTTRange(Cpt.GetStatFinalValue(STAT_CONST.STATS.ELINT))

func ToggleFuelRangeVisibility(t : bool) -> void:
	ShowFuelRange = t


func SetCurrentPort(Port : MapSpot):
	CurrentPort = Port
	Cpt.CurrentPort = Port.GetSpotName()
	var dr = GetDroneDock().GetDockedShips()
	for g in dr:
		g.SetCurrentPort(Port)
	PortChanged.emit()
		
func SetSpeed(Spd : float) -> void:
	GetShipAcelerationNode().position.x = Spd / 360

func _HandleLanding(SimulationSpeed : float) -> void:
	if (Landing):
		UpdateAltitude(max(0, Altitude - (60 * SimulationSpeed)))
		if (Altitude <= 0):
			Altitude = 0
			LandingEnded.emit(self)
			LandingEnded2.emit()
			Landing = false
	else: if (TakingOff):
		UpdateAltitude(min(10000, Altitude + (60 * SimulationSpeed)))
		if (Altitude >= 10000):
			Altitude = 10000
			TakeoffEnded.emit(self)
			TakingOff = false
	else: if (MatchingAltitude):
		UpdateAltitude(clamp(move_toward(Altitude, Command.Altitude, 60 * SimulationSpeed), 0, 10000))
		if (Altitude == Command.Altitude):
			MatchingAltitudeEnded.emit(self)
			MatchingAltitude = false

func InitialiseAltitudeMatching() -> void:
	MatchingAltitude = true
	MatchingAltitudeStarted.emit()

func RemovePort():
	ShipDeparted.emit(CurrentPort)
	CurrentPort = null
	InventoryManager.GetInstance().CancelUpgrades(Cpt)
	Cpt.CurrentPort = ""
	if (Landing):
		LandingCanceled.emit(self)
		Landing = false
	if (Altitude != 10000 and !TakingOff):
		TakingOff = true
		TakeoffStarted.emit()
	var dr = GetDroneDock().GetDockedShips()
	for g in dr:
		g.RemovePort()
	PortChanged.emit()

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
	if (Landing):
		LandingCanceled.emit(self)
		Landing = false

	else : if (Altitude != 10000 and !TakingOff):
		TakingOff = true
		TakeoffStarted.emit()
		RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.LIFTOFF)

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
	#GetShipAcelerationNode().position.x = max(0,min(value,1) * GetShipMaxSpeed()) 
	
func Steer(Rotation : float) -> void:
	rotation += Rotation / 50
	
	var Mat = ShipSprite.material as ShaderMaterial
	Mat.set_shader_parameter("sprite_rotation", ShipSprite.global_rotation)

	for g in GetDroneDock().GetDockedShips():
		g.ForceSteer(rotation)

func ForceSteer(Rotation : float) -> void:
	rotation = Rotation
	var Mat = ShipSprite.material as ShaderMaterial
	Mat.set_shader_parameter("sprite_rotation", ShipSprite.global_rotation)
	for g in GetDroneDock().GetDockedShips():
		g.ForceSteer(rotation)
		
func ShipLookAt(pos : Vector2) -> void:
	if (is_equal_approx(global_position.angle_to_point(pos), global_rotation)):
		return
	look_at(pos)
	var Mat = ShipSprite.material as ShaderMaterial
	Mat.set_shader_parameter("sprite_rotation", ShipSprite.global_rotation)

	for g in GetDroneDock().GetDockedShips():
		g.ForceSteer(rotation)

func SetShipPosition(pos : Vector2) -> void:
	global_position = pos
	for g in TrailLines:
		g.Init()

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

func StartLanding() -> void:
	if (TakingOff):
		TakeoffEnded.emit(null)
		TakingOff = false
	LandingStarted.emit()
	Landing = true
	
func Landed() -> bool:
	return Altitude == 0

func UpdateAltitude(NewAlt : float) -> void:
	Altitude = NewAlt
	#var S = lerp(0.05, 0.1, Altitude / 10000.0)
	#ShipSprite.scale = Vector2(lerp(0.05, 0.1, Altitude / 10000.0), lerp(0.05, 0.1, Altitude / 10000.0))
	
	var Mat = ShipSprite.material as ShaderMaterial
	Mat.set_shader_parameter("shadow_parallax_amount", lerp(0.0, ParalaxMulti, Altitude / 10000.0))
	Mat.set_shader_parameter("ShipSize", lerp(0.001, 0.008, Altitude / 10000.0))

	for g in GetDroneDock().GetDockedShips():
		g.UpdateAltitude(NewAlt)

func GetShipParalaxPosition(CamPos : Vector2, Zoom : float) -> Vector2:
	var offset = (CamPos - global_position) * Zoom * lerp(0.0, 0.88, Altitude / 10000.0) * 0.05
	offset.x /= 1.65
	return global_position - offset

func UpdateELINTTRange(rang : float):
	var ElintRangeCollisionShape = ElintShape.get_node("CollisionShape2D")
	#scalling collision
	(ElintRangeCollisionShape.shape as CircleShape2D).radius = rang


#//////////////////////////////////////////////////////////
#██████   █████  ██████   █████  ██████      ██ ███████ ██      ██ ███    ██ ████████ 
#██   ██ ██   ██ ██   ██ ██   ██ ██   ██    ██  ██      ██      ██ ████   ██    ██    
#██████  ███████ ██   ██ ███████ ██████    ██   █████   ██      ██ ██ ██  ██    ██    
#██   ██ ██   ██ ██   ██ ██   ██ ██   ██  ██    ██      ██      ██ ██  ██ ██    ██    
#██   ██ ██   ██ ██████  ██   ██ ██   ██ ██     ███████ ███████ ██ ██   ████    ██    

func ToggleRadar():
	Detectable = !Detectable
	RadarWorking = !RadarWorking
	if (RadarWorking):
		#RadarShape.get_child(0).disabled = false
		UpdateVizRange(Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE))
	else:
		#RadarShape.get_child(0).disabled = false
		UpdateVizRange(0)
	for g in GetDroneDock().DockedDrones:
		g.ToggleRadar()
		
func ToggleElint():
	$Elint/CollisionShape2D.disabled = !$Elint/CollisionShape2D.disabled
	
var d = 0.4

func UpdateElint(delta: float) -> void:
	d -= delta
	if (d > 0):
		return
	d = 0.4
	var BiggestLevel = -1
	var Dir : float
	for g in ElintContacts.size():
		var ship = ElintContacts.keys()[g] as MapShip
		var lvl = ElintContacts.values()[g]
		var Newlvl = GetElintLevel(global_position.distance_squared_to(ship.global_position), ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE))
		if (Newlvl > BiggestLevel):
			BiggestLevel = Newlvl
			Dir = global_position.angle_to_point(ship.global_position)
		if (Newlvl != lvl):
			ElintContacts[ship] = Newlvl
	if (BiggestLevel > -1):
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.ELINT_CONTACT)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.ELINT_CONTACT)
			ActionTracker.GetInstance().ShowTutorial("Electronic Intelligence", "The Elint sensors of one of your ships has been triggered. Elint detects enemy radar signals and provides a rough estimation on the distance and the direction of the signal. If the sensor is triggered it means you are about to enter into a radar's signal range and be detected.", [], true)
		Elint.emit(true, BiggestLevel, Helper.AngleToDirection(Dir))
	else:
		Elint.emit(false, -1, "")

func UpdateVizRange(rang : float):
	#print("{0}'s radar range has been set to {1}".format([GetShipName(), rang]))
	var RadarRangeCollisionShape = RadarShape.get_node("CollisionShape2D")
	(RadarRangeCollisionShape.shape as CircleShape2D).radius = max(rang, 110)

func RephreshVisRange() -> void:
	var VisualRange = VisibilityValue
	if (RadarWorking):
		VisualRange = Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE)
	var RadarRangeCollisionShape = RadarShape.get_node("CollisionShape2D")
	(RadarRangeCollisionShape.shape as CircleShape2D).radius = max(VisualRange, VisibilityValue)

#/////////////////////////////////////////////////////
#██████  ██   ██ ██    ██ ███████ ██  ██████ ███████     ███████ ██    ██ ███████ ███    ██ ████████ ███████ 
#██   ██ ██   ██  ██  ██  ██      ██ ██      ██          ██      ██    ██ ██      ████   ██    ██    ██      
#██████  ███████   ████   ███████ ██ ██      ███████     █████   ██    ██ █████   ██ ██  ██    ██    ███████ 
#██      ██   ██    ██         ██ ██ ██           ██     ██       ██  ██  ██      ██  ██ ██    ██         ██ 
#██      ██   ██    ██    ███████ ██  ██████ ███████     ███████   ████   ███████ ██   ████    ██    ███████ 

func BodyEnteredElint(Body: Area2D) -> void:
	if (Body.get_parent() == self):
		return
	ElintContacts[Body.get_parent()] = 0
	#Elint.emit(true, 1)
	
func BodyLeftElint(Body: Area2D) -> void:
	if (Body.get_parent() == self):
		return
	ElintContacts.erase(Body.get_parent())
	#Elint.emit(false, 0)

func BodyEnteredRadar(Body : Area2D) -> void:
	var Parent = Body.get_parent()
	if (Parent is HostileShip):
		Parent.OnShipSeen(self)
		if (Parent.Convoy and !ActionTracker.IsActionCompleted(ActionTracker.Action.CONVOY)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.CONVOY)
			ActionTracker.GetInstance().ShowTutorial("Enemy Convoys", "You have located an enemy convoy. These convoys pose no risk since the have no weapons on them an are usually not escorted by any combatants. Capturing any of those convoys is dangerous since they can raise the alarm on you and signify your position to the enemy. Managing to capture on will provide a good reward once any of those is brought back to any of the cities, where the ship can be broken down and sold. Bring any captured convoy to any city and land it to receive your reward.", [], true)
		
	else: if (Parent is Missile):
		if (Parent.FiredBy is HostileShip):
			Parent.OnShipSeen(self)
	else : if (Parent is MapSpot):
		if (Parent.EnemyCity):
			if (!ActionTracker.IsActionCompleted(ActionTracker.Action.ENEMY_TOWN_APROACH)):
				ActionTracker.OnActionCompleted(ActionTracker.Action.ENEMY_TOWN_APROACH)
				var TutText = "You are reaching an enemy [color=#ffc315]city[/color]. Enemy cities are usual refuel spots for [color=#ffc315]patrols[/color], and always have a guarding [color=#ffc315]garrisson[/color] in their center. Entering the perimiter of a city will comence combat with all enemies that happen to be in it."
				ActionTracker.GetInstance().ShowTutorial("Enemy Cities", TutText, [], true)
		else:
			if (!ActionTracker.IsActionCompleted(ActionTracker.Action.TOWN_APROACH)):
				ActionTracker.OnActionCompleted(ActionTracker.Action.TOWN_APROACH)
				var TutText = "You are reaching one of the many friendly [color=#ffc315]villages[/color] in the glacier. No enemies exist in those [color=#ffc315]villages[/color] and none of the locals wil raise the [color=#ffc315]alarm[/color] on you. You are free to use those [color=#ffc315]villages[/color] to restock/repair or even as a hideout. The location of those [color=#ffc315]villages[/color] is unknown and will need to be discovered."
				ActionTracker.GetInstance().ShowTutorial("Friendly Villages", TutText, [], true)
		if (!Parent.Seen):
			Parent.OnSpotSeen()

func BodyLeftRadar(Body : Area2D) -> void:
	var Parent = Body.get_parent()
	if (Parent is HostileShip):
		Parent.OnShipUnseen(self)
	else: if (Parent is Missile):
		if (Parent.FiredBy is HostileShip):
			Parent.OnShipUnseen(self)
			
func BodyEnteredBody(Body : Area2D) -> void:
	if (Docked):
		return
	var Parent = Body.get_parent()
	if (Parent is MapSpot):
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.LANDING)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.LANDING)
			#TODO fix this
			#ActionTracker.GetInstance().ShowTutorial("Landing", "You have entrered the perimiter of a [color=#ffc315]Town[/color].\nTo visit the [color=#ffc315]town[/color]'s verdors and resuply you'll need to land your fleet.\nTo do so click the [color=#ffc315]Land Button[/color] while over a [color=#ffc315]Town[/color] to initiate the landing procedure. Once the landing is complete press the [color=#ffc315]Open Hatch[/color] button bellow the land button to visit the town.", [World.GetInstance().GetMap().GetScreenUi().LandButton, World.GetInstance().GetMap().GetScreenUi().HatchButton], false)
		SetCurrentPort(Parent)
		Parent.OnSpotAproached(self)
		for g in GetDroneDock().GetDockedShips():
			g.SetCurrentPort(Parent)
			Parent.OnSpotAproached(g)
	
func BodyLeftBody(Body : Area2D) -> void:
	if (Docked):
		return
	var Parent = Body.get_parent()
	if (Parent is MapSpot):
		RemovePort()
		Parent.OnSpotDeparture(self)
		for g in GetDroneDock().GetDockedShips():
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
	
	var Fleet = GetDroneDock().GetDockedShips()
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
		Fleet.append_array(Command.GetDroneDock().DockedDrones)
	else:
		Fleet.append_array(GetDroneDock().DockedDrones)
	
	return Fleet

func GetFuelRange() -> float:
	if (Command != null):
		return Command.GetFuelRange()
	var Fleet = GetDroneDock().GetDockedShips()
	
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
	var Fleet = GetDroneDock().GetDockedShips()
	
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
		for g in GetDroneDock().GetDockedShips():
			var DroneSpd = (g.Cpt.GetStatFinalValue(STAT_CONST.STATS.THRUST) * 1000) / g.Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
			if (DroneSpd < Spd):
				Spd = DroneSpd

	return Spd
	
func GetShipName() -> String:
	return Cpt.GetCaptainName()
	
func GetShipSpeed() -> float:
	if (Command != null):
		return Command.GetShipSpeed()
	return (Acceleration.position.x * 360)

func GetAffectedSpeed() -> float:
	if (Command != null):
		return Command.GetAffectedSpeed()
	var WindVel = GetShipWindManipulationModifier()
	var Spd = GetShipSpeed()
	var AffectedSpeed = Spd + (Spd * WindVel)
	return AffectedSpeed

func GetShipWindManipulationModifier() -> float:
	var WindVel = Vector2.RIGHT.rotated(rotation).dot(WeatherManage.WindDirection) * (WeatherManage.WindSpeed / WeatherManage.MAX_WIND_SPEED) * 0.2
	var WeightModifier = 1 - Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT) / STAT_CONST.GetStatMaxValue(STAT_CONST.STATS.WEIGHT)
	return WindVel * WeightModifier

func GetShipThrust() -> float:
	var Thrust = Cpt.GetStatFinalValue(STAT_CONST.STATS.THRUST) * (GetShipSpeed() / GetShipMaxSpeed())
	
	return Thrust

func GetShipSpeedVec() -> Vector2:
	return Acceleration.global_position - global_position
	
func GetClosestElint() -> Vector2:
	var closest : Vector2 = Vector2.ZERO
	var closestdist : float = 999999999999999999
	for g in ElintContacts.size():
		var ship = ElintContacts.keys()[g]
		var dist = global_position.distance_squared_to(ship.global_position)
		if (closestdist > dist):
			closest = ship.global_position
			closestdist = dist
	for g:MapShip in GetDroneDock().GetDockedShips():
		var DroneClosest = g.GetClosestElint()
		var dist = global_position.distance_squared_to(DroneClosest)
		if(dist < closestdist):
			closest = DroneClosest
	return closest

func GetClosestElintLevel() -> int:
	if (ElintContacts.size() == 0):
		return -1
	var closest : MapShip
	var closestdist : float = 9999999999999999
	for g in ElintContacts.size():
		var ship = ElintContacts.keys()[g]
		var dist = global_position.distance_squared_to(ship.global_position)
		if (closestdist > dist):
			closest = ship
			closestdist = dist
	
	var Newlvl = GetElintLevel(global_position.distance_squared_to(closest.global_position), closest.Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE))
	for g:MapShip in GetDroneDock().GetDockedShips():
		Newlvl = max(Newlvl, g.GetClosestElintLevel())
	return Newlvl
	
func GetElintLevel(DistSq : float, RadarL : float) -> int:
	var Lvl = -1
	var RadarLSq = RadarL * RadarL
	var ElintDist = Cpt.GetStatFinalValue(STAT_CONST.STATS.ELINT)
	if (ElintDist == 0 or RadarL <= 90):
		return Lvl
	if (DistSq < RadarLSq):
		Lvl = 3
	else : if (DistSq < RadarLSq * 2):
		Lvl = 2
	else : if (DistSq < RadarLSq * 10):
		Lvl = 1
	return Lvl
	
func GetDroneDock():
	return DroneDok
	
func IsFuelFull() -> bool:
	for g in GetDroneDock().DockedDrones:
		if (!g.IsFuelFull()):
			return false
	return Cpt.IsResourceFull(STAT_CONST.STATS.FUEL_TANK)

#//////////////////////////////////////
#███████ ██ ███    ███ ██    ██ ██       █████  ████████ ██  ██████  ███    ██ 
#██      ██ ████  ████ ██    ██ ██      ██   ██    ██    ██ ██    ██ ████   ██ 
#███████ ██ ██ ████ ██ ██    ██ ██      ███████    ██    ██ ██    ██ ██ ██  ██ 
#     ██ ██ ██  ██  ██ ██    ██ ██      ██   ██    ██    ██ ██    ██ ██  ██ ██ 
#███████ ██ ██      ██  ██████  ███████ ██   ██    ██    ██  ██████  ██   ████ 


func TogglePause(t : bool):
	Paused = t
	$AudioStreamPlayer2D.playing = !t
#/////////////////////////////////////

func UpdateCameraZoom(NewZoom : float) -> void:
	visible = NewZoom > 1.5
