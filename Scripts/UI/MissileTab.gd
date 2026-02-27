extends Control
class_name MissileTab


@export var MissileDockEventH : MissileDockEventHandler
@export var ShipControllerEventH : ShipControllerEventHandler
@export var DockEventH : DroneDockEventHandler
@export var UIEventH : UIEventHandler

@export_group("Nodes")
@export var MissileSelectLight : Light
@export var AngleSelectLight : Light
@export var RangeText : Label
@export var SelectedMissileText : Label
@export var TurnOffButton : Button
@export var ArmButton : Button
@export var DissarmButton : Button
@export var LaunchButton : Button
@export var Cap : Panel
@export var missile_dial : Dial

signal MissileLaunched

var CurrentlySelectedMissile

var SelectedIndex : int

var ConnectedShip : PlayerDrivenShip

#var Missiles : Dictionary

var AvailableMissiles : Array[MissileItem]

var Showing = false
var Armed = false
var AmmountArmed = false
var Ammount : int = 0

func DoIntroductionTutorial() -> void:
	ActionTracker.GetInstance().QueueTutorial("Missile Launcher", "To turn on the missile launcher use this nob", [Map.UI_ELEMENT.MISSILE_TOGGLE])

func DoMissileArmTutorial() -> void:
	ActionTracker.GetInstance().QueueTutorial("Missile Arming", "Turn the dial to pass over the missiles the current fleet has on them, after selecting the type of the missile press the arm button to start the launching sequence", [Map.UI_ELEMENT.MISSILE_ARM, Map.UI_ELEMENT.MISSILE_DIAL])
	
func DoMissileAmmountTutorial() -> void:
	ActionTracker.GetInstance().QueueTutorial("Missile Ammout","Turn the dial to pick the ammount of missiles you want to shoot and press the arm button again to be prompted to pick a direction", [Map.UI_ELEMENT.MISSILE_ARM, Map.UI_ELEMENT.MISSILE_DIAL])

func DoMissileLaucnhTutorial() -> void:
	ActionTracker.GetInstance().QueueTutorial("Missile Launch","Finally turn the dial to aim the missile, when ready press the Launch button to send it away.", [Map.UI_ELEMENT.MISSILE_LAUNCH, Map.UI_ELEMENT.MISSILE_DIAL])

func FleetHasMissileLauncher() -> bool:
	if (ConnectedShip.Cpt.GetCharacterInventory().HasWeapon(CardStats.WeaponType.ML)):
		return true
	for g : Captain in ConnectedShip.GetDroneDock().GetCaptains():
		if (g.GetCharacterInventory().HasWeapon(CardStats.WeaponType.ML)):
			return true
	return false

func _ready() -> void:
	Initialise()
	MissileLaunched.connect(UIEventH.OnMissilgeLaunched)
	DockEventH.DroneDocked.connect(DroneAdded)
	DockEventH.DroneUndocked.connect(DroneRemoved)
	#visible = false

func DroneRemoved(Dr : Drone, Target : MapShip) -> void:
	if (Target == ConnectedShip):
		if (Armed):
			DissarmMiss()
		UpdateAvailableMissiles()
		var FleetHasLauncher : bool = FleetHasMissileLauncher()
		Cap.visible = !FleetHasLauncher
		if (!FleetHasLauncher):
			_on_turn_off_toggled(false)

func DroneAdded(Dr : Drone, Target : MapShip) -> void:
	if (Target == ConnectedShip):
		if (Armed):
			DissarmMiss()
		UpdateAvailableMissiles()
		var FleetHasLauncher : bool = FleetHasMissileLauncher()
		Cap.visible = !FleetHasLauncher
		if (!FleetHasLauncher):
			_on_turn_off_toggled(false)

