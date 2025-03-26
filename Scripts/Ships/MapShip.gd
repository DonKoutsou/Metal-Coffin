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

@export var RadarShape : Area2D
@export var ElintShape : Area2D
@export var BodyShape : Area2D
@export var DroneDok : Node2D
@export var LowStatsToNotifyAbout : Array[String]
@export var Cpt : Captain

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
		
func _physics_process(delta: float) -> void:

	UpdateElint(delta)
	queue_redraw()

	if (Paused):
		return
	
	var SimulationSpeed = SimulationManager.SimSpeed()
	
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
	
	if (AccelChanged):
		var Audioween = create_tween()
		Audioween.tween_property($AudioStreamPlayer2D, "pitch_scale", lerp(0.1, 1.0, GetShipSpeed() / GetShipMaxSpeed()), 2)
		if (!$AudioStreamPlayer2D.playing):
			$AudioStreamPlayer2D.play()
		AccelChanged = false

	if (CurrentPort != null):
		Refuel()
		
		Repair()
		
		var inv = Cpt.GetCharacterInventory()
		if (inv._ItemBeingUpgraded != null):
			ShipDockActions.emit("Upgrading", true, roundi(inv.GetUpgradeTimeLeft()))
		else:
			ShipDockActions.emit("Upgrading", false, 0)

	if (Docked or GetShipSpeedVec() == Vector2.ZERO):
		return
	
	var FuelConsumtion = $Aceleration.position.x / Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY) * SimulationSpeed
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
		var dronefuel = ($Aceleration.position.x / Cap.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)) * SimulationSpeed
		if (Cap.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > dronefuel):
			Cap.ConsumeResource(STAT_CONST.STATS.FUEL_TANK,dronefuel)
		else : if (Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) >= dronefuel):
			Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, dronefuel)
		else: if (GetDroneDock().DronesHaveFuel(dronefuel)):
			GetDroneDock().SyphonFuelFromDrones(dronefuel)
		else:
			HaltShip()
			PopUpManager.GetInstance().DoFadeNotif("Your drones have run out of fuel.")

	var offset = GetShipSpeedVec()
	global_position += offset * SimulationSpeed

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

func UpdateCameraZoom(NewZoom : float) -> void:
	CamZoom = NewZoom
	queue_redraw()

func SetCurrentPort(Port : MapSpot):
	CurrentPort = Port
	Cpt.CurrentPort = Port.GetSpotName()
	var dr = GetDroneDock().GetDockedShips()
	for g in dr:
		g.SetCurrentPort(Port)
	PortChanged.emit(Port)
		
func SetSpeed(Spd : float) -> void:
	GetShipAcelerationNode().position.x = Spd

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
	$PlayerShipSpr.texture = Tex
	$PlayerShipSpr/ShadowPivot/Shadow.texture = Tex
	
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
		if (Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) <= 0):
			HaltShip()
			PopUpManager.GetInstance().DoPopUp("You have run out of fuel.")
			return
	
	AccelChanged = true
	
	
	GetShipAcelerationNode().position.x = max(0,min(value,1) * GetShipMaxSpeed())

func updatedronecourse():
	var plship = Command
	# Get the current position and velocity of the ship
	
	var ship_position = plship.position
	var ship_velocity = plship.GetShipSpeedVec()

	# Predict where the ship will be in a future time `t`
	var time_to_interception = (position.distance_to(ship_position)) / GetShipSpeed()

	# Calculate the predicted interception point
	var predicted_position = ship_position + ship_velocity * time_to_interception
	ShipLookAt(predicted_position)
	
func Steer(Rotation : float) -> void:
	rotation += Rotation / 50
	var piv = $PlayerShipSpr/ShadowPivot as Node2D
	piv.global_rotation = deg_to_rad(-90)
	var shadow = $PlayerShipSpr/ShadowPivot/Shadow as Node2D
	shadow.rotation = rotation
	for g in GetDroneDock().GetDockedShips():
		g.ForceSteer(rotation)

func ForceSteer(Rotation : float) -> void:
	rotation = Rotation
	var piv = $PlayerShipSpr/ShadowPivot as Node2D
	piv.global_rotation = deg_to_rad(-90)
	var shadow = $PlayerShipSpr/ShadowPivot/Shadow as Node2D
	shadow.rotation = rotation
		
