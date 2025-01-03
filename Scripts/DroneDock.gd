extends Area2D
class_name DroneDock
#@export var DroneScene : PackedScene

@export var DroneDockEventH : DroneDockEventHandler

@export var CaptainNotif : PackedScene

@export var LandedVoiceLines : Array[AudioStream]
@export var ReturnVoiceLines : Array[AudioStream]
@export var TakeoffVoiceLines : Array[AudioStream]

var DockedDrones : Array[Drone]
var FlyingDrones : Array[Drone]

func _ready() -> void:
	$Line2D.visible = false
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
	for g in DockedDrones:
		fuelneeded -= g.Cpt.GetStat("FUEL_TANK").CurrentVelue
		if (fuelneeded <= 0):
			return true
	return false

func SyphonFuelFromDrones(amm : float) -> void:
	for g in DockedDrones:
		if (g.Cpt.GetStat("FUEL_TANK").CurrentVelue > amm):
			g.Cpt.GetStat("FUEL_TANK").CurrentVelue -= amm
			return
		else:
			amm -= g.Cpt.GetStat("FUEL_TANK").CurrentVelue
			g.Cpt.GetStat("FUEL_TANK").CurrentVelue = 0

func GetDroneFuel() -> float:
	var fuel : float = 0
	for g in DockedDrones:
		fuel += g.Cpt.GetStat("FUEL_TANK").CurrentVelue
	return fuel

func HasSpace() -> bool:
	return DockedDrones.size() + FlyingDrones.size() < 6
	
func ClearAllDrones() -> void:
	for g in DockedDrones:
		DroneDisharged(g)
	for g in FlyingDrones:
		DroneDisharged(g)

func GetSaveData() -> Array[DroneSaveData]:
	var saved : Array[DroneSaveData]
	for g in DockedDrones:
		saved.append(g.GetSaveData())
	for g in FlyingDrones:
		saved.append(g.GetSaveData())
	return saved
	
func LoadSaveData( Dat : Array[DroneSaveData]) -> void:
	for g in Dat:
		var dr = AddCaptain(g.Cpt, false)
		dr.Cpt.GetStat("FUEL_TANK").CurrentVelue = g.Fuel
		if (!g.Docked):
			UndockDrone(dr)
			dr.EnableDrone()
			dr.global_position = g.Pos
			dr.global_rotation = g.Rot
			dr.CommingBack = g.CommingBack
	
func GetCaptains() -> Array[Captain]:
	var cptns : Array[Captain]
	for g in DockedDrones:
		cptns.append(g.Cpt)
	for g in FlyingDrones:
		cptns.append(g.Cpt)
	return cptns
	
func DroneDisharged(Dr : Drone):
	if (DockedDrones.has(Dr)):
		DockedDrones.erase(Dr)
	if (FlyingDrones.has(Dr)):
		FlyingDrones.erase(Dr)
	ShipData.GetInstance().RemoveCaptainStats([Dr.Cpt.GetStat("INVENTORY_CAPACITY")])
	Inventory.GetInstance().UpdateSize()
	MapPointerManager.GetInstance().RemoveShip(Dr)
	Dr.queue_free()

func AddCaptain(Cpt : Captain, Notify : bool = true) -> Drone:
	var ship = (load("res://Scenes/drone.tscn") as PackedScene).instantiate() as Drone
	ship.Cpt = Cpt
	AddDrone(ship, Notify)
	return ship
	
func AddDrone(Drne : Drone, Notify : bool = true) -> void:
	#var drone = DroneScene.instantiate()
	if (Notify):
		var notif = CaptainNotif.instantiate() as CaptainNotification
		notif.SetCaptain(Drne.Cpt)
		Ingame_UIManager.GetInstance().AddUI(notif, false, true)
	Drne.connect("OnShipDestroyed", DroneDisharged)
	ShipData.GetInstance().ApplyCaptainStats([Drne.Cpt.GetStat("INVENTORY_CAPACITY")])
	Inventory.GetInstance().UpdateSize()
	AddDroneToHierarchy(Drne)
	var pl = get_parent() as MapShip
	if (pl.CurrentPort != null):
		Drne.SetCurrentPort(pl.CurrentPort)
	if (!pl.Detectable):
		Drne.ToggleRadar()
func PlayLandingSound()-> void:
	var sound = AudioStreamPlayer.new()
	sound.stream = LandedVoiceLines.pick_random()
	sound.bus = "UI"
	add_child(sound, true)
	sound.connect("finished", SoundEnded)
	sound.volume_db = -10
	sound.play()
	
func PlayReturnSound() -> void:
	var sound = AudioStreamPlayer.new()
	sound.stream = ReturnVoiceLines.pick_random()
	sound.bus = "UI"
	add_child(sound, true)
	sound.connect("finished", SoundEnded)
	sound.volume_db = -10
	sound.play()

func PlayTakeoffSound() -> void:
	var sound = AudioStreamPlayer.new()
	sound.stream = TakeoffVoiceLines.pick_random()
	sound.bus = "UI"
	add_child(sound, true)
	sound.connect("finished", SoundEnded)
	sound.volume_db = -10
	sound.play()

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
		var fueltoconsume = $Line2D.get_point_position(1).x / 10 / Dr.Cpt.GetStatValue("FUEL_EFFICIENCY")
		var neededfuel = fueltoconsume - Dr.Cpt.GetStat("FUEL_TANK").CurrentVelue
		if (neededfuel > 0):
			if (ShipData.GetInstance().GetStat("FUEL").CurrentVelue < neededfuel):
				return
			ShipData.GetInstance().ConsumeResource("FUEL", neededfuel)
		PlayTakeoffSound()
		UndockDrone(Dr)
		Dr.global_rotation = $Line2D.global_rotation
		Dr.global_position = global_position
		Dr.Cpt.GetStat("FUEL_TANK").CurrentVelue = $Line2D.get_point_position(1).x / 10 / Dr.Cpt.GetStatValue("FUEL_EFFICIENCY")
		Dr.EnableDrone()
	
func AddDroneToHierarchy(drone : Drone):
	drone.Command = get_parent()
	get_parent().get_parent().add_child(drone)
	DockDrone(drone)
	DroneDockEventH.OnDroneAdded(drone, get_parent())

func DockDrone(drone : Drone, playsound : bool = false):
	if (playsound):
		PlayLandingSound()
	FlyingDrones.erase(drone)
	DockedDrones.append(drone)
	drone.DissableDrone()
	
	DroneDockEventH.OnDroneDocked(drone, get_parent())
	
	var docks = $DroneSpots.get_children()
	for g in docks.size():
		if (docks[g].get_child_count() > 0):
			continue
		var dock = docks[g]
		var trans = RemoteTransform2D.new()
		trans.update_rotation = false
		dock.add_child(trans)
		trans.remote_path = drone.get_path()
		drone.Docked = true
		if ($"..".Landing or $"..".Landed()):
			drone.LandingStarted.emit()
			drone.Landing = true
		return

func UndockDrone(drone : Drone):
	DockedDrones.erase(drone)
	FlyingDrones.append(drone)
	DroneDockEventH.OnDroneUnDocked(drone, get_parent())
	var docks = $DroneSpots.get_children()
	for g in docks.size():
		if (docks[g].get_child_count() > 0):
			var trans = docks[g].get_child(0) as RemoteTransform2D
			if (trans.remote_path == drone.get_path()):
				trans.free()
				drone.Docked = false
				return
