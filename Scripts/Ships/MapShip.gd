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
@export var ShipShadow : Sprite2D
@export var ShadowPivot : Node2D
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
var CommingBack = false



signal ShipDeparted()
signal ShipDockActions(Stats : String, t : bool, timel : float)
signal StatLow(StatName : String)
signal OnShipDamaged(Amm : float, ShowVisuals : bool)
signal OnShipDestroyed(Sh : MapShip)

var Landing : bool = false
signal LandingStarted
signal LandingCanceled(Ship : MapShip)
signal LandingEnded(Ship : MapShip)
var TakingOff : bool = false
signal TakeoffStarted
signal TakeoffEnded(Ship : MapShip)

signal PortChanged(P : MapSpot)

signal Elint(T : bool, Lvl : int, Dir : String)
var ElintContacts : Dictionary

var Detectable = true



func _ready() -> void:
	ElintShape.connect("area_entered", BodyEnteredElint)
	ElintShape.connect("area_exited", BodyLeftElint)
	RadarShape.connect("area_entered", BodyEnteredRadar)
	RadarShape.connect("area_exited", BodyLeftRadar)
	BodyShape.connect("area_entered", BodyEnteredBody)
	BodyShape.connect("area_exited", BodyLeftBody)
	Cpt.connect("ShipPartChanged", PartChanged)
	
	MapPointerManager.GetInstance().AddShip(self, true)
	#SimulationSpeed = SimulationManager.SimSpeed()
	#TODO probably a better way to do this
	Cpt.CaptainShip = self
	###
	_UpdateShipIcon(Cpt.ShipIcon)
	for g in Cpt.CaptainStats:
		g.ForceMaxValue()
		
func _draw() -> void:
	if (ShowFuelRange):
		draw_circle(Vector2.ZERO, GetFuelRange(), Color(0.3, 0.7, 0.915), false, 2.0 / CamZoom, true)

func Refuel() -> void:
	if (!Cpt.IsResourceFull(STAT_CONST.STATS.FUEL_TANK) and CurrentPort.PlayerHasFuelReserves()):
		var SimulationSpeed = SimulationManager.SimSpeed()
		var TimeMulti = 0.05
		
		if (CurrentPort.HasFuel()):
			TimeMulti = 0.1
		var maxfuelcap = Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
		var currentfuel = Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var timeleft = (min(maxfuelcap, currentfuel + CurrentPort.PlayerFuelReserves) - currentfuel) / TimeMulti / 6
		ShipDockActions.emit("Refueling", true, roundi(timeleft))
		#ToggleShowRefuel("Refueling", true, roundi(timeleft))
		Cpt.RefillResource(STAT_CONST.STATS.FUEL_TANK, TimeMulti * SimulationSpeed)
		CurrentPort.PlayerFuelReserves -= TimeMulti * SimulationSpeed
	else:
		ShipDockActions.emit("Refueling", false, 0)

func Repair() -> void:
	if (!Cpt.IsResourceFull(STAT_CONST.STATS.HULL) and CurrentPort.PlayerRepairReserves > 0):
		var SimulationSpeed = SimulationManager.SimSpeed()
		var TimeMulti = 0.05
		
		if (CurrentPort.HasRepair()):
			TimeMulti = 0.25
		var timeleft = ((Cpt.GetStatFinalValue(STAT_CONST.STATS.HULL) - Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)) / TimeMulti / 6)
		ShipDockActions.emit("Repairing", true, roundi(timeleft))
		Cpt.RefillResource(STAT_CONST.STATS.HULL ,TimeMulti * SimulationSpeed)
		CurrentPort.PlayerRepairReserves -= TimeMulti * SimulationSpeed
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
	PortChanged.emit(Port)
		
func SetSpeed(Spd : float) -> void:
	GetShipAcelerationNode().position.x = Spd / 360

func RemovePort():
	ShipDeparted.emit()
	CurrentPort = null
	InventoryManager.GetInstance().CancelUpgrades(Cpt)
	Cpt.CurrentPort = ""
	if (Landing):
		LandingCanceled.emit(self)
		Landing = false
	if (Altitude != 10000 and !TakingOff):
		TakeoffStarted.emit()
		TakingOff = true
	var dr = GetDroneDock().GetDockedShips()
	for g in dr:
		g.RemovePort()
	PortChanged.emit(null)

func OnStatLow(StatName : String) -> void:
	if (!LowStatsToNotifyAbout.has(StatName)):
		return
	StatLow.emit(StatName)

func _UpdateShipIcon(Tex : Texture) -> void:
	ShipSprite.texture = Tex
	ShipShadow.texture = Tex
	
#///////////////////////////////////////////////
#███████ ██   ██ ██ ██████       ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ██ ███    ██  ██████  
#██      ██   ██ ██ ██   ██     ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██ ████   ██ ██       
#███████ ███████ ██ ██████      ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      ██ ██ ██  ██ ██   ███ 
#     ██ ██   ██ ██ ██          ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██ ██  ██ ██ ██    ██ 
#███████ ██   ██ ██ ██           ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ██ ██   ████  ██████ 

func HaltShip():
	SetSpeed(0)
	#AccelerationChanged(0)

var AccelChanged = false

func AccelerationChanged(value: float) -> void:
	if (Landing):
		LandingCanceled.emit(self)
		Landing = false

	else : if (Altitude != 10000 and !TakingOff):
		TakeoffStarted.emit()
		TakingOff = true

	if (value > 0):
		if (GetFuelRange() <= 0):
			HaltShip()
			PopUpManager.GetInstance().DoFadeNotif("You have run out of fuel.")
			return

	AccelChanged = true

	SetSpeed(max(0,min(value,1) * GetShipMaxSpeed()) )
	#GetShipAcelerationNode().position.x = max(0,min(value,1) * GetShipMaxSpeed()) 

