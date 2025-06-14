extends Area2D
class_name DroneDock
#@export var DroneScene : PackedScene

@export var DroneDockEventH : DroneDockEventHandler

@export var CaptainNotif : PackedScene

var DockedDrones : Array[Drone]
var Captives : Array[HostileShip]

signal DroneAdded
signal DroneRemoved
#var FlyingDrones : Array[Drone]

func _ready() -> void:
	$Line2D.visible = false
	DroneDockEventH.OnDockInstanced(get_parent())
	DroneDockEventH.connect("OnDroneDirectionChanged", DroneAimDirChanged)
	DroneDockEventH.connect("OnDroneArmed", DroneArmed)
	DroneDockEventH.connect("OnDroneDissarmed", DroneDissarmed)
	DroneDockEventH.connect("DroneLaunched", LaunchDrone)
	DroneDockEventH.connect("DroneRangeChanged", DroneRangeChanged)
	DroneDockEventH.connect("DroneDischarged", DroneDisharged)
func AnyDroneNeedsFuel() -> bool:
	for g in DockedDrones:
		if (g.Fuel < 50):
			return true
	return false

func DronesHaveFuel(f : float) -> bool:
	var fuelneeded = f
	for g in GetDockedShips():
		fuelneeded -= g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		if (fuelneeded <= 0):
			return true
	return false

func SyphonFuelFromDrones(amm : float) -> void:
	for g in GetDockedShips():
		if (g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) > amm):
			g.Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, amm)
			return
		else:
			var FuelAmm = g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
			amm -= FuelAmm
			g.Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, FuelAmm)

func GetDroneFuel() -> float:
	var fuel : float = 0
	for g in DockedDrones:
		fuel += g.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
	return fuel

func RemoveCaptain(Cap : Captain) -> void:
	for g in DockedDrones:
		if (g.Cpt == Cap):
			UndockDrone(g)
			g.Kill()
			return
		
func ClearAllDrones() -> void:
	var Drones = DockedDrones.duplicate()
	for g in Drones:
		DroneDisharged(g)
		g.Kill()
	#for g in FlyingDrones:
		#DroneDisharged(g)
		#g.Kill()
		
func GetSaveData() -> Array[DroneSaveData]:
	var saved : Array[DroneSaveData]
	for g in DockedDrones:
		saved.append(g.GetSaveData())
	#for g in FlyingDrones:
		#saved.append(g.GetSaveData())
	return saved
	
func GetCaptains() -> Array[Captain]:
	var cptns : Array[Captain]
	for g in DockedDrones:
		cptns.append(g.Cpt)
	#for g in FlyingDrones:
		#cptns.append(g.Cpt)
	return cptns
	
func DroneDisharged(Dr : MapShip):

	DroneRemoved.emit()
	UndockDrone(Dr)
	#if (FlyingDrones.has(Dr)):
		#FlyingDrones.erase(Dr)

func CaptiveDischarged(C : HostileShip) -> void:
	DroneRemoved.emit()
	UndockCaptive(C)

func AddRecruit(Cpt : Captain, _Notify : bool = true) -> void:
	#if (Notify):
		#PopUpManager.GetInstance().DoFadeNotif("{0} drahma added".format([Cpt.ProvidingFunds]))
		#Ingame_UIManager.GetInstance().PlayDiag(["I will be providing my sum of {0} drahma towards the cause captain. Hope it provides a small help in these dire circumstanses".format([Cpt.ProvidingFunds])], Cpt.CaptainPortrait, Cpt.CaptainName)
	#
	World.GetInstance().PlayerWallet.AddFunds(Cpt.ProvidingFunds)
	var ship = (load("res://Scenes/MapShips/drone.tscn") as PackedScene).instantiate() as Drone
	ship.Cpt = Cpt
	AddDrone(ship, false)
	for Crew in Cpt.ProvidingCaptains:
		var NewShip = (load("res://Scenes/MapShips/drone.tscn") as PackedScene).instantiate() as Drone
		NewShip.Cpt = Crew
		AddDrone(NewShip, false)

