extends Control
class_name MissileTab

var Armed = false
@export var MissileDockEventH : MissileDockEventHandler
@export var DroneDockEventH : DroneDockEventHandler

@export_group("Nodes")
@export var MissileSelectLight : Light
@export var AngleSelectLight : Light
@export var RangeText : Label
@export var SelectedMissileText : Label
@export var TouchStopper : Control
#var Missiles : Array[MissileItem]

signal MissileLaunched

var CurrentlySelectedMissile

var SelectedIndex : int

var ConnectedShip : MapShip

var Missiles : Dictionary

var AvailableMissiles : Array[MissileItem]

var Showing = false

func UpdateConnectedShip(Ship : MapShip) -> void:
	if (!Missiles.has(Ship)):
		var MissileAr : Array[MissileItem] = []
		Missiles[Ship] = MissileAr
		Ship.connect("OnShipDestroyed", OnShipDest)
	if (Armed):
		DissarmMiss()
	ConnectedShip = Ship
	call_deferred("UpdateMissileSelect")

#HACK TO MAKE SURE UI IS INITIALISED IN TIME.
func Initialise() -> void:
	DroneDockEventH.connect("DroneAdded", RegisterShip)
	MissileDockEventH.connect("MissileAdded", MissileAdded)
	MissileDockEventH.connect("MissileRemoved", MissileRemoved)

func _ready() -> void:
	#$Control/Control/Dissarm.ToggleDissable(true)
	#$Control/Control/Launch.ToggleDissable(true)
	Initialise()
	#visible = false

func FindOwner(Mis : MissileItem) -> Captain:
	for g in Missiles.keys():
		if (Missiles[g].has(Mis)):
			return g.Cpt
	return null

var d = 0.3

func _physics_process(delta: float) -> void:
	d -= delta
	if (d > 0):
		return
	d = 0.3
	if (ConnectedShip != null):
		UpdateAvailableMissiles()
	
func RegisterShip(Dr : Drone, _Target : MapShip):
	if (!Missiles.has(Dr)):
		var MissileAr : Array[MissileItem] = []
		Missiles[Dr] = MissileAr
		Dr.connect("OnShipDestroyed", OnShipDest)

func FindShip(C: Captain ) -> MapShip:
	for g in Missiles.keys():
		var ship = g as MapShip
		if (ship.Cpt == C):
			return ship
	return null

func UpdateAvailableMissiles() -> void:
	var sizeb = AvailableMissiles.size()
	var Misses : Array[MissileItem] = []
	Misses.append_array(Missiles[ConnectedShip])
	for g in ConnectedShip.GetDroneDock().DockedDrones:
		Misses.append_array(Missiles[g])
	AvailableMissiles =  Misses
	var sizea = AvailableMissiles.size()
	if (sizeb != sizea):
		UpdateMissileSelect()

func MissileAdded(MIs : MissileItem, Target : Captain) -> void:
	var Ship = FindShip(Target)
	if (MIs.Type == 1):
		return
	if (Ship == null):
		call_deferred("MissileAdded",MIs, Target)
		return
	Missiles[Ship].append(MIs)
	if (CurrentlySelectedMissile == null):
		UpdateMissileSelect()

func MissileRemoved(MIs : MissileItem, Target : Captain) -> void:
	var Ship = FindShip(Target)
	if (MIs.Type == 1):
		return
	Missiles[Ship].erase(MIs)
	if (MIs == CurrentlySelectedMissile):
		CurrentlySelectedMissile = null
		UpdateMissileSelect()

func OnShipDest(Ship : MapShip) -> void:
	Missiles.erase(Ship)

func OnLaunchPressed() -> void:
	if (!Armed):
		PopUpManager.GetInstance().DoFadeNotif("No missile is Armed. Launch canceled.")
		return
	PopUpManager.GetInstance().DoFadeNotif("{0} Launched".format([CurrentlySelectedMissile.ItemName]))
	MissileDockEventH.OnMissileLaunched(CurrentlySelectedMissile, FindOwner(CurrentlySelectedMissile),ConnectedShip.Cpt)
	AchievementManager.GetInstance().UlockAchievement("MC_MISSILEFIRE")
	MissileLaunched.emit()
	DissarmMiss()
	
func OnArmPressed() -> void:
	if (AvailableMissiles.size() == 0):
		PopUpManager.GetInstance().DoFadeNotif("No missiles available")
		DissarmMiss()
		return
	if (Armed):
		PopUpManager.GetInstance().DoFadeNotif("A missile is already armed")
		return

	Armed = true
	MissileSelectLight.Toggle(false, false)
	AngleSelectLight.Toggle(true, true)
	PopUpManager.GetInstance().DoFadeNotif("{0} Armed".format([CurrentlySelectedMissile.ItemName]))

	MissileDockEventH.MissileArmed(CurrentlySelectedMissile, ConnectedShip.Cpt)


func OnDissarmPressed() -> void:
	PopUpManager.GetInstance().DoFadeNotif("{0} Dissarmed".format([CurrentlySelectedMissile.ItemName]))
	DissarmMiss()

func DissarmMiss() -> void:
	Armed = false
	MissileSelectLight.Toggle(true, true)
	AngleSelectLight.Toggle(false, false)
	MissileDockEventH.MissileDissarmed(ConnectedShip.Cpt)
	
func Toggle() -> void:
	if ($AnimationPlayer.is_playing()):
		await $AnimationPlayer.animation_finished
	if (!Showing):
		TouchStopper.mouse_filter = MOUSE_FILTER_IGNORE
		$AnimationPlayer.play("Show")
		UpdateMissileSelect()
		Showing = true
	else:
		TurnOffPressed()

var SteeringDir : float = 0.0

func UpdateSteer(RelativeRot : float):
	if (Armed):
		SteeringDir = RelativeRot
		MissileDockEventH.MissileDirectionChanged(SteeringDir / 50, ConnectedShip.Cpt)

func UpdateSelected(Dir : bool) -> void:
	if (!Armed):
		ProgressMissileSelect(Dir)

func UpdateMissileSelect(Select : int = 0):
	if (AvailableMissiles.size() > Select):
		SelectedIndex = Select
		CurrentlySelectedMissile = AvailableMissiles[Select]
		SelectedMissileText.text = CurrentlySelectedMissile.ItemName
		RangeText.text = "Range : " + var_to_str(CurrentlySelectedMissile.Distance) + "km"
	else:
		SelectedMissileText.text = "No Missiles"
		
func ProgressMissileSelect(Front : bool = true):
	if (AvailableMissiles.size() == 0):
		SelectedMissileText.text = "No Missiles"
		return
	if (CurrentlySelectedMissile == null):
		CurrentlySelectedMissile = AvailableMissiles[0]
	else:
		if (Front):
			SelectedIndex +=  1
		else :
			SelectedIndex -= 1
		if (SelectedIndex >= AvailableMissiles.size()):
			SelectedIndex = 0
		else : if (SelectedIndex < 0):
			SelectedIndex = AvailableMissiles.size() - 1
		CurrentlySelectedMissile = AvailableMissiles[SelectedIndex]
		
	SelectedMissileText.text = CurrentlySelectedMissile.ItemName
	RangeText.text = "Range : " + var_to_str(CurrentlySelectedMissile.Distance) + "km"
	
func TurnOffPressed() -> void:
	TouchStopper.mouse_filter = MOUSE_FILTER_STOP
	if (Armed):
		DissarmMiss()
	$AnimationPlayer.play("Hide")
	Showing = false

func TurnOff() -> void:
	if (!Showing):
		return
	TurnOffPressed()