func updatedronecourse():
	var plship = Command
	# Get the current position and velocity of the ship
	
	var ship_position = plship.position
	
	var Distance = global_position.distance_to(ship_position)
	
	if (Distance < 10):
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
	
	
	
func Steer(Rotation : float) -> void:
	rotation += Rotation / 50
	ShadowPivot.global_rotation = deg_to_rad(-90)
	ShipShadow.rotation = rotation
	for g in GetDroneDock().GetDockedShips():
		g.ForceSteer(rotation)

func ForceSteer(Rotation : float) -> void:
	rotation = Rotation
	ShadowPivot.global_rotation = deg_to_rad(-90)
	ShipShadow.rotation = rotation
		
func ShipLookAt(pos : Vector2) -> void:
	if (is_equal_approx(global_position.angle_to_point(pos), global_rotation)):
		return
	look_at(pos)
	ShadowPivot.global_rotation = deg_to_rad(-90)
	ShipShadow.rotation = rotation
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
	ShipSprite.scale = Vector2(lerp(0.03, 0.1, Altitude / 10000.0), lerp(0.03, 0.1, Altitude / 10000.0))
	ShipShadow.position = Vector2(lerp(0, -40, Altitude / 10000.0), lerp(0, -40, Altitude / 10000.0))
	for g in GetDroneDock().GetDockedShips():
		g.UpdateAltitude(NewAlt)
	
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
		var Newlvl = GetElintLevel(global_position.distance_to(ship.global_position), ship.Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE))
		if (Newlvl > BiggestLevel):
			BiggestLevel = Newlvl
			Dir = global_position.angle_to_point(ship.global_position)
		if (Newlvl != lvl):
			ElintContacts[ship] = Newlvl
	if (BiggestLevel > -1):
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.ELINT_CONTACT)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.ELINT_CONTACT)
			ActionTracker.GetInstance().ShowTutorial("Electronic Intelligence", "The Elint sensors of one of your ships has been triggered. Elint detects enemy radar signals and provides a rough estimation on the distance and the direction of the signal. If the sensor is triggered it means you are about to enter into a radar's signal range and be detected.", [], true)
		Elint.emit(true, BiggestLevel, Helper.GetInstance().AngleToDirection(Dir))
	else:
		Elint.emit(false, -1, "")

func UpdateVizRange(rang : float):
	#print("{0}'s radar range has been set to {1}".format([GetShipName(), rang]))
	var RadarRangeCollisionShape = RadarShape.get_node("CollisionShape2D")
	(RadarRangeCollisionShape.shape as CircleShape2D).radius = max(rang, 105)

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
		if (Parent.SpotInfo.EnemyCity):
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
			ActionTracker.GetInstance().ShowTutorial("Landing", "You have entrered the perimiter of a town. To visit the town's verdors to resuply you need to land your fleet. To do so click the Land button next to the thrust lever to initiate the landing procedure.", [World.GetInstance().GetMap().GetScreenUi().LandButton], false)
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
	var inverse_ef_sum = 1.0 / (fuel_ef - Weight / 40)
	
	# Group ships fuel and efficiency calculations
	for g in Fleet:
		var ship_fuel = g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var ship_maxfuel = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
		var ship_efficiency = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
		var ship_weight = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
		
		total_fuel += ship_fuel
		total_maxfuel += ship_maxfuel
		inverse_ef_sum += 1.0 / (ship_efficiency - ship_weight / 40)
		

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
	var inverse_ef_sum = 1.0 / (fuel_ef - Weight / 40)
	
	# Group ships fuel and efficiency calculations
	for g in Fleet:
		var ship_fuel = g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var ship_efficiency = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
		var ship_weight = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
		total_fuel += ship_fuel
		inverse_ef_sum += 1.0 / (ship_efficiency - ship_weight / 40)
		

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
	return Cpt.CaptainName
	
func GetShipSpeed() -> float:
	if (Docked):
		return Command.GetShipSpeed()
	return Acceleration.position.x * 360
	
func GetShipSpeedVec() -> Vector2:
	return Acceleration.global_position - global_position
	
func GetClosestElint() -> Vector2:
	var closest : Vector2 = Vector2.ZERO
	var closestdist : float = 999999999999
	for g in ElintContacts.size():
		var ship = ElintContacts.keys()[g]
		var dist = global_position.distance_to(ship.global_position)
		if (closestdist > dist):
			closest = ship.global_position
			closestdist = dist
	
	return closest
	
func GetElintLevel(Dist : float, RadarL : float) -> int:
	var Lvl = -1
	var ElintDist = Cpt.GetStatFinalValue(STAT_CONST.STATS.ELINT)
	if (ElintDist == 0 or RadarL <= 90):
		return Lvl
	if (Dist < RadarL):
		Lvl = 3
	else : if (Dist < RadarL * 2):
		Lvl = 2
	else : if (Dist < RadarL * 10):
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

#func ChangeSimulationSpeed(i : float):
	#SimulationSpeed = i

func TogglePause(t : bool):
	Paused = t
	$AudioStreamPlayer2D.playing = !t
#/////////////////////////////////////

func UpdateCameraZoom(NewZoom : float) -> void:
	visible = NewZoom > 0.5