func AddCaptive(Captive : HostileShip) -> void:
	
	#var pl = get_parent() as MapShip
	#if (pl.CurrentPort != null):
		#World.GetInstance().PlayerWallet.AddFunds(Captive.Cpt.ProvidingFunds * 2)
		#Captive.Evaporate()
		#return
		
	#TODO new signal for captives
	Captive.connect("OnShipDestroyed", CaptiveDischarged)
	
	call_deferred("DoCaptiveThing", Captive)
	#ShipData.GetInstance().ApplyCaptainStats([Drne.Cpt.GetStat(STAT_CONST.STATS.INVENTORY_SPACE)])
	#Inventory.GetInstance().OnCharacterAdded(Drne.Cpt)

func ReleaseCaptive(Captive : HostileShip) -> void:
	UndockCaptive(Captive)
	Captive.Captured = false
	Commander.GetInstance().RegisterSelf(Captive)

func GetDockedShips() -> Array[MapShip]:
	var Ships : Array[MapShip]
	Ships.append_array(DockedDrones)
	Ships.append_array(Captives)
	return Ships

func DoCaptiveThing(Captive : HostileShip) -> void:
	var CaptiveParent = Captive.get_parent()
	CaptiveParent.remove_child(Captive)
	Captive.Captured = true
	CaptiveParent.add_child(Captive)
	DockCaptive(Captive)
	Commander.GetInstance().UnregisterSelf(Captive)



func AddDrone(Drne : Drone, Notify : bool = true) -> void:
	#var drone = DroneScene.instantiate()
	if (Notify):
		var notif = CaptainNotif.instantiate() as CaptainNotification
		notif.SetCaptain(Drne.Cpt)
		Ingame_UIManager.GetInstance().AddUI(notif, true)
	Drne.connect("OnShipDestroyed", DroneDisharged)
	#ShipData.GetInstance().ApplyCaptainStats([Drne.Cpt.GetStat(STAT_CONST.STATS.INVENTORY_SPACE)])
	#Inventory.GetInstance().OnCharacterAdded(Drne.Cpt)
	AddDroneToHierarchy(Drne)
	var pl = get_parent() as MapShip
	if (pl.CurrentPort != null):
		Drne.SetCurrentPort(pl.CurrentPort)
		pl.CurrentPort.OnSpotAproached(Drne)
	if (!pl.Detectable):
		Drne.ToggleRadar()

func SoundEnded() -> void:
	for g in $Sounds.get_child_count():
		if (!($Sounds.get_child(g) as AudioStreamPlayer).playing):
			$Sounds.get_child(g).queue_free()
			return
		
func DroneArmed(Target : MapShip) -> void:
	if (Target == get_parent()):
		$Line2D.visible = true

func DroneDissarmed(Target : MapShip) -> void:
	if (Target == get_parent()):
		$Line2D.visible = false

func DroneAimDirChanged(NewDir : float, Target : MapShip) -> void:
	if (Target == get_parent()):
		$Line2D.rotation = NewDir / 10
	
func DroneRangeChanged(NewRange : float, Target : MapShip) -> void:
	if (Target == get_parent()):
		$Line2D.set_point_position(1, Vector2(NewRange, 0))
	
func LaunchDrone(Dr : Drone, Target : MapShip) -> void:
	if (Target == get_parent()):
		var fueltoconsume = $Line2D.get_point_position(1).x / 10 / Dr.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY)
		var neededfuel = fueltoconsume - Dr.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK)
		if (neededfuel > 0):
			#if (Target is Drone):
			if (Target.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) < neededfuel):
				PopUpManager.GetInstance().DoFadeNotif("Not enough fuel to perform operation.")
				return
			Target.Cpt.ConsumeResource(STAT_CONST.STATS.FUEL_TANK, neededfuel)
		#PlayTakeoffSound()
		RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.LIFTOFF)
		UndockDrone(Dr)
		Dr.global_rotation = $Line2D.global_rotation
		Dr.global_position = global_position
		var RefilAmm = Dr.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) - ($Line2D.get_point_position(1).x / 10 / Dr.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY))
		Dr.Cpt.RefillResource(STAT_CONST.STATS.FUEL_TANK, abs(RefilAmm))
		Dr.EnableDrone()

