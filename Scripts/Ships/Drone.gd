extends MapShip

class_name Drone

signal DroneReturning

func  _ready() -> void:
	super()
	#UpdateVizRange(Cpt.GetStatFinalValue(STAT_CONST.STATS.VISUAL_RANGE))
	#UpdateELINTTRange(Cpt.GetStatFinalValue(STAT_CONST.STATS.ELINT))
	Paused = SimulationManager.IsPaused()

#func _exit_tree() -> void:
	##InventoryManager.GetInstance().OnCharacterRemoved(Cpt)
	#MapPointerManager.GetInstance().RemoveShip(self)

func Steer(Rotation : float) -> void:
	if (CommingBack or Docked):
		return
	super(Rotation)

func AccelerationChanged(value: float) -> void:
	if (CommingBack or Docked):
		return
	super(value)

func EnableDrone():
	#set_physics_process(true)`
	if (Altitude != 10000):
		if (Landing):
			LandingCanceled.emit()
			Landing = false
		TakeoffStarted.emit()
		TakingOff = true
	$AudioStreamPlayer2D.play()
	GetShipAcelerationNode().position.x = Cpt.GetStatFinalValue(STAT_CONST.STATS.SPEED)
	#ToggleRadar()
	#$ShipBody/CollisionShape2D.set_deferred("disabled", false)
func DissableDrone():
	#GetShipIcon().rotation = 0.0
	rotation = 0
	$AudioStreamPlayer2D.stop()
	#set_physics_process(false)
	#ToggleRadar()
	#$ShipBody/CollisionShape2D.set_deferred("disabled", true)
func ReturnToBase():
	SetSpeed(GetShipMaxSpeed())
	#rotation = 0.0
	CommingBack = true
	DroneReturning.emit()
	#Docked = false

func SetCurrentPort(Port : MapSpot):
	super(Port)
	var dr = GetDroneDock().DockedDrones
	for g in dr:
		g.SetCurrentPort(Port)
func RemovePort():
	super()
	var dr = GetDroneDock().DockedDrones
	for g in dr:
		g.RemovePort()
func _on_return_sound_trigger_area_entered(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip and CommingBack):
		var plship = area.get_parent() as PlayerShip
		plship.GetDroneDock().PlayReturnSound()
func _on_ship_body_area_entered(area: Area2D) -> void:
	if (Docked):
		return
	if (area.get_parent() is MapSpot and !CommingBack):
		var spot = area.get_parent() as MapSpot
		if (spot.CurrentlyVisiting):
			return
		if (!spot.Seen):
			spot.OnSpotSeenByDrone()
		spot.OnSpotVisitedByDrone()
	else : if (area.get_parent() == Command and CommingBack):
		var plship = area.get_parent() as MapShip
		plship.GetDroneDock().DockDrone(self, true)
		var MyDroneDock = GetDroneDock()
		for g in MyDroneDock.DockedDrones:
			MyDroneDock.UndockDrone(g, false)
			plship.GetDroneDock().DockDrone(g, false)
		for g in MyDroneDock.FlyingDrones:
			g.Command = plship
		CommingBack = false
func _on_elint_area_entered(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		return
	super(area)
func _on_elint_area_exited(area: Area2D) -> void:
	if (area.get_parent() is PlayerShip or area.get_parent() is Drone):
		return
	super(area)

func GetSaveData() -> DroneSaveData:
	var dat = DroneSaveData.new()
	dat.CommingBack = CommingBack
	dat.Cpt = Cpt
	dat.Docked = Docked
	dat.Pos = global_position
	dat.Rot = global_rotation
	for g in GetDroneDock().DockedDrones:
		dat.DockedDrones.append(g.GetSaveData())
	for g in GetDroneDock().FlyingDrones:
		dat.DockedDrones.append(g.GetSaveData())
	return dat
