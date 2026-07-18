extends BaseDock
class_name PlayerDock

@export var DroneDockEventH : DroneDockEventHandler
@export var CaptainNotif : PackedScene


func _ready() -> void:
	$Line2D.visible = false
	DroneDockEventH.OnDockInstanced(get_parent())
	DroneDockEventH.connect("OnDroneDirectionChanged", DroneAimDirChanged)
	DroneDockEventH.connect("OnDroneArmed", DroneArmed)
	DroneDockEventH.connect("OnDroneDissarmed", DroneDissarmed)
	DroneDockEventH.connect("DroneLaunched", LaunchDrone)
	DroneDockEventH.connect("DroneRangeChanged", DroneRangeChanged)
	DroneDockEventH.connect("DroneDischarged", DroneDischarged)


func RemoveCaptain(Cap : Captain) -> void:
	for g in DockedShips:
		if (g.Cpt == Cap):
			UndockShip(g)
			g.Kill()
			return

func GetSaveData() -> Array[DroneSaveData]:
	var saved : Array[DroneSaveData]
	for g in DockedShips:
		saved.append(g.GetSaveData())
	#for g in FlyingDrones:
		#saved.append(g.GetSaveData())
	return saved


func CaptiveDischarged(C : HostileShip) -> void:
	DroneRemoved.emit()
	UndockCaptive(C)


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

func AddShip(Ship : MapShip, Notify : bool = true) -> void:
	if (Notify):
		var notif = CaptainNotif.instantiate() as CaptainNotification
		notif.SetCaptain(Ship.Cpt)
		Ingame_UIManager.GetInstance().AddUI(notif, true)
	Ship.connect("OnShipDestroyed", DroneDischarged)
	super(Ship, Notify)

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
		UndockShip(Dr)
		Dr.global_rotation = $Line2D.global_rotation
		Dr.global_position = global_position
		var RefilAmm = Dr.Cpt.GetStatCurrentValue(STAT_CONST.STATS.FUEL_TANK) - ($Line2D.get_point_position(1).x / 10 / Dr.Cpt.GetStatFinalValue(STAT_CONST.STATS.FUEL_EFFICIENCY))
		Dr.Cpt.RefillResource(STAT_CONST.STATS.FUEL_TANK, abs(RefilAmm))
		Dr.EnableDrone()

func AddShipToHierarchy(Ship : MapShip) -> void:
	super(Ship)
	DroneDockEventH.OnDroneAdded(Ship, get_parent())

func DockShip(ship : MapShip):
	super(ship)
	
	if (RadioSpeaker.GetInstance() != null):
		RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.LANDING_END)
	ship.ToggleLight(false)
	ship.ToggleRadar(ship.Command.RadarShape.Working)
	
	DroneDockEventH.OnDroneDocked(ship, ship.Command)
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

func UndockShip(ship : MapShip) -> void:
	super(ship)
	ship.ToggleLight(true)
	DroneDockEventH.OnDroneUnDocked(ship, get_parent())
	DroneRemoved.emit()


func UpdateCameraZoom(NewZoom : float) -> void:
	$Line2D.width =  2 / NewZoom