func AddDroneToHierarchy(drone : Drone):
	get_parent().get_parent().add_child(drone)
	DockDrone(drone)
	DroneDockEventH.OnDroneAdded(drone, get_parent())

func DockDrone(drone : Drone, playsound : bool = false):
	if (playsound):
		RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.LANDING_END)
	#FlyingDrones.erase(drone)
	DockedDrones.append(drone)
	#drone.DissableDrone()
	
	var Command = get_parent() as MapShip
	
	drone.Command = Command
	DroneDockEventH.OnDroneDocked(drone, Command)
	
	var docks = $DroneSpots.get_children()
	
	var pos : Vector2
	var Offset = 10
	for g in docks.size() + 1:
		if (is_even(g)):
			pos = Vector2(-Offset, -Offset)
		else:
			pos = Vector2(-Offset, Offset)
			Offset += 10
	drone.ToggleLight(false)
	var trans = RemoteTransform2D.new()
	trans.update_rotation = false
	$DroneSpots.add_child(trans)
	trans.position = pos
	drone.ForceSteer(get_parent().rotation)
	trans.remote_path = drone.get_path()
	drone.Docked = true
	
	drone.SetShipPosition(trans.global_position)
	
	if (drone.Altitude != Command.Altitude):
		drone.MatchingAltitudeStarted.emit()
		drone.MatchingAltitude = true
	
	if (Command.GetShipSpeed() > 0):
		Command.AccelerationChanged(Command.GetShipSpeed() / Command.GetShipMaxSpeed())
	
	DroneAdded.emit()
		
func is_even(number: int) -> bool:
	return number % 2 == 0
		
func DockCaptive(Captive : HostileShip) -> void:
	Captives.append(Captive)
	Captive.Command = get_parent()
	
	var docks = $DroneSpots.get_children()
	
	var pos : Vector2
	var Offset = 10
	for g in docks.size() + 1:
		if (is_even(g)):
			pos = Vector2(-Offset, -Offset)
		else:
			pos = Vector2(-Offset, Offset)
			Offset += 10

	var trans = RemoteTransform2D.new()
	trans.update_rotation = false
	$DroneSpots.add_child(trans)
	trans.position = pos
	Captive.ForceSteer(get_parent().rotation)
	trans.remote_path = Captive.get_path()
	Captive.Docked = true
	Captive.SetShipPosition(trans.global_position)
	
func UndockCaptive(Captive : HostileShip):
	Captives.erase(Captive)

	Captive.Command = null

	var docks = $DroneSpots.get_children()
	for g in docks:
		var trans = g as RemoteTransform2D
		if (trans.remote_path == Captive.get_path()):
			trans.free()
			Captive.Docked = false
			break
	RepositionDocks()
	
	DroneRemoved.emit()

func UndockDrone(drone : Drone):
	DockedDrones.erase(drone)

	drone.Command = null
	drone.ToggleLight(true)
	DroneDockEventH.OnDroneUnDocked(drone, get_parent())
	var docks = $DroneSpots.get_children()
	for g in docks:
		var trans = g as RemoteTransform2D
		if (trans.remote_path == drone.get_path()):
			trans.free()
			drone.Docked = false
			break
	RepositionDocks()
	
	DroneRemoved.emit()
	
func RepositionDocks() -> void:
	
	for DockSpot in $DroneSpots.get_children().size():
		var pos : Vector2
		var Offset = 10
		for g in DockSpot + 1:
			if (is_even(g)):
				pos = Vector2(-Offset, -Offset)
			else:
				pos = Vector2(-Offset, Offset)
				Offset += 10
		
		$DroneSpots.get_child(DockSpot).position = pos

func UpdateCameraZoom(NewZoom : float) -> void:
	$Line2D.width =  2 / NewZoom
