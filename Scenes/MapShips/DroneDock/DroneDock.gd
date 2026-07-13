extends BaseDock
class_name PlayerDock
#@export var DroneScene : PackedScene

@export var DroneDockEventH : DroneDockEventHandler
@export_file("*.tscn") var Ship_Scene : String
@export var CaptainNotif : PackedScene

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
	for g in DockedShips:
		if (g.Fuel < 50):
			return true
	return false



func RemoveCaptain(Cap : Captain) -> void:
	for g in DockedShips:
		if (g.Cpt == Cap):
			UndockDrone(g)
			g.Kill()
			return

func ClearAllDrones() -> void:
	var Drones = DockedShips.duplicate()
	for g in Drones:
		DroneDisharged(g)
		g.Kill()
	#for g in FlyingDrones:
		#DroneDisharged(g)
		#g.Kill()

func GetSaveData() -> Array[DroneSaveData]:
	var saved : Array[DroneSaveData]
	for g in DockedShips:
		saved.append(g.GetSaveData())
	#for g in FlyingDrones:
		#saved.append(g.GetSaveData())
	return saved

func DroneDisharged(Dr : MapShip):

	DroneRemoved.emit()
	UndockDrone(Dr)
	#if (FlyingDrones.has(Dr)):
		#FlyingDrones.erase(Dr)

func CaptiveDischarged(C : HostileShip) -> void:
	DroneRemoved.emit()
	UndockCaptive(C)

func AddRecruit(Cpt : Captain, _Notify : bool = true) -> MapShip:
	#if (Notify):
		#PopUpManager.GetInstance().DoFadeNotif("{0} drahma added".format([Cpt.ProvidingFunds]))
		#Ingame_UIManager.GetInstance().PlayDiag(["I will be providing my sum of {0} drahma towards the cause captain. Hope it provides a small help in these dire circumstanses".format([Cpt.ProvidingFunds])], Cpt.CaptainPortrait, Cpt.CaptainName)
	#
	World.GetInstance().PlayerWallet.AddFunds(Cpt.ProvidingFunds)
	var ship = (load(Ship_Scene) as PackedScene).instantiate() as PlayerDrivenShip
	ship.Cpt = Cpt
	AddDrone(ship, false)
	for Crew in Cpt.ProvidingCaptains:
		var NewShip = (load(Ship_Scene) as PackedScene).instantiate() as PlayerDrivenShip
		NewShip.Cpt = Crew
		AddDrone(NewShip, false)
	return ship

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



func DoCaptiveThing(Captive : HostileShip) -> void:
	var CaptiveParent = Captive.get_parent()
	CaptiveParent.remove_child(Captive)
	Captive.Captured = true
	CaptiveParent.add_child(Captive)
	DockCaptive(Captive)
	Commander.GetInstance().UnregisterSelf(Captive)



func AddDrone(Drne : PlayerDrivenShip, Notify : bool = true) -> void:
	#var drone = DroneScene.instantiate()
	if (Notify):
		var notif = CaptainNotif.instantiate() as CaptainNotification
		notif.SetCaptain(Drne.Cpt)
		Ingame_UIManager.GetInstance().AddUI(notif, true)
	Drne.connect("OnShipDestroyed", DroneDisharged)
	#ShipData.GetInstance().ApplyCaptainStats([Drne.Cpt.GetStat(STAT_CONST.STATS.INVENTORY_SPACE)])
	#Inventory.GetInstance().OnCharacterAdded(Drne.Cpt)
	AddDroneToHierarchy(Drne)



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

func LaunchDrone(Dr : PlayerDrivenShip, Target : MapShip) -> void:
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

func AddDroneToHierarchy(drone : PlayerDrivenShip):
	get_parent().get_parent().add_child(drone)
	DockDrone(drone)
	DroneDockEventH.OnDroneAdded(drone, get_parent())

func DockDrone(drone : PlayerDrivenShip, playsound : bool = false):
	if (playsound):
		RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.LANDING_END)
	#FlyingDrones.erase(drone)
	DockedShips.append(drone)
	#drone.DissableDrone()

	var Command = get_parent() as MapShip
	drone.ToggleLight(false)
	drone.Command = Command
	DroneDockEventH.OnDroneDocked(drone, Command)

	var docks = $DroneSpots.get_children()

	var pos : Vector2
	var Offset = 2
	for g in docks.size() + 1:
		if (Helper.is_even(g)):
			pos = Vector2(-Offset, -Offset)
		else:
			pos = Vector2(-Offset, Offset)
			Offset += 2

	var trans = RemoteTransform2D.new()
	trans.update_rotation = false
	$DroneSpots.add_child(trans)
	trans.position = pos
	drone.ForceSteer(get_parent().rotation)
	trans.remote_path = drone.get_path()
	drone.Docked = true

	drone.SetShipPosition(trans.global_position)

	if (drone.Altitude != Command.Altitude):
		drone.TargetAltitude = Command.Altitude
		#drone.InitialiseAltitudeMatching()

	if (Command.GetShipSpeed() > 0):
		Command.AccelerationChanged(Command.GetShipSpeed() / Command.GetShipMaxSpeed())

	if (Command.CurrentPort != null and Command.CurrentPort != drone.CurrentPort):
		drone.SetCurrentPort(Command.CurrentPort)
		Command.CurrentPort.OnSpotAproached(drone)
	drone.ToggleRadar(Command.RadarShape.Working)

	DroneAdded.emit()



func DockCaptive(Captive : HostileShip) -> void:
	Captives.append(Captive)
	Captive.Command = get_parent()

	var docks = $DroneSpots.get_children()

	var pos : Vector2
	var Offset = 10
	for g in docks.size() + 1:
		if (Helper.is_even(g)):
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

func UndockDrone(drone : PlayerDrivenShip):
	DockedShips.erase(drone)

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
		var Offset = 5
		for g in DockSpot + 1:
			if (Helper.is_even(g)):
				pos = Vector2(-Offset, -Offset)
			else:
				pos = Vector2(-Offset, Offset)
				Offset += 5

		$DroneSpots.get_child(DockSpot).position = pos

func UpdateCameraZoom(NewZoom : float) -> void:
	$Line2D.width =  2 / NewZoom
