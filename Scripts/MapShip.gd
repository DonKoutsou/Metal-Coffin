extends Node2D

class_name MapShip

@export var LowStatsToNotifyAbout : Array[String]
@export var Cpt : Captain

#@export var Missile : PackedScene

var ShipType : BaseShip

var Travelling = false
#var ChangingCourse = false
var Paused = true
var SimulationSpeed : int = 1
var CurrentPort : MapSpot
var CanRefuel = false
var CanRepair = false
var CanUpgrade = false
var IsRefueling = false
var RadarWorking = true
var Altitude = 10000
var Command : MapShip
var ShowFuelRange = true
var Docked = false
var CamZoom = 1
var CommingBack = false
signal ShipStopped
signal ShipAccelerating
signal ShipForceStopped
signal ShipDeparted()
signal ShipDockActions(Stats : String, t : bool, timel : float)
signal StatLow(StatName : String)
signal OnShipDestroyed(Sh : MapShip)

var Landing : bool = false
signal LandingStarted
signal LandingCanceled(Ship : MapShip)
signal LandingEnded(Ship : MapShip)
var TakingOff : bool = false
signal TakeoffStarted
signal TakeoffEnded(Ship : MapShip)

signal Elint(T : bool, Lvl : int)
var ElintContacts : Dictionary

var Detectable = true

func _ready() -> void:
	$Elint.connect("area_entered", _on_elint_area_entered)
	$Elint.connect("area_exited", _on_elint_area_exited)
	Cpt.connect("ShipPartChanged", PartChanged)
	MapPointerManager.GetInstance().AddShip(self, true)
	_UpdateShipIcon(Cpt.ShipIcon)
	for g in Cpt.CaptainStats:
		g.CurrentVelue = g.GetStat()
func _draw() -> void:
	if (ShowFuelRange):
		draw_circle(Vector2.ZERO, GetFuelRange(), Color(0.763, 0.659, 0.082), false, 2 / CamZoom, true)

