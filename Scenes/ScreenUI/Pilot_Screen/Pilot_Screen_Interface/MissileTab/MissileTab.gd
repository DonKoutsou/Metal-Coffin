extends BasePilotScreenInterface
class_name MissileTab

# --- EXPORTED MEMBER VARIABLES ---

@export var missileDockEventH: MissileDockEventHandler
@export var uiEventH: UIEventHandler

@export_group("Nodes")
@export var missileSelectLight: Light
@export var angleSelectLight: Light
@export var rangeText: Label
@export var selectedMissileText: Label
@export var turnOffButton: Button
@export var armButton: Button
@export var dissarmButton: Button
@export var launchButton: Button
@export var cap: Panel
@export var missileDial: Dial

# --- SIGNALS ---

signal MissileLaunched

# --- INTERNAL STATE ---

var currentlySelectedMissile: MissileItem = null
var selectedIndex: int = 0
var availableMissiles: Array[MissileItem] = []
var showing: bool = false
var armed: bool = false
var amountArmed: bool = false
var amount: int = 0
var steeringDir: float = 0.0

# --- TUTORIALS ---

func doIntroductionTutorial() -> void:
	ActionTracker.GetInstance().QueueTutorial("Missile Launcher", 
		"To turn on the missile launcher use this knob", [Map.UI_ELEMENT.MISSILE_TOGGLE])

func doMissileArmTutorial() -> void:
	ActionTracker.GetInstance().QueueTutorial("Missile Arming", 
		"Turn the dial to select missile types in the current fleet, then arm to start launching.", 
		[Map.UI_ELEMENT.MISSILE_ARM, Map.UI_ELEMENT.MISSILE_DIAL])
	
func doMissileAmountTutorial() -> void:
	ActionTracker.GetInstance().QueueTutorial("Missile Amount",
		"Turn the dial to pick the amount of missiles you want to shoot and press the arm button again to pick a direction",
		[Map.UI_ELEMENT.MISSILE_ARM, Map.UI_ELEMENT.MISSILE_DIAL])

func doMissileLaunchTutorial() -> void:
	ActionTracker.GetInstance().QueueTutorial("Missile Launch",
		"Finally turn the dial to aim, then press Launch to send it away.",
		[Map.UI_ELEMENT.MISSILE_LAUNCH, Map.UI_ELEMENT.MISSILE_DIAL])

# --- MISSILE/FLEET LOGIC ---

func fleetHasMissileLauncher() -> bool:
	if controller.Cpt.GetCharacterInventory().HasWeapon(CardStats.WeaponType.ML):
		return true
	for cap: Captain in controller.GetDroneDock().GetCaptains():
		if cap.GetCharacterInventory().HasWeapon(CardStats.WeaponType.ML):
			return true
	return false

# --- INITIALIZATION & CONNECTION ---

func _ready() -> void:
	super()
	MissileLaunched.connect(uiEventH.OnMissilgeLaunched)
	missileDockEventH.connect("MissileAdded", missileAdded)
	missileDockEventH.connect("MissileRemoved", missileRemoved)

# --- SHIP/EVENT MANAGEMENT ---

func _onControlledShipUpdated(ship: PlayerDrivenShip) -> void:
	if ship == controller:
		return
	if controller != null:
		controller.disconnect("OnShipDestroyed", onShipDest)
	ship.connect("OnShipDestroyed", onShipDest)
	if armed:
		dissarmMiss()
	controller = ship
	updateAvailableMissiles()
	call_deferred("updateMissileSelect")
	var hasLauncher = fleetHasMissileLauncher()
	cap.visible = not hasLauncher
	if not hasLauncher:
		_on_turn_off_toggled(false)
	else:
		if not ActionTracker.IsActionCompleted(ActionTracker.Action.MISSILE_TOGGLE):
			ActionTracker.OnActionCompleted(ActionTracker.Action.MISSILE_TOGGLE)
			doIntroductionTutorial()

func _onDroneAdded(drone: Drone, target: MapShip) -> void:
	if target == controller:
		if armed:
			dissarmMiss()
		updateAvailableMissiles()
		var hasLauncher = fleetHasMissileLauncher()
		cap.visible = not hasLauncher
		if not hasLauncher:
			_on_turn_off_toggled(false)

func _onDroneRemoved(drone: Drone, target: MapShip) -> void:
	if target == controller:
		if armed:
			dissarmMiss()
		updateAvailableMissiles()
		var hasLauncher = fleetHasMissileLauncher()
		cap.visible = not hasLauncher
		if not hasLauncher:
			_on_turn_off_toggled(false)

# --- MISSILE LIST MANAGEMENT ---

func updateAvailableMissiles() -> void:
	var sizeBefore = availableMissiles.size()
	var missiles: Array[MissileItem] = []
	missiles.append_array(controller.Cpt.GetCharacterInventory().GetMissile())
	for ship: PlayerDrivenShip in controller.GetDroneDock().GetDockedShips():
		missiles.append_array(ship.Cpt.GetCharacterInventory().GetMissile())
	availableMissiles = missiles
	if sizeBefore != availableMissiles.size():
		updateMissileSelect()

func missileAdded(_missile: MissileItem, target: Captain) -> void:
	if target == controller.Cpt:
		updateAvailableMissiles()

func missileRemoved(_missile: MissileItem, _target: Captain) -> void:
	updateAvailableMissiles()

func onShipDest(_ship: MapShip) -> void:
	turnOff()

