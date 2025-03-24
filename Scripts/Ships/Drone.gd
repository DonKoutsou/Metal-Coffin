extends MapShip

class_name Drone

signal DroneReturning

func  _ready() -> void:
	super()
	Paused = SimulationManager.IsPaused()
	ShipContoller.GetInstance().RegisterSelf(self)

#func _exit_tree() -> void:
	##InventoryManager.GetInstance().OnCharacterRemoved(Cpt)
	#MapPointerManager.GetInstance().RemoveShip(self)

func Steer(Rotation : float) -> void:
	if (CommingBack or Docked):
		return
	super(Rotation)

func AccelerationChanged(value: float) -> void:
	if (Docked):
		return
	super(value)

func EnableDrone():
	#set_physics_process(true)`
	if (Altitude != 10000):
		if (Landing):
			LandingCanceled.emit(self)
			Landing = false
		TakeoffStarted.emit()
		TakingOff = true
	#$AudioStreamPlayer2D.play()
	GetShipAcelerationNode().position.x = Cpt.GetStatFinalValue(STAT_CONST.STATS.SPEED)
	#ToggleRadar()
	#$ShipBody/CollisionShape2D.set_deferred("disabled", false)
	
func DissableDrone():
	#GetShipIcon().rotation = 0.0
	rotation = 0
	#$AudioStreamPlayer2D.stop()
	#set_physics_process(false)
	#ToggleRadar()
	#$ShipBody/CollisionShape2D.set_deferred("disabled", true)
	
func Regroup(NewCommander : MapShip):
	Command = NewCommander
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
		RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.APROACHING)
		
func BodyEnteredBody(Body: Area2D) -> void:
	if (Docked):
		return
	var Parent = Body.get_parent()
	if (Parent is MapSpot):
		SetCurrentPort(Parent)
		Parent.OnSpotAproached(self)
	else : if (Parent == Command and CommingBack):
		var plship = Body.get_parent() as MapShip
		plship.GetDroneDock().DockDrone(self, true)
		var MyDroneDock = GetDroneDock()
		for g in MyDroneDock.DockedDrones:
			MyDroneDock.UndockDrone(g)
			plship.GetDroneDock().DockDrone(g, false)
		#for g in MyDroneDock.FlyingDrones:
			#g.Command = plship
		CommingBack = false
func BodyEnteredElint(Body: Area2D) -> void:
	if (Body.get_parent() is PlayerShip or Body.get_parent() is Drone):
		return
	super(Body)
func BodyLeftElint(Body: Area2D) -> void:
	if (Body.get_parent() is PlayerShip or Body.get_parent() is Drone):
		return
	super(Body)

func GetSaveData() -> DroneSaveData:
	var dat = DroneSaveData.new()
	dat.CommingBack = CommingBack
	dat.Cpt = Cpt
	dat.Docked = Docked
	dat.Pos = global_position
	dat.Rot = global_rotation
	for g in GetDroneDock().DockedDrones:
		dat.DockedDrones.append(g.GetSaveData())
	
	#TODO to fix flying drones not saved
	#for g in GetDroneDock().FlyingDrones:
		#dat.DockedDrones.append(g.GetSaveData())
	return dat