func ShipLookAt(pos : Vector2) -> void:
	if (is_equal_approx(global_position.angle_to_point(pos), global_rotation)):
		return
	look_at(pos)
	var piv = $PlayerShipSpr/ShadowPivot as Node2D
	piv.global_rotation = deg_to_rad(-90)
	var shadow = $PlayerShipSpr/ShadowPivot/Shadow as Node2D
	shadow.rotation = rotation
	for g in GetDroneDock().GetDockedShips():
		g.global_rotation = global_rotation
	
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
	$PlayerShipSpr.scale = Vector2(lerp(0.03, 0.1, Altitude / 10000.0), lerp(0.03, 0.1, Altitude / 10000.0))
	$PlayerShipSpr/ShadowPivot/Shadow.position = Vector2(lerp(0, -20, Altitude / 10000.0), lerp(0, -20, Altitude / 10000.0))
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
	else: if (Parent is Missile):
		if (Parent.FiredBy is HostileShip):
			Parent.OnShipSeen(self)
	else : if (Parent is MapSpot):
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
	var Parent = Body.get_parent()
	if (Parent is MapSpot):
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
	return $ShipBody
	
func GetShipRadarArea() -> Area2D:
	return $Radar

func GetShipAcelerationNode() -> Node2D:
	return $Aceleration
	
func GetShipIcon() -> Node2D:
	return $PlayerShipSpr

func GetFuelStats() -> Dictionary[String, float]:
	var Stats : Dictionary[String, float]
	
	var Fleet = GetDroneDock().GetDockedShips()
	var fuel_ef = Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
	var fleetsize = 1 + Fleet.size()
	var total_fuel = Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
	var total_maxfuel = Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
	var inverse_ef_sum = 1.0 / fuel_ef
	
	# Group ships fuel and efficiency calculations
	for g in Fleet:
		var ship_fuel = g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var ship_maxfuel = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_TANK)
		var ship_efficiency = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
		total_fuel += ship_fuel
		total_maxfuel += ship_maxfuel
		inverse_ef_sum += 1.0 / ship_efficiency

	var effective_efficiency = fleetsize / inverse_ef_sum
	# Calculate average efficiency for the group
	Stats["CurrentFuel"] = total_fuel
	Stats["MaxFuel"] = total_maxfuel
	Stats["FleetRange"] = (total_fuel * effective_efficiency) / fleetsize
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
	
	var fuel = Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
	var fuel_ef = Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
	var fleetsize = 1 + Fleet.size()
	var total_fuel = fuel
	var inverse_ef_sum = 1.0 / fuel_ef
	
	# Group ships fuel and efficiency calculations
	for g in Fleet:
		var ship_fuel = g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		var ship_efficiency = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
		total_fuel += ship_fuel
		inverse_ef_sum += 1.0 / ship_efficiency

	var effective_efficiency = fleetsize / inverse_ef_sum
	# Calculate average efficiency for the group
	return (total_fuel * effective_efficiency) / fleetsize
	
func GetBattleStats() -> BattleShipStats:
	
	var stats = BattleShipStats.new()
	stats.Hull = Cpt.GetStatCurrentValue(STAT_CONST.STATS.HULL)
	stats.Speed = Cpt.GetStatFinalValue(STAT_CONST.STATS.SPEED)
	stats.FirePower = Cpt.GetStatFinalValue(STAT_CONST.STATS.FIREPOWER)
	stats.ShipIcon = Cpt.ShipIcon
	stats.CaptainIcon = Cpt.CaptainPortrait
	stats.Name = GetShipName()
	stats.Cards = Cpt.GetCharacterInventory().GetCards()
	stats.Ammo = Cpt.GetCharacterInventory().GetCardAmmo()
	stats.Funds = Cpt.ProvidingFunds
	stats.Convoy = false
	return stats
	
func GetShipMaxSpeed() -> float:
	var Spd = Cpt.GetStatFinalValue(STAT_CONST.STATS.SPEED)
	if (Docked):
		Spd = Command.GetShipMaxSpeed()
	else:
		for g in GetDroneDock().GetDockedShips():
			var DroneSpd = g.Cpt.GetStatFinalValue(STAT_CONST.STATS.SPEED)
			if (DroneSpd < Spd):
				Spd = DroneSpd

	return Spd
	
func GetShipName() -> String:
	return Cpt.CaptainName
	
func GetShipSpeed() -> float:
	if (Docked):
		return Command.GetShipSpeed()
	return $Aceleration.position.x
	
func GetShipSpeedVec() -> Vector2:
	return $Aceleration.global_position - global_position
	
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
	if (ElintDist == 0):
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