# --- MISSILE STATE MANAGEMENT & UI ACTIONS ---

func onLaunchPressed() -> void:
	if not showing:
		return
	if not armed:
		PopUpManager.GetInstance().DoFadeNotif("No missile is Armed. Launch canceled.")
		return
	if not amountArmed:
		PopUpManager.GetInstance().DoFadeNotif("Missile amount hasn't been chosen.")
		return
	PopUpManager.GetInstance().DoFadeNotif("{0} Launched".format([currentlySelectedMissile.ItemName]))
	
	var missilesToLaunch: Array[MissileItem]
	for _i in amount:
		missilesToLaunch.append(currentlySelectedMissile)
	missileDockEventH.OnMissileLaunched(missilesToLaunch, controller.Cpt, controller.Cpt)
	AchievementManager.GetInstance().UlockAchievement("MC_MISSILEFIRE")
	MissileLaunched.emit()
	dissarmMiss()

func onArmPressed() -> void:
	if not showing:
		return
	if availableMissiles.size() == 0:
		PopUpManager.GetInstance().DoFadeNotif("No missiles available")
		dissarmMiss()
		return
	if armed:
		amountArmed = true
		PopUpManager.GetInstance().DoFadeNotif("Amount Picked")
		missileSelectLight.Toggle(false, false)
		angleSelectLight.Toggle(true, true)
		missileDockEventH.MissileArmed(currentlySelectedMissile, controller.Cpt)
		if not ActionTracker.IsActionCompleted(ActionTracker.Action.MISSILE_LAUNCH):
			ActionTracker.OnActionCompleted(ActionTracker.Action.MISSILE_LAUNCH)
			doMissileLaunchTutorial()
		return
	if amountArmed:
		PopUpManager.GetInstance().DoFadeNotif("A missile is already armed")
		return 
	if not ActionTracker.IsActionCompleted(ActionTracker.Action.MISSILE_SELECT_NUM):
		ActionTracker.OnActionCompleted(ActionTracker.Action.MISSILE_SELECT_NUM)
		doMissileAmountTutorial()
	armed = true
	amount = 1
	rangeText.text = "Amount : %s" % var_to_str(amount)
	PopUpManager.GetInstance().DoFadeNotif("{0} Armed".format([currentlySelectedMissile.ItemName]))

func onDissarmPressed() -> void:
	if not showing:
		return
	PopUpManager.GetInstance().DoFadeNotif("{0} Dissarmed".format([currentlySelectedMissile.ItemName]))
	dissarmMiss()

func dissarmMiss() -> void:
	armed = false
	amountArmed = false
	missileSelectLight.Toggle(true, true)
	angleSelectLight.Toggle(false, false)
	missileDockEventH.MissileDissarmed(controller.Cpt)

func updateSteer(relativeRot: float) -> void:
	if not showing or not armed or not amountArmed:
		return
	steeringDir = relativeRot
	missileDockEventH.MissileDirectionChanged(steeringDir / 50, controller.Cpt)

func updateSelected(dir: bool) -> void:
	if not showing:
		return
	if not armed:
		progressMissileSelect(dir)
	elif not amountArmed:
		if not dir:
			amount = min(amount + 1, availableMissiles.count(currentlySelectedMissile))
		else:
			amount = max(amount - 1, 1)
		rangeText.text = "Amount : %s" % var_to_str(amount)

func updateMissileSelect(select: int = 0) -> void:
	if availableMissiles.size() > select:
		selectedIndex = select
		currentlySelectedMissile = availableMissiles[select]
		selectedMissileText.text = currentlySelectedMissile.ItemName
		rangeText.text = "Range : %s km" % var_to_str(currentlySelectedMissile.Distance)
	else:
		selectedMissileText.text = "No Missiles"
		rangeText.text = ""

func progressMissileSelect(front: bool = true) -> void:
	if availableMissiles.is_empty():
		selectedMissileText.text = "No Missiles"
		rangeText.text = ""
		return
	if currentlySelectedMissile == null:
		currentlySelectedMissile = availableMissiles[0]
		selectedIndex = 0
	else:
		if front:
			selectedIndex += 1
		else:
			selectedIndex -= 1
		if selectedIndex >= availableMissiles.size():
			selectedIndex = 0
		elif selectedIndex < 0:
			selectedIndex = availableMissiles.size() - 1
		currentlySelectedMissile = availableMissiles[selectedIndex]
	
	selectedMissileText.text = currentlySelectedMissile.ItemName
	rangeText.text = "Range : %s km" % var_to_str(currentlySelectedMissile.Distance)

func turnOff() -> void:
	if not showing:
		return
	turnOffButton.set_pressed_no_signal(false)
	_on_turn_off_toggled(false)

func _on_turn_off_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		if armed:
			dissarmMiss()
		showing = false
		rangeText.visible = false
		selectedMissileText.visible = false
		missileSelectLight.Toggle(false, false)
		turnOffButton.set_pressed_no_signal(false)
	else:
		if not ActionTracker.IsActionCompleted(ActionTracker.Action.MISSILE_ARM):
			ActionTracker.OnActionCompleted(ActionTracker.Action.MISSILE_ARM)
			doMissileArmTutorial()
		showing = true
		updateMissileSelect()
		rangeText.visible = true
		selectedMissileText.visible = true
		missileSelectLight.Toggle(true, true)
		turnOffButton.set_pressed_no_signal(true)

func _getInterfaceName() -> String:
	return "Missile Tab"