func _physics_process(delta: float) -> void:
	queue_redraw()
	if (Paused):
		return
	if (Landing):
		UpdateAltitude(Altitude - (20 * SimulationSpeed))
		if (Altitude <= 0):
			Altitude = 0
			LandingEnded.emit(self)
			Landing = false
	if (TakingOff):
		UpdateAltitude(Altitude + (20 * SimulationSpeed))
		if (Altitude >= 10000):
			Altitude = 10000
			TakeoffEnded.emit(self)
			TakingOff = false
	UpdateElint(delta)
	
	if (CurrentPort != null):
		#CurrentPort.OnSpotVisited()
		#if (CanRefuel):
		if (Cpt.GetStat("FUEL_TANK").CurrentVelue < Cpt.GetStatFinalValue("FUEL_TANK") and CurrentPort.PlayerFuelReserves > 0):
			var maxfuelcap = Cpt.GetStatFinalValue("FUEL_TANK")
			var currentfuel = Cpt.GetStat("FUEL_TANK").CurrentVelue
			var timeleft = (min(maxfuelcap, currentfuel + CurrentPort.PlayerFuelReserves) - currentfuel) / 0.05 / 6
			ShipDockActions.emit("Refueling", true, roundi(timeleft))
			#ToggleShowRefuel("Refueling", true, roundi(timeleft))
			Cpt.GetStat("FUEL_TANK").CurrentVelue +=  0.05 * SimulationSpeed
			CurrentPort.PlayerFuelReserves -= 0.05 * SimulationSpeed
		else:
			ShipDockActions.emit("Refueling", false, 0)
				#ToggleShowRefuel("Refueling", false)
		#if (CanRepair):
		if (Cpt.GetStat("HULL").GetCurrentValue() < Cpt.GetStat("HULL").GetStat() and CurrentPort.PlayerRepairReserves > 0):
			var timeleft = ((Cpt.GetStat("HULL").GetStat() - Cpt.GetStat("HULL").GetCurrentValue()) / 0.05 / 6)
			ShipDockActions.emit("Repairing", true, roundi(timeleft))
			#ToggleShowRefuel("Repairing", true, roundi(timeleft))
			Cpt.GetStat("HULL").RefilCurrentVelue(0.05 * SimulationSpeed)
		else:
			ShipDockActions.emit("Repairing", false, 0)
				#ToggleShowRefuel("Repairing", false)
		#if (CanUpgrade):
		var inv = InventoryManager.GetInstance().GetCharacterInventory(Cpt)
		if (inv._ItemBeingUpgraded != null):
			#ToggleShowRefuel("Upgrading", true, roundi(inv.GetUpgradeTimeLeft()))
			ShipDockActions.emit("Upgrading", true, roundi(inv.GetUpgradeTimeLeft()))
		else:
			ShipDockActions.emit("Upgrading", false, 0)
			#ToggleShowRefuel("Upgrading", false)
	if (Docked):
		return
	
	var FuelConsumtion = $Aceleration.position.x / 10 / Cpt.GetStatFinalValue("FUEL_EFFICIENCY") * SimulationSpeed
	
	#Consume fuel on shif if enough
	if (Cpt.GetStat("FUEL_TANK").GetCurrentValue() >= FuelConsumtion):
		Cpt.GetStat("FUEL_TANK").CurrentVelue -= FuelConsumtion
	# If not enough on ship syphoon some from drones in dock
	else: if (GetDroneDock().DronesHaveFuel(FuelConsumtion)):
		GetDroneDock().SyphonFuelFromDrones(FuelConsumtion)
		#SetFuelShaderRange(GetFuelRange())
	else:
		HaltShip()
		PopUpManager.GetInstance().DoFadeNotif("Your drone has run out of fuel.")
		return
	#if (Cpt.GetStat("FUEL_TANK").CurrentVelue <= 0)
	
	if (CommingBack):
		updatedronecourse()
	
	for g in GetDroneDock().DockedDrones:
		var dronefuel = ($Aceleration.position.x / 10 / g.Cpt.GetStat("FUEL_EFFICIENCY").GetStat()) * SimulationSpeed
		if (g.Cpt.GetStat("FUEL_TANK").CurrentVelue > dronefuel):
			g.Cpt.GetStat("FUEL_TANK").CurrentVelue -= dronefuel
		else : if (Cpt.GetStat("FUEL_TANK").GetCurrentValue() >= dronefuel):
			Cpt.GetStat("FUEL_TANK").CurrentVelue -= dronefuel
		else:
			HaltShip()
			PopUpManager.GetInstance().DoFadeNotif("Your drones have run out of fuel.")

	var offset = GetShipSpeedVec()
	global_position += offset * SimulationSpeed
	
func TogglePause(t : bool):
	Paused = t
	$AudioStreamPlayer2D.stream_paused = t

func PartChanged(It : ShipPart) -> void:
	for g in It.Upgrades:
		if (g.UpgradeName == "VIZ_RANGE"):
			UpdateVizRange(Cpt.GetStat("VIZ_RANGE").GetStat())
		else : if (g.UpgradeName == "ELINT"):
			UpdateELINTTRange(Cpt.GetStat("ELINT").GetStat())
func ChangeSimulationSpeed(i : int):
	SimulationSpeed = i

func ToggleRadar():
	Detectable = !Detectable
	RadarWorking = !RadarWorking
	$Radar/CollisionShape2D.set_deferred("disabled", !$Radar/CollisionShape2D.disabled)
	for g in GetDroneDock().DockedDrones:
		g.ToggleRadar()
func ToggleElint():
	$Elint/CollisionShape2D.disabled = !$Elint/CollisionShape2D.disabled
func ToggleFuelRangeVisibility(t : bool) -> void:
	ShowFuelRange = t

func StartLanding() -> void:
	if (TakingOff):
		TakeoffEnded.emit()
		TakingOff = false
	LandingStarted.emit()
	Landing = true
func Landed() -> bool:
	return Altitude == 0

func UpdateAltitude(NewAlt : float) -> void:
	Altitude = NewAlt
	$PlayerShipSpr.scale = Vector2(lerp(0.3, 1.0, Altitude / 10000.0), lerp(0.3, 1.0, Altitude / 10000.0))
	$PlayerShipSpr/ShadowPivot/Shadow.position = Vector2(lerp(0, -20, Altitude / 10000.0), lerp(0, -20, Altitude / 10000.0))
	for g in GetDroneDock().DockedDrones:
		g.UpdateAltitude(NewAlt)
