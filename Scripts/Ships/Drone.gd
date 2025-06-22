extends PlayerDrivenShip

class_name Drone

signal DroneReturning

func  _ready() -> void:
	super()
	ShipContoller.GetInstance().RegisterSelf(self)

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
	#if (Altitude != 10000):
		#if (Landing):
			#LandingCanceled.emit(self)
			#Landing = false
		#TakeoffStarted.emit()
		#TakingOff = true
	#$AudioStreamPlayer2D.play()
	#var Speed = (Cpt.GetStatFinalValue(STAT_CONST.STATS.THRUST) * 1000) / Cpt.GetStatFinalValue(STAT_CONST.STATS.WEIGHT)
	#GetShipAcelerationNode().position.x =  Speed / 360
	#ToggleRadar()
	#$ShipBody/CollisionShape2D.set_deferred("disabled", false)
	pass


func Regroup(NewCommander : MapShip):
	RegroupTarget = NewCommander
	SetSpeed(GetShipMaxSpeed())
	#rotation = 0.0
	CommingBack = true
	DroneReturning.emit()
	#Docked = false

func _physics_process(delta: float) -> void:
	super(delta)

func _on_return_sound_trigger_area_entered(area: Area2D) -> void:
	if (area.get_parent() == RegroupTarget and CommingBack):
		RadioSpeaker.GetInstance().PlaySound(RadioSpeaker.RadioSound.APROACHING)
		
func BodyEnteredBody(Body: Area2D) -> void:
	if (Docked):
		return
	super(Body)

func GetSaveData() -> DroneSaveData:
	var dat = DroneSaveData.new()
	dat.CommingBack = CommingBack
	dat.RegroupTargetName = RegroupTarget.GetShipName()
	dat.Cpt = Cpt
	dat.Docked = Docked
	dat.Pos = global_position
	dat.Rot = global_rotation
	dat.Speed = GetShipSpeed()
	dat.RepairParts = Cpt.Repair_Parts
	dat.TempName = Cpt.TempName
	dat.Altitude = Altitude
	for g in GetDroneDock().DockedDrones:
		dat.DockedDrones.append(g.GetSaveData())

	return dat