func UpdateConnectedShip(Ship : PlayerDrivenShip) -> void:
	if (Ship == ConnectedShip):
		return
	if (ConnectedShip != null):
		ConnectedShip.disconnect("OnShipDestroyed", OnShipDest)
	#if (!Missiles.has(Ship)):
		#var MissileAr : Array[MissileItem] = []
		#Missiles[Ship] = MissileAr
	Ship.connect("OnShipDestroyed", OnShipDest)
	if (Armed):
		DissarmMiss()
	ConnectedShip = Ship
	UpdateAvailableMissiles()
	call_deferred("UpdateMissileSelect")
	var FleetHasLauncher : bool = FleetHasMissileLauncher()
	Cap.visible = !FleetHasLauncher
	if (!FleetHasLauncher):
		_on_turn_off_toggled(false)
	else:
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.MISSILE_TOGGLE)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.MISSILE_TOGGLE)
			DoIntroductionTutorial()

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
	for g :PlayerDrivenShip in ConnectedShip.GetDroneDock().GetDockedShips():
		Misses.append_array(g.Cpt.GetCharacterInventory().GetMissile())
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
	#if (Target == ConnectedShip.Cpt):
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
	if (!AmmountArmed):
		PopUpManager.GetInstance().DoFadeNotif("Missile Ammount hasn't been chosen.")
		return
	PopUpManager.GetInstance().DoFadeNotif("{0} Launched".format([CurrentlySelectedMissile.ItemName]))
	
	var MissilesToLaunch : Array[MissileItem]
	for g in Ammount:
		MissilesToLaunch.append(CurrentlySelectedMissile)
		
	MissileDockEventH.OnMissileLaunched(MissilesToLaunch, ConnectedShip.Cpt,ConnectedShip.Cpt)
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
		AmmountArmed = true
		PopUpManager.GetInstance().DoFadeNotif("Ammount Picked")
		MissileSelectLight.Toggle(false, false)
		AngleSelectLight.Toggle(true, true)
		MissileDockEventH.MissileArmed(CurrentlySelectedMissile, ConnectedShip.Cpt)
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.MISSILE_LAUNCH)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.MISSILE_LAUNCH)
			DoMissileLaucnhTutorial()
		return
	if (AmmountArmed):
		PopUpManager.GetInstance().DoFadeNotif("A missile is already armed")
		return 
	
	if (!ActionTracker.IsActionCompleted(ActionTracker.Action.MISSILE_SELECT_NUM)):
		ActionTracker.OnActionCompleted(ActionTracker.Action.MISSILE_SELECT_NUM)
		DoMissileAmmountTutorial()
	Armed = true
	Ammount = 1
	RangeText.text = "Ammount : " + var_to_str(Ammount)
	
	PopUpManager.GetInstance().DoFadeNotif("{0} Armed".format([CurrentlySelectedMissile.ItemName]))

	


func OnDissarmPressed() -> void:
	if (!Showing):
		return
	
	PopUpManager.GetInstance().DoFadeNotif("{0} Dissarmed".format([CurrentlySelectedMissile.ItemName]))
	DissarmMiss()

func DissarmMiss() -> void:
	Armed = false
	AmmountArmed = false
	MissileSelectLight.Toggle(true, true)
	AngleSelectLight.Toggle(false, false)
	MissileDockEventH.MissileDissarmed(ConnectedShip.Cpt)

var SteeringDir : float = 0.0

func UpdateSteer(RelativeRot : float):
	if (!Showing):
		return
	
	if (Armed and AmmountArmed):
		SteeringDir = RelativeRot
		MissileDockEventH.MissileDirectionChanged(SteeringDir / 50, ConnectedShip.Cpt)

func UpdateSelected(Dir : bool) -> void:
	if (!Showing):
		return
	if (!Armed):
		ProgressMissileSelect(Dir)
	else: if (!AmmountArmed):
		if (!Dir):
			Ammount = min(Ammount + 1, AvailableMissiles.count(CurrentlySelectedMissile))
		else:
			Ammount = max(Ammount - 1, 1)
		RangeText.text = "Ammount : " + var_to_str(Ammount)

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
		TurnOffButton.set_pressed_no_signal(false)
	else:
		if (!ActionTracker.IsActionCompleted(ActionTracker.Action.MISSILE_ARM)):
			ActionTracker.OnActionCompleted(ActionTracker.Action.MISSILE_ARM)
			DoMissileArmTutorial()
		Showing = true
		UpdateMissileSelect()
		RangeText.visible = true
		SelectedMissileText.visible = true
		MissileSelectLight.Toggle(true, true)
		TurnOffButton.set_pressed_no_signal(true)