var d = 0.4
func UpdateElint(delta: float) -> void:
	d -= delta
	if (d > 0):
		return
	d = 0.4
	var BiggestLevel = 0
	for g in ElintContacts.size():
		var ship = ElintContacts.keys()[g]
		var lvl = ElintContacts.values()[g]
		var Newlvl = GetElintLevel(global_position.distance_to(ship.global_position))
		if (Newlvl > BiggestLevel):
			BiggestLevel = Newlvl
		if (Newlvl != lvl):
			ElintContacts[ship] = Newlvl
	if (BiggestLevel > 0):
		Elint.emit(true, BiggestLevel)
func UpdateVizRange(rang : float):
	var RadarRangeCollisionShape = $Radar/CollisionShape2D
	(RadarRangeCollisionShape.shape as CircleShape2D).radius = rang
func UpdateELINTTRange(rang : float):
	var ElintRangeCollisionShape = $Elint/CollisionShape2D
	#scalling collision
	(ElintRangeCollisionShape.shape as CircleShape2D).radius = rang
func UpdateCameraZoom(NewZoom : float) -> void:
	CamZoom = NewZoom

func Damage(amm : float) -> void:
	Cpt.GetStat("HULL").CurrentVelue -= amm
	if (IsDead()):
		MapPointerManager.GetInstance().RemoveShip(self)
		OnShipDestroyed.emit(self)
		#$Radar/CollisionShape2D.set_deferred("disabled", true)
		queue_free()
func IsDead() -> bool:
	return Cpt.GetStat("HULL").CurrentVelue <= 0

func SetCurrentPort(Port : MapSpot):
	CurrentPort = Port
	CanRefuel = Port.HasFuel()
	CanRepair = Port.HasRepair()
	CanUpgrade = Port.HasUpgrade()
	Cpt.CurrentPort = Port.GetSpotName()
	var dr = GetDroneDock().DockedDrones
	for g in dr:
		g.SetCurrentPort(Port)
func SetSpeed(Spd : float) -> void:
	GetShipAcelerationNode().position.x = Spd
func RemovePort():
	ShipDeparted.emit()
	CurrentPort = null
	InventoryManager.GetInstance().CancelUpgrades(Cpt)
	Cpt.CurrentPort = ""
	var dr = GetDroneDock().DockedDrones
	for g in dr:
		g.RemovePort()
func ShowingNotif() -> bool:
	return $Notifications.get_child_count() > 0

func OnStatLow(StatName : String) -> void:
	if (!LowStatsToNotifyAbout.has(StatName)):
		return
	StatLow.emit(StatName)
func HaltShip():
	Travelling = false
	#set_physics_process(false)
	
	SetSpeed(0)
	#$AudioStreamPlayer2D.stop()
	AccelerationChanged(0)
	#ChangingCourse = false
	ShipForceStopped.emit()

func AccelerationChanged(value: float) -> void:
	if (value <= 0):
		Travelling = false
		#set_physics_process(false)
		#$AudioStreamPlayer2D.stop()
		#$SmokeParticles.emitting = false
		ShipStopped.emit()
		#return
	else:
		if (Landing):
			LandingCanceled.emit(self)
			Landing = false
			#UpdateAltitude(10000)
		if (Altitude != 10000 and !TakingOff):
			TakeoffStarted.emit()
			TakingOff = true
		#if (Paused):
			#return
		#var Dat = ShipData.GetInstance()
		if (Cpt.GetStat("FUEL_TANK").GetCurrentValue() <= 0):
			HaltShip()
			PopUpManager.GetInstance().DoPopUp("You have run out of fuel.")
			return
			#set_physics_process(false)
			
		#$SmokeParticles.emitting = true
		Travelling = true
		#set_physics_process(true)
		ShipAccelerating.emit()
	
	
	var Audioween = create_tween()
	#Audioween.set_trans(Tween.TRANS_EXPO)
	#var ef = AudioServer.get_bus_effect(4, 0)
	Audioween.tween_property($AudioStreamPlayer2D, "pitch_scale", max(0.1,value / 2), 2)
	#ChangingCourse = true
	if (!$AudioStreamPlayer2D.playing):
		$AudioStreamPlayer2D.play()
	
	GetShipAcelerationNode().position.x = max(0,value * GetShipMaxSpeed())
	#var postween = create_tween()
	#postween.set_trans(Tween.TRANS_EXPO)
	#postween.tween_property($Aceleration, "position", Vector2(max(0,value * GetShipMaxSpeed()), 0), 2)
	
