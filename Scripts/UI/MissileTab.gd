extends Control
class_name MissileTab

var Armed = false
@export var MissileDockEventH : MissileDockEventHandler
@export var ShipControllerEventH : ShipControllerEventHandler
@export var UIEventH : UIEventHandler

@export_group("Nodes")
@export var MissileSelectLight : Light
@export var AngleSelectLight : Light
@export var RangeText : Label
@export var SelectedMissileText : Label
@export var TurnOffButton : Button

signal MissileLaunched

var CurrentlySelectedMissile

var SelectedIndex : int

var ConnectedShip : PlayerDrivenShip

#var Missiles : Dictionary

var AvailableMissiles : Array[MissileItem]

var Showing = false

func _ready() -> void:
	Initialise()
	MissileLaunched.connect(UIEventH.OnMissilgeLaunched)
	#visible = false
	
func UpdateConnectedShip(Ship : PlayerDrivenShip) -> void:
	if (Ship == ConnectedShip):
		return
	if (ConnectedShip != null):
		Ship.disconnect("OnShipDestroyed", OnShipDest)
	#if (!Missiles.has(Ship)):
		#var MissileAr : Array[MissileItem] = []
		#Missiles[Ship] = MissileAr
	Ship.connect("OnShipDestroyed", OnShipDest)
	if (Armed):
		DissarmMiss()
	ConnectedShip = Ship
	UpdateAvailableMissiles()
	call_deferred("UpdateMissileSelect")

#HACK TO MAKE SURE UI IS INITIALISED IN TIME.
func Initialise() -> void:
	#for g : PlayerDrivenShip in get_tree().get_nodes_in_group("PlayerShips"):
		#RegisterShip(g)
	#DroneDockEventH.connect("DroneAdded", RegisterShip)
	UpdateConnectedShip(ShipControllerEventH.CurrentControlled)
	ShipControllerEventH.OnControlledShipChanged.connect(UpdateConnectedShip)
	#MissileUI.UpdateConnectedShip(NewShip)
	MissileDockEventH.connect("MissileAdded", MissileAdded)
	MissileDockEventH.connect("MissileRemoved", MissileRemoved)

#func FindOwner(Mis : MissileItem) -> Captain:
	#for g in Missiles.keys():
		#if (Missiles[g].has(Mis)):
			#return g.Cpt
	#return null

#var d = 0.3
#
#func _physics_process(delta: float) -> void:
	#d -= delta
	#if (d > 0):
		#return
	#d = 0.3
	##if (ConnectedShip != null):
		##UpdateAvailableMissiles()
	
#func RegisterShip(Dr : Drone, _Target : MapShip):
	#if (!Missiles.has(Dr)):
		#var MissileAr : Array[MissileItem] = []
		#Missiles[Dr] = MissileAr
		#Dr.connect("OnShipDestroyed", OnShipDest)
#
#func FindShip(C: Captain ) -> MapShip:
	#for g in Missiles.keys():
		#var ship = g as MapShip
		#if (ship.Cpt == C):
			#return ship
	#return null

func UpdateAvailableMissiles() -> void:
	var sizeb = AvailableMissiles.size()
	var Misses : Array[MissileItem] = []
	Misses.append_array(ConnectedShip.Cpt.GetCharacterInventory().GetMissile())
	#for g in ConnectedShip.GetDroneDock().DockedDrones:
		#Misses.append_array(Missiles[g])
	AvailableMissiles =  Misses
	var sizea = AvailableMissiles.size()
	if (sizeb != sizea):
		UpdateMissileSelect()

func MissileAdded(_MIs : MissileItem, Target : Captain) -> void:
	if (Target == ConnectedShip.Cpt):
		UpdateAvailableMissiles()
	#var Ship = FindShip(Target)
	#if (MIs.Type == 1):
		#return
	#if (Ship == null):
		#call_deferred("MissileAdded",MIs, Target)
		#return
	##Missiles[Ship].append(MIs)
	#if (CurrentlySelectedMissile == null):
		#UpdateMissileSelect()

func MissileRemoved(_MIs : MissileItem, Target : Captain) -> void:
	if (Target == ConnectedShip.Cpt):
		UpdateAvailableMissiles()
	#var Ship = FindShip(Target)
	#if (MIs.Type == 1):
		#return
	##Missiles[Ship].erase(MIs)
	#if (MIs == CurrentlySelectedMissile):
		#CurrentlySelectedMissile = null
		#UpdateMissileSelect()

func OnShipDest(_Ship : MapShip) -> void:
	TurnOff()
	#Missiles.erase(Ship)

func OnLaunchPressed() -> void:
	if (!Showing):
		return
	if (!Armed):
		PopUpManager.GetInstance().DoFadeNotif("No missile is Armed. Launch canceled.")
		return
	PopUpManager.GetInstance().DoFadeNotif("{0} Launched".format([CurrentlySelectedMissile.ItemName]))
	MissileDockEventH.OnMissileLaunched(CurrentlySelectedMissile, ConnectedShip.Cpt,ConnectedShip.Cpt)
	AchievementManager.GetInstance().UlockAchievement("MC_MISSILEFIRE")
	MissileLaunched.emit()
	DissarmMiss()
	
func OnArmPressed() -> void:
	if (!Showing):
		return
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
	if (!Showing):
		return
	
	PopUpManager.GetInstance().DoFadeNotif("{0} Dissarmed".format([CurrentlySelectedMissile.ItemName]))
	DissarmMiss()

func DissarmMiss() -> void:
	Armed = false
	MissileSelectLight.Toggle(true, true)
	AngleSelectLight.Toggle(false, false)
	MissileDockEventH.MissileDissarmed(ConnectedShip.Cpt)

var SteeringDir : float = 0.0

func UpdateSteer(RelativeRot : float):
	if (!Showing):
		return
	if (Armed):
		SteeringDir = RelativeRot
		MissileDockEventH.MissileDirectionChanged(SteeringDir / 50, ConnectedShip.Cpt)

func UpdateSelected(Dir : bool) -> void:
	if (!Showing):
		return
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
	

	

func TurnOff() -> void:
	if (!Showing):
		return
	TurnOffButton.set_pressed_no_signal(false)
	_on_turn_off_toggled(false)


func _on_turn_off_toggled(toggled_on: bool) -> void:
	if (!toggled_on):
		if (Armed):
			DissarmMiss()
		Showing = false
		RangeText.visible = false
		SelectedMissileText.visible = false
		MissileSelectLight.Toggle(false, false)
	else:
		Showing = true
		UpdateMissileSelect()
		RangeText.visible = true
		SelectedMissileText.visible = true
		MissileSelectLight.Toggle(true, true)