func AccelerationEnded(_value_changed: bool) -> void:
	pass
	#ChangingCourse = false
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
	var tw = create_tween()
	#tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "rotation", Rotation, 1)
	var piv = $PlayerShipSpr/ShadowPivot as Node2D
	piv.global_rotation = deg_to_rad(-90)
	var shadow = $PlayerShipSpr/ShadowPivot/Shadow as Node2D
	shadow.rotation = rotation
	for g in GetDroneDock().DockedDrones:
		g.ForceSteer(Rotation)
		
func ForceSteer(Rotation : float) -> void:
	var tw = create_tween()
	#tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "rotation", Rotation, 1)
	var piv = $PlayerShipSpr/ShadowPivot as Node2D
	piv.global_rotation = deg_to_rad(-90)
	var shadow = $PlayerShipSpr/ShadowPivot/Shadow as Node2D
	shadow.rotation = rotation
		
func ShipLookAt(pos : Vector2) -> void:
	look_at(pos)
	var piv = $PlayerShipSpr/ShadowPivot as Node2D
	piv.global_rotation = deg_to_rad(-90)
	var shadow = $PlayerShipSpr/ShadowPivot/Shadow as Node2D
	shadow.rotation = rotation
	for g in GetDroneDock().DockedDrones:
		g.global_rotation = global_rotation
	
func GetSteer() -> float:
	return rotation

func SetShipType(Ship : BaseShip):
	ShipType = Ship
	_UpdateShipIcon(Ship.TopIcon)

func _UpdateShipIcon(Tex : Texture) -> void:
	$PlayerShipSpr.texture = Tex
	$PlayerShipSpr/ShadowPivot/Shadow.texture = Tex

func _on_elint_area_entered(area: Area2D) -> void:
	if (area.get_parent() == self):
		return
	ElintContacts[area.get_parent()] = 0
	#Elint.emit(true, 1)
func _on_elint_area_exited(area: Area2D) -> void:
	if (area.get_parent() == self):
		return
	ElintContacts.erase(area.get_parent())
	Elint.emit(false, 0)
func GetShipBodyArea() -> Area2D:
	return $ShipBody
func GetShipRadarArea() -> Area2D:
	return $Radar
#func GetShipAnalayzerArea() -> Area2D:
	#return $Analyzer
func GetShipAcelerationNode() -> Node2D:
	return $Aceleration
func GetShipIcon() -> Node2D:
	return $PlayerShipSpr
func GetFuelReserves() -> float:
	return 0
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
func GetBattleStats() -> BattleShipStats:
	var stats = BattleShipStats.new()
	stats.Hull = Cpt.GetStat("HULL").GetCurrentValue()
	stats.Speed = Cpt.GetStat("SPEED").GetStat()
	stats.FirePower = Cpt.GetStat("FIREPOWER").GetStat()
	stats.ShipIcon = Cpt.ShipIcon
	stats.CaptainIcon = Cpt.CaptainPortrait
	stats.Name = GetShipName()
	return stats
func GetShipMaxSpeed() -> float:
	var Spd = Cpt.GetStatFinalValue("SPEED")
	if (Docked):
		Spd = Command.GetShipMaxSpeed()
	for g in GetDroneDock().DockedDrones:
		var DroneSpd = g.Cpt.GetStatFinalValue("SPEED")
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
func GetDroneDock():
	return $DroneDock
func IsFuelFull() -> bool:
	for g in GetDroneDock().DockedDrones:
		if (!g.IsFuelFull()):
			return false
	return Cpt.GetStat("FUEL_TANK").CurrentVelue == Cpt.GetStat("FUEL_TANK").GetStat()
func Refuel(_Amm : float) -> void:
	pass
